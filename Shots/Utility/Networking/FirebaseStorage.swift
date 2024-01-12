//
//  FirebaseStorage.swift
//  Shots
//
//  Created by Brett Rosen on 1/11/24.
//

import FirebaseStorage
import Foundation

final class AssetStorage {

    // MARK: Firestore reference
    internal static let storage = Storage.storage()
    internal static let storageRef = storage.reference()
    

    // MARK: Success & Error
    enum Error: Swift.Error, Equatable {
        case failedToUpload
    }

    static func upload(
        data: Data,
        path: String,
        metadata: [String: AnyHashable] = [:],
        onProgress: @escaping (Progress?) -> Void = { _ in }
    ) async throws -> Success {
        let ref = storageRef.child(path)
        do {
            let metadata = StorageMetadata(dictionary: metadata)
            let _ = try await ref.putDataAsync(data, metadata: metadata, onProgress: onProgress)
            return Success()
        } catch {
            print("Upload failed: \(error)")
            throw Error.failedToUpload
        }
    }
}
