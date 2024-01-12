//
//  FirestoreNetworking.swift
//  Shots
//
//  Created by Brett Rosen on 1/11/24.
//

import IdentifiedCollections
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseFirestoreCombineSwift
import Foundation
import OSLog

struct Success: Equatable { }

func retrying<T>(
    attempts: Int = 3,
    delay: TimeInterval = 1,
    closure: @escaping () async throws -> T
) async rethrows -> T {
    for _ in 0 ..< attempts - 1 {
        do {
            return try await closure()
        } catch {
            let delay = UInt64(delay * TimeInterval(1_000_000_000))
            try await Task.sleep(nanoseconds: delay)
        }
    }
    return try await closure()
}

final class Networking {

    // MARK: Success & Error
    struct Error: Swift.Error, Equatable {
        var description: String = ""
    }

    // MARK: Collection types
    enum FirestoreCollection: String {
        case users
    }

    // MARK: Document state
    enum DocState<D: Decodable> {
        case exists(D)
        case doesntExist
    }

    internal static let KEYCHAIN_SHARING_ID = "Z2HT5GMEGY.com.brettrosen.Scattered"

    // MARK: Firestore reference
    internal static let db = Firestore.firestore()

    /// Handles authentication state
    internal static var authStateHandler: AuthStateDidChangeListenerHandle?

    internal static var storeTransactionListenerTask: Task<(), Never>? = nil

    internal static let logger = Logger()

    private static var listeners: [UUID: ListenerRegistration] = [:]

    static func streamDocuments<D: Decodable>(
        query: Query,
        includeCachedData: Bool = true
    ) -> AsyncThrowingStream<[D], Swift.Error> {
        let id = UUID()
        return AsyncThrowingStream { continuation in
            Self.listeners[id] = query.addSnapshotListener(includeMetadataChanges: true) { querySnapshot, error in
                if let error = error {
                    continuation.finish(throwing: error)
                }

                guard let snapshot = querySnapshot else {
                    continuation.finish()
                    return
                }

                do {
                    let data = try snapshot.documents.compactMap { queryDocumentSnapshot -> D? in
                        try queryDocumentSnapshot.data(as: D.self)
                    }
                    continuation.yield(data)
                } catch {
                    print("Error streaming documents: \(error)")
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                Self.listeners[id]?.remove()
                Self.listeners[id] = nil
            }
        }
    }

    static func getDocumentsOnce<D: Decodable>(
        query: Query
    ) async throws -> [D] {
        do {
            let snapshot = try await query.getDocuments()
            let data = try snapshot.documents.compactMap { queryDocumentSnapshot -> D? in
                try queryDocumentSnapshot.data(as: D.self)
            }
            return data
        } catch {
            print("getDocumentsOnce failed: \(error)")
            throw error
        }
    }

    static func getDocumentOnce<D: Decodable>(
        collection: FirestoreCollection,
        documentId: String
    ) async throws -> D {
        do {
            let snapshot = try await db.collection(collection.rawValue).document(documentId).getDocument()
            let data = try snapshot.data(as: D.self)
            return data
        } catch {
            print("getDocumentOnce error: \(error)")
            throw error
        }
    }

    static func addOrUpdateMany<E: Encodable> (
        collection: FirestoreCollection,
        dataPairs: [(encodable: E, id: String)]
    ) async throws -> Success {
        let batch = db.batch()
        for dataPair in dataPairs {
            guard let data = dataPair.encodable.dictionary else {
                throw Networking.Error(description: "Cannot convert model to data")
            }
            let ref = db.collection(collection.rawValue).document(dataPair.id)
            batch.setData(data, forDocument: ref)
        }
        do {
            let _ = try await batch.commit()
            return Success()
        } catch {
            throw error
        }
    }

    static func addOrUpdateDocument<E: Encodable>(
        collection: FirestoreCollection,
        documentId: String?,
        encodable: E
    ) async throws -> Success {
        guard let data = encodable.dictionary else {
            throw Networking.Error(description: "Cannot convert model to data")
        }
        do {
            if let id = documentId {
                let _ = try await db.collection(collection.rawValue).document(id).setData(data)
                return Success()
            } else {
                let _ = try await db.collection(collection.rawValue).addDocument(data: data)
                return Success()
            }
        }
        catch {
            throw error
        }
    }

    static func checkDocExists<D: Decodable>(
        query: Query
    ) async throws -> DocState<D> {
        do {
            let snapshot = try await query.getDocuments()
            if snapshot.count == 0 {
                return .doesntExist
            } else {
                guard let data = try snapshot.documents.first?.data(as: D.self) else {
                    throw Networking.Error(description: "Can't parse data")
                }
                return .exists(data)
            }
        } catch {
            throw Networking.Error(description: error.localizedDescription)
        }
    }

    private static func formatUpdateDictionary<A: Encodable>(
        fieldName: String,
        value: A
    ) -> [String: Any] {
        var data: [String: Any]
        if let dictionary = value.dictionary {
            data = [fieldName: dictionary]
        } else {
            data = [fieldName: value]
        }
        return data
    }

    static func updateValueInDocument<A: Encodable>(
        collection: FirestoreCollection,
        documentId: String,
        fieldName: String,
        value: A
    ) async throws -> Success {
        do {
            let _ = try await db.collection(collection.rawValue).document(documentId).updateData(
                formatUpdateDictionary(fieldName: fieldName, value: value)
            )
            return Success()
        } catch {
            throw error
        }
    }

    static func removeValueFromDocument<A: Encodable>(
        collection: FirestoreCollection,
        documentId: String,
        fieldName: String,
        value: A
    ) async throws -> Success {
        do {
            let _ = try await db.collection(collection.rawValue).document(documentId).updateData([
                fieldName: FieldValue.arrayRemove([value.dictionary])
            ])
            return Success()
        } catch {
            throw error
        }
    }

    static func delete(
        collection: FirestoreCollection,
        documentId: String
    ) async throws -> Success {
        do {
            let _ = try await db.collection(collection.rawValue).document(documentId).delete()
            return Success()
        } catch {
            throw error
        }
    }

    static func deleteMany(
        collection: FirestoreCollection,
        documentIds: [String]
    ) async throws -> Success {
        let batch = db.batch()
        for id in documentIds {
            let ref = db.collection(collection.rawValue).document(id)
            batch.deleteDocument(ref)
        }
        do {
            let _ = try await batch.commit()
            return Success()
        } catch {
            throw error
        }
    }
}
