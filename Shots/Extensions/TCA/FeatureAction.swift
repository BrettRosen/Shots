//
//  FeatureAction.swift
//  World of Wealth
//
//  Created by Brett Rosen on 11/23/23.
//

import CasePaths
import Combine
import ComposableArchitecture

/// A `FeatureAction` provides a standard structure for the actions in a TCA reducer
///
/// Often in a TCA reducer there are broadly three classes of actions:
/// 1. Those triggered from the view layer (either by the user or from system actions) (`ViewAction`)
/// 2. Those that are implementation details of the reducer (such as receiving an API response) (`ReducerAction`)
/// 3. Those that act as a delegate and pass actions to their parent (`DelegateAction`)
///
/// An example of how you would implement this protocol might look something like this:
/// ```swift
/// enum Action: FeatureAction {
///   enum ViewAction {
///     case onDidTapPublishListingButton
///   }
///
///   enum ReducerAction {
///     case didReceivePublishListingResponse(TaskResult<Listing>)
///   }
///
///   enum DelegateAction {
///     case didFinishPublishingListing
///   }
///
///   case view(ViewAction)
///   case reducer(ReducerAction)
///   case delegate(DelegateAction)
/// }
/// ```
public protocol FeatureAction {
    /// A set of actions that represent how the view layer can interact with this reducer
    ///
    /// This often includes things such as user interactions and system actions such
    /// as UIKit interactions (e.g. `viewDidLoad`). You should consider this to be
    /// the public interface for how the view, as well as other reducers, can interact with
    /// this reducer.
    associatedtype ViewAction

    /// A set of actions that represent internal implementation details of this reducer
    ///
    /// This will include this like API responses and other scenarios when a some side
    /// effect of one action wants to feed another action back into the reducer.
    associatedtype ReducerAction

    /// A set of actions that represent how this reducer can communicate with its
    /// parent reducer
    ///
    /// Think of this as a modification of the delegate pattern for the TCA world.
    /// If you want to notify your parent that something has happened, an action
    /// under this is how you would do it!
    associatedtype DelegateAction

    /// An enum case that holds all view-related actions
    static func view(_: ViewAction) -> Self

    /// An enum case that holds all internal implementation detail actions
    static func reducer(_: ReducerAction) -> Self

    /// An enum case that holds all delegate-pattern actions
    static func delegate(_: DelegateAction) -> Self
}

public extension Scope where ParentAction: FeatureAction {
    @inlinable
    init<ChildState, ChildAction>(
        state toChildState: WritableKeyPath<ParentState, ChildState>,
        action toChildAction: AnyCasePath<ParentAction.ReducerAction, ChildAction>,
        @ReducerBuilder<ChildState, ChildAction> _ child: () -> Child
    ) where ChildState == Child.State, ChildAction == Child.Action {
        self = .init(
            state: toChildState,
            action: (/ParentAction.reducer) .. toChildAction,
            child: child
        )
    }
}

public extension Store where Action: FeatureAction {
    func scope<ChildState, ChildAction>(
        state toChildState: @escaping (State) -> ChildState,
        action fromChildAction: AnyCasePath<Action.ReducerAction, ChildAction>
    ) -> Store<ChildState, ChildAction> {
        scope(
            state: toChildState,
            action: { .reducer(fromChildAction.embed($0)) }
        )
    }
}

public extension Reducer where Action: FeatureAction {
    @inlinable
    func ifLet<WrappedState, WrappedAction, Wrapped: Reducer>(
        _ toWrappedState: WritableKeyPath<State, WrappedState?>,
        action toWrappedAction: AnyCasePath<Action.ReducerAction, WrappedAction>,
        @ReducerBuilder<WrappedState, WrappedAction> then wrapped: () -> Wrapped,
        fileID: StaticString = #fileID,
        line: UInt = #line
    ) -> _IfLetReducer<Self, Wrapped> where WrappedState == Wrapped.State, WrappedAction == Wrapped.Action {
        // swiftformat:disable redundantSelf
        self.ifLet(
            toWrappedState,
            action: (/Action.reducer) .. toWrappedAction,
            then: wrapped,
            fileID: fileID,
            line: line
        )
        // swiftformat:enable redundantSelf
    }

    @inlinable
    func ifCaseLet<CaseState, CaseAction, Case: Reducer>(
        _ toCaseState: AnyCasePath<State, CaseState>,
        action toCaseAction: AnyCasePath<Action.ReducerAction, CaseAction>,
        @ReducerBuilder<CaseState, CaseAction> then case: () -> Case,
        fileID: StaticString = #fileID,
        line: UInt = #line
    ) -> _IfCaseLetReducer<Self, Case>
        where CaseState == Case.State, CaseAction == Case.Action {
        // swiftformat:disable redundantSelf
        self.ifCaseLet(
            toCaseState,
            action: (/Action.reducer) .. toCaseAction,
            then: `case`,
            fileID: fileID,
            line: line
        )
        // swiftformat:enable redundantSelf
    }

    @inlinable
    func forEach<ElementState, ElementAction, ID: Hashable, Wrapped: Reducer>(
        _ toElementsState: WritableKeyPath<State, IdentifiedArray<ID, ElementState>>,
        action toElementAction: AnyCasePath<Action.ReducerAction, (ID, ElementAction)>,
        @ReducerBuilder<ElementState, ElementAction> element: () -> Wrapped,
        fileID: StaticString = #fileID,
        line: UInt = #line
    ) -> _ForEachReducer<Self, ID, Wrapped>
        where ElementState == Wrapped.State, ElementAction == Wrapped.Action {
        // swiftformat:disable redundantSelf
        self.forEach(
            toElementsState,
            action: /Action.reducer .. toElementAction,
            element: element,
            fileID: fileID,
            line: line
        )
        // swiftformat:enable redundantSelf
    }
}
