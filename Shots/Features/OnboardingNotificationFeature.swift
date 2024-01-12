//
//  OnboardingNotificationFeature.swift
//  Shots
//
//  Created by Brett Rosen on 1/11/24.
//

import ComposableArchitecture
import Foundation

struct OnboardingNotificationFeature: Reducer {
    @Dependency(\.userDefaults) var userDefaults

    struct State: Equatable {

    }

    enum Action: Equatable, FeatureAction {
        enum ViewAction: Equatable {
            case laterButtonTapped
        }

        enum ReducerAction: Equatable {

        }

        enum DelegateAction: Equatable {
            case didCompleteOnboarding
        }

        case view(ViewAction)
        case reducer(ReducerAction)
        case delegate(DelegateAction)
    }

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case let .view(action):
                switch action {
                case .laterButtonTapped:
                    return .merge(
                        .send(.delegate(.didCompleteOnboarding)),
                        .run { _ in
                            await userDefaults.setHasCompletedOnboarding(true)
                        }
                    )
                }
            case let .reducer(action):
                switch action {

                }
            case .delegate:
                return .none
            }
        }
    }
}
