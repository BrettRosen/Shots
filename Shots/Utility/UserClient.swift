//
//  UserClient.swift
//  Shots
//
//  Created by Brett Rosen on 1/11/24.
//

import Combine
import ComposableArchitecture
import Firebase
import FirebaseAuth
import AuthenticationServices

struct UserClient {
    let user: () -> User?
    /// Updates the `User` in local state
    var setUser: (Shots.User?) async -> Void
    /// Updates the `User` in Firebase
    var updateUser: @Sendable (Shots.User) async throws -> Success
    var getUser: @Sendable (Firebase.User) async throws -> Shots.User?
    var registerAuthStateHandler: @Sendable () -> AsyncStream<Firebase.User?>
    var signInApple: @Sendable (ASAuthorization, String?) async throws -> User
    var linkAnonymousWithApple: @Sendable (ASAuthorization, String?, Firebase.User) async throws -> User
    var signInAnonymously: @Sendable () async throws -> Success
    var signOut: @Sendable () throws -> Void
    var deleteAccount: @Sendable () async throws -> Void
}

extension UserClient: DependencyKey {
    static var liveValue: Self {
        let userPublisher: CurrentValueSubject<User?, Never> = CurrentValueSubject(nil)

        return .init(
            user: { userPublisher.value },
            setUser: { user in
                userPublisher.send(user)
            },
            updateUser: { user in
                let success = try await Networking.updateUser(user)
                userPublisher.send(user)
                return success
            },
            getUser: { user in
                try await Networking.getUser(user)
            },
            registerAuthStateHandler: {
                Networking.registerAuthStateHandler()
            }, signInApple: { authorization, nonce in
                try await Networking.signInApple(authorization: authorization, currentNonce: nonce)
            }, linkAnonymousWithApple: { authorization, nonce, user in
                try await Networking.linkAnonymousWithApple(
                    authorization: authorization,
                    currentNonce: nonce,
                    anonymousUser: user
                )
            }, signInAnonymously: {
                try await Networking.signInAnonymously()
            }, signOut: {
                try Networking.signOut()
            }, deleteAccount: {
                try await Networking.deleteAccount()
            }
        )
    }
}

extension UserClient: TestDependencyKey {
    static let testValue = Self(
        user: unimplemented("\(Self.self).user"),
        setUser: unimplemented("\(Self.self).setUser"),
        updateUser: unimplemented("\(Self.self).updateUser"),
        getUser: unimplemented("\(Self.self).getUser"),
        registerAuthStateHandler: unimplemented("\(Self.self).registerAuthStateHandler"),
        signInApple: unimplemented("\(Self.self).signInApple"),
        linkAnonymousWithApple: unimplemented("\(Self.self).linkAnonymousWithApple"),
        signInAnonymously: unimplemented("\(Self.self).signInAnonymously"),
        signOut: unimplemented("\(Self.self).signOut"),
        deleteAccount: unimplemented("\(Self.self).deleteAccount")
    )
}

extension DependencyValues {
    var userClient: UserClient {
        get { self[UserClient.self] }
        set { self[UserClient.self] = newValue }
    }
}
