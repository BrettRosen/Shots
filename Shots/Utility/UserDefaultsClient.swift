//
//  UserDefaultsClient.swift
//  Shots
//
//  Created by Brett Rosen on 1/11/24.
//

import Dependencies
import Foundation

// MARK: Live
extension UserDefaultsClient: DependencyKey {
    public static let liveValue: Self = {
        let defaults = { UserDefaults(suiteName: "group.shots")! }
        return Self(
            valueForKey: { defaults().value(forKey: $0) },
            boolForKey: { defaults().bool(forKey: $0) },
            dataForKey: { defaults().data(forKey: $0) },
            doubleForKey: { defaults().double(forKey: $0) },
            integerForKey: { defaults().integer(forKey: $0) },
            stringForKey: { defaults().string(forKey: $0) },
            remove: { defaults().removeObject(forKey: $0) },
            setValue: { defaults().set($0, forKey: $1) },
            setBool: { defaults().set($0, forKey: $1) },
            setData: { defaults().set($0, forKey: $1) },
            setDouble: { defaults().set($0, forKey: $1) },
            setInteger: { defaults().set($0, forKey: $1) },
            setString: { defaults().set($0, forKey: $1) }
        )
    }()
}

public struct UserDefaultsClient {
    public var valueForKey: @Sendable (String) -> Any?
    public var boolForKey: @Sendable (String) -> Bool
    public var dataForKey: @Sendable (String) -> Data?
    public var doubleForKey: @Sendable (String) -> Double
    public var integerForKey: @Sendable (String) -> Int
    public var stringForKey: @Sendable (String) -> String?
    public var remove: @Sendable (String) async -> Void
    public var setValue: @Sendable (Any?, String) async -> Void
    public var setBool: @Sendable (Bool, String) async -> Void
    public var setData: @Sendable (Data?, String) async -> Void
    public var setDouble: @Sendable (Double, String) async -> Void
    public var setInteger: @Sendable (Int, String) async -> Void
    public var setString: @Sendable(String, String) async -> Void

    var hasCompletedOnboarding: Bool {
        self.boolForKey(UserDefaultsKey.hasCompletedOnboarding.rawValue)
    }

    func setHasCompletedOnboarding(_ bool: Bool) async {
        await self.setBool(bool, UserDefaultsKey.hasCompletedOnboarding.rawValue)
    }
}

enum UserDefaultsKey: String {
    // Marked as complete once a user has gone through all onboarding steps at least once.
    case hasCompletedOnboarding
}

extension DependencyValues {
    var userDefaults: UserDefaultsClient {
        get { self[UserDefaultsClient.self] }
        set { self[UserDefaultsClient.self] = newValue }
    }
}
