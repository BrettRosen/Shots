//
//  LoginSignupFeature.swift
//  Shots
//
//  Created by Brett Rosen on 1/11/24.
//

import AuthenticationServices
import ComposableArchitecture
import Foundation

struct LoginSignupFeature: Reducer {
    @Dependency(\.userClient) var userClient

    struct State: Equatable {
        var currentNonce: String?
        var isLoading: Bool = false
    }

    enum Action: Equatable, FeatureAction {
        enum ViewAction: Equatable {
            case handleSignInWithAppleRequest(ASAuthorizationAppleIDRequest)
            case handleSignInWithAppleCompletion(Result<ASAuthorization, Error>)
        }

        enum ReducerAction: Equatable {
            case signInResult(TaskResult<User>)
        }

        enum DelegateAction: Equatable {
            case signInFailed
            case signInSucceeded
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
                case let .handleSignInWithAppleRequest(request):
                    request.requestedScopes = [.email]
                    let nonce = randomNonceString()
                    state.currentNonce = nonce
                    request.nonce = sha256(nonce)
                    return .none

                case let .handleSignInWithAppleCompletion(.success(success)):
                    state.isLoading = true
                    let nonce = state.currentNonce

                    return .run { send in
                        await send(.reducer(.signInResult(TaskResult {
                            try await self.userClient.signInApple(success, nonce)
                        })))
                    }

                case .handleSignInWithAppleCompletion(.failure):
                    return .none
                }
            case let .reducer(action):
                switch action {
                case let .signInResult(.success(user)):
                    state.isLoading = false
                    return .concatenate(
                        .run { _ in await userClient.setUser(user) },
                        .send(.delegate(.signInSucceeded))
                    )

                case .signInResult(.failure):
                    state.isLoading = false
                    return .send(.delegate(.signInFailed))
                }
            case .delegate:
                return .none
            }
        }
    }
}

// Not auto-synthezied because of the Result type in `handleSignInWithAppleCompletion`
extension LoginSignupFeature.Action.ViewAction {
    static func == (
        lhs: LoginSignupFeature.Action.ViewAction,
        rhs: LoginSignupFeature.Action.ViewAction
    ) -> Bool {
        switch (lhs, rhs) {
        case (.handleSignInWithAppleRequest(let lhsRequest), .handleSignInWithAppleRequest(let rhsRequest)):
            return lhsRequest.user == rhsRequest.user // Not sure if this is correct
        case (.handleSignInWithAppleCompletion(let lhsResult), .handleSignInWithAppleCompletion(let rhsResult)):
            switch (lhsResult, rhsResult) {
            case (.success(let lhsAuth), .success(let rhsAuth)):
                return lhsAuth == rhsAuth
            case (.failure, .failure):
                return true
            default:
                return false
            }
        default:
            return false
        }
    }
}
