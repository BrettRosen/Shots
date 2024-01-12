//
//  OnboardingLoginFeature.swift
//  Shots
//
//  Created by Brett Rosen on 1/11/24.
//

import AuthenticationServices
import ComposableArchitecture
import Foundation
import IdentifiedCollections
import UIKit

struct OnboardingLoginFeature: Reducer {
    @Dependency(\.userClient) var userClient
    @Dependency(\.imageClient) var imageClient
    @Dependency(\.userDefaults) var userDefaults

    struct State: Equatable {
        var infoPages = OnboardingInfoPage.all
        var currentInfoPage = OnboardingInfoPage.all.first!
        var imageScrollTarget: OnboardingInfoPage.ID?

        var loginSignupState: LoginSignupFeature.State = .init()

        var navigationPath: [NavigationDestination] = []
        var notificationOnboarding: OnboardingNotificationFeature.State = .init()
    }

    enum NavigationDestination: String, Equatable, Identifiable {
        var id: Self { self }
        case notifications
    }

    enum Action: Equatable, FeatureAction {
        enum ViewAction: Equatable {
            case viewAppeared
            case updateScrollID(OnboardingInfoPage.ID?)
            case updateCurrentInfoPage(OnboardingInfoPage)
            case updateNavigationPath([NavigationDestination])
            case continueButtonTapped
        }

        enum ReducerAction: Equatable {
            case maskedImageResult(pageID: OnboardingInfoPage.ID, TaskResult<UIImage?>)
        }

        enum DelegateAction: Equatable {
            case didContinueOnboarding
        }

        case view(ViewAction)
        case reducer(ReducerAction)
        case delegate(DelegateAction)
        case loginSignup(LoginSignupFeature.Action)
        case notifications(OnboardingNotificationFeature.Action)
    }

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case let .view(action):
                switch action {
                case .viewAppeared:
                    let maskedImageEffects: [Effect<Action>] = state.infoPages.compactMap { page -> Effect<Action>? in
                        guard let cgImage = page.image.cgImage else { return nil }
                        return Effect.run { send in
                            await send(.reducer(.maskedImageResult(pageID: page.id, await TaskResult {
                                try await imageClient.analyzeImage(cgImage)
                            })))
                        }
                    }
                    return .merge(maskedImageEffects)
                case let .updateScrollID(id):
                    state.imageScrollTarget = id
                    if let id = id, let page = state.infoPages[id: id] {
                        state.currentInfoPage = page
                    }
                    return .none

                case let .updateCurrentInfoPage(page):
                    state.currentInfoPage = page
                    state.imageScrollTarget = page.id
                    return .none

                case let .updateNavigationPath(path):
                    state.navigationPath = path
                    return .none

                case .continueButtonTapped:
                    if !self.userDefaults.hasCompletedOnboarding {
                        state.navigationPath.append(.notifications)
                        return .none
                    }
                    return .send(.delegate(.didContinueOnboarding))
                }
            case let .reducer(action):
                switch action {
                case let .maskedImageResult(pageId, .success(image)):
                    state.infoPages[id: pageId]?.maskedImage = image
                    return .none
                case .maskedImageResult(_, .failure):
                    return .none
                }
            case let .loginSignup(.delegate(action)):
                switch action {
                case .signInSucceeded:
                    if !self.userDefaults.hasCompletedOnboarding {
                        state.navigationPath.append(.notifications)
                        return .none
                    } else {
                        return .send(.delegate(.didContinueOnboarding))
                    }
                case .signInFailed:
                    return .none
                }
            case .loginSignup:
                return .none
            case .delegate:
                return .none
            case .notifications:
                return .none
            }
        }

        Scope(state: \.loginSignupState, action: /Action.loginSignup) {
            LoginSignupFeature()
        }

        Scope(state: \.notificationOnboarding, action: /Action.notifications) {
            OnboardingNotificationFeature()
        }
    }
}
