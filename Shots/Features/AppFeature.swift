//
//  AppFeature.swift
//  Shots
//
//  Created by Brett Rosen on 1/10/24.
//

import ComposableArchitecture
import Firebase
import FirebaseAppCheck
import FirebaseCore
import FirebaseAuth
import Foundation

@Reducer
struct AppFeature {
    @Dependency(\.userClient) var userClient

    enum Tab: String, Equatable, CaseIterable, Identifiable {
        case home
        case explore
        case profile
        case settings

        var id: Self { self }
    }

    struct State: Equatable {
        var user: User?
        var tab: Tab = .home

        var onboarding: OnboardingLoginFeature.State?
        var home: HomeFeature.State = .init()
    }

    enum Action: Equatable, FeatureAction {
        enum ViewAction: Equatable {
            case didFinishLaunching
            case didUpdateTab(Tab)
        }

        enum ReducerAction: Equatable {
            case userListenerResponse(Firebase.User?)
            case fetchUserResponse(TaskResult<User?>)
        }

        enum DelegateAction: Equatable {

        }

        case view(ViewAction)
        case reducer(ReducerAction)
        case delegate(DelegateAction)

        case onboarding(OnboardingLoginFeature.Action)
        case home(HomeFeature.Action)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .view(action):
                switch action {
                case .didFinishLaunching:

                    //if !userDefaults.hasCompletedOnboarding {
                        state.onboarding = .init()
                    //}

                    return .run { send in
                        for await user in self.userClient.registerAuthStateHandler() {
                            await send(.reducer(.userListenerResponse(user)))
                        }
                    }
                case let .didUpdateTab(tab):
                    state.tab = tab
                    return .none
                }
            case let .reducer(action):
                switch action {
                case let .userListenerResponse(user):
                    guard let user = user else {
                        // If the user is not logged in, we shouldn't prompt them to log in but instead log them in as an anonymous user.
                        return .run { _ in
                            _ = try await self.userClient.signInAnonymously()
                        }
                    }

                    return .run { send in
                        await send(.reducer(.fetchUserResponse(await TaskResult {
                            try await userClient.getUser(user)
                        })))
                    }
                case let .fetchUserResponse(.success(user)):
                    if let user = user {
                        return .run { _ in
                            await userClient.setUser(user)
                        }
                    }
                    return .none
                case .fetchUserResponse(.failure):
                    return .none
                }
            case .delegate:
                return .none
            case let .onboarding(.delegate(action)):
                switch action {
                case .didContinueOnboarding:
                    state.onboarding = nil
                    return .none
                }
            case let .onboarding(.notifications(.delegate(action))):
                switch action {
                case .didCompleteOnboarding:
                    state.onboarding = nil
                    return .none
                }
            case .onboarding, .home:
                return .none
            }
        }
        .ifLet(\.onboarding, action: /Action.onboarding) {
            OnboardingLoginFeature()
        }

        Scope(state: \.home, action: /Action.home) {
            HomeFeature()
        }
    }
}
