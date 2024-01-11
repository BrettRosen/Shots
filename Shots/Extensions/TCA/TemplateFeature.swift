//
//  TemplateFeature.swift
//  World of Wealth
//
//  Created by Brett Rosen on 11/23/23.
//

import ComposableArchitecture
import Foundation

@Reducer
struct TemplateFeature {
    struct State: Equatable {

    }

    enum Action: Equatable, FeatureAction {
        enum ViewAction: Equatable {

        }

        enum ReducerAction: Equatable {

        }

        enum DelegateAction: Equatable {

        }

        case view(ViewAction)
        case reducer(ReducerAction)
        case delegate(DelegateAction)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .view(action):
                switch action {

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
