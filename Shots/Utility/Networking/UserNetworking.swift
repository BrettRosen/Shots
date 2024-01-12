//
//  UserNetworking.swift
//  Shots
//
//  Created by Brett Rosen on 1/11/24.
//

import AuthenticationServices
import ComposableArchitecture
import CryptoKit
import Firebase
import FirebaseAuthCombineSwift
import Foundation
import OSLog

internal struct AppleSignInRequirements {
    let appleIDCredential: ASAuthorizationAppleIDCredential
    let nonce: String
    let appleIDToken: Data
    let idTokenString: String
}

extension Networking {

    static func getUser(
        _ user: Firebase.User
    ) async throws -> User? {
        try? await Networking.getDocumentOnce(collection: .users, documentId: user.uid)
    }

    static func updateUser(
        _ user: Shots.User
    ) async throws -> Success {
        try await Networking.addOrUpdateDocument(collection: .users, documentId: user.id, encodable: user)
    }

    static func registerAuthStateHandler() -> AsyncStream<Firebase.User?> {
        AsyncStream { continuation in
            guard authStateHandler == nil else {
                continuation.finish()
                return
            }

            authStateHandler = Auth.auth().addStateDidChangeListener { auth, user in
                continuation.yield(user)
            }

            continuation.onTermination = { _ in }
        }
    }

    static func signOut() throws {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Unable to sign out \(error)")
            throw error
        }
    }

    static func deleteAccount() async throws {
        do {
            try await Auth.auth().currentUser?.delete()
        } catch {
            print("Unable to delete account \(error)")
            throw error
        }
    }

    private static func appleCredentialChecks(
        authorization: ASAuthorization,
        currentNonce: String?
    ) throws -> AppleSignInRequirements {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw Error(description: "Authorization has no credentials.")
        }
        guard let nonce = currentNonce else {
            throw Error(description: "Invalid state: a login callback was recieved but no login request was sent.")
        }
        guard let appleIDToken = appleIDCredential.identityToken else {
            throw Error(description: "Unable to fetch identity token.")
        }
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw Error(description: "Unable to serialize token from data: \(appleIDToken.debugDescription)")
        }
        return AppleSignInRequirements(
            appleIDCredential: appleIDCredential,
            nonce: nonce,
            appleIDToken: appleIDToken,
            idTokenString: idTokenString
        )
    }

    static func linkAnonymousWithApple(
        authorization: ASAuthorization,
        currentNonce: String?,
        anonymousUser: Firebase.User
    ) async throws -> User {
        do {
            let requirements = try appleCredentialChecks(authorization: authorization, currentNonce: currentNonce)
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: requirements.idTokenString, rawNonce: requirements.nonce)
            let result = try await anonymousUser.link(with: credential)
            let user = try await updateDisplayName(for: result.user, with: requirements.appleIDCredential)

            return user
        } catch {
            throw error
        }
    }

    static func signInApple(
        authorization: ASAuthorization,
        currentNonce: String?
    ) async throws -> User {
        do {
            let _ = try Auth.auth().useUserAccessGroup(Networking.KEYCHAIN_SHARING_ID)
            let requirements = try appleCredentialChecks(authorization: authorization, currentNonce: currentNonce)
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: requirements.idTokenString, rawNonce: requirements.nonce)
            let result = try await Auth.auth().signIn(with: credential)
            //let user = try await updateDisplayName(for: result.user, with: requirements.appleIDCredential)
            let user = User(id: result.user.uid, createdAt: .now, email: requirements.appleIDCredential.email)
            let _ = try await Networking.addUser(user)
            logger.info("User signed in with Apple")
            return user
        } catch {
            logger.error("Error signing in with Apple: \(error.localizedDescription)")
            throw error
        }
    }

    /// Attempts to anonymously sign in the user, retrying infinitely.
    /// Since anonymous users are not added to Firestore, we can just return a Success here
    /// instead of a User.
    static func signInAnonymously() async throws -> Success {
        do {
            let _ = try await retrying(
                attempts: 999_999
            ) {
                try await Auth.auth().signInAnonymously()
            }
            logger.info("User signed in anonymously")
            return Success()
        }
        catch {
            logger.error("User failed to sign in anonymously")
            throw Networking.Error(description: error.localizedDescription)
        }
    }

    /// Updates a User's displayName based off Apple Signin Credentials
    private static func updateDisplayName(
        for user: Firebase.User,
        with appleIDCredential: ASAuthorizationAppleIDCredential,
        force: Bool = false
    ) async throws -> User {
        if let currentDisplayName = Auth.auth().currentUser?.displayName, !currentDisplayName.isEmpty {
            // current user display-name is not empty, don't overwrite it
            // TODO: Update createdAt
            return User(id: user.uid, createdAt: .now)
        } else {
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = appleIDCredential.fullName?.givenName

            do {
                try await changeRequest.commitChanges()
                // TODO: Update createdAt
                return User(id: user.uid, createdAt: .now, name: Auth.auth().currentUser?.displayName)
            } catch {
                print(error)
                throw error
            }
        }
    }

    /// Checks if the User exists in Firebase by checking against their **ID only**
    private static func userExists(_ user: Shots.User) async throws -> DocState<User> {
        let query = db.collection(FirestoreCollection.users.rawValue).whereField("id", isEqualTo: user.id)
        return try await Networking.checkDocExists(query: query)
    }

    /// Updates the user's createdAt if the document does not exist yet, then adds to Firebase.
    private static func addUser(
        _ user: User
    ) async throws -> Success {
        let docState = try await Networking.userExists(user)
        if case .doesntExist = docState {
            let user = User(id: user.id, createdAt: .now)
            return try await Networking.addOrUpdateDocument(collection: .users, documentId: user.id, encodable: user)
        } else {
            return Success()
        }
    }
}

// MARK: Authentication Helpers

func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
        String(format: "%02x", $0)
    }.joined()

    return hashString
}

func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: [Character] =
    Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length

    while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                fatalError(
                    "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
                )
            }
            return random
        }

        randoms.forEach { random in
            if remainingLength == 0 {
                return
            }

            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }

    return result
}
