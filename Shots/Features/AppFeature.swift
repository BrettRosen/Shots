//
//  AppFeature.swift
//  Shots
//
//  Created by Brett Rosen on 1/10/24.
//

import ComposableArchitecture
import Foundation

@Reducer
struct AppFeature {
    enum Tab: String, Equatable, CaseIterable, Identifiable {
        case home
        case explore
        case profile
        case settings

        var id: Self { self }
    }

    struct State: Equatable {
        var tab: Tab = .home

        var home: HomeFeature.State = .init()
    }

    enum Action: Equatable, FeatureAction {
        enum ViewAction: Equatable {
            case didUpdateTab(Tab)
        }

        enum ReducerAction: Equatable {

        }

        enum DelegateAction: Equatable {

        }

        case view(ViewAction)
        case reducer(ReducerAction)
        case delegate(DelegateAction)
        case home(HomeFeature.Action)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .view(action):
                switch action {
                case let .didUpdateTab(tab):
                    state.tab = tab
                    return .none
                }
            case let .reducer(action):
                switch action {

                }
            case .delegate:
                return .none
            case .home:
                return .none
            }
        }

        Scope(state: \.home, action: /Action.home) {
            HomeFeature()
        }
    }
}
