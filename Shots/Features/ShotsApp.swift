//
//  ShotsApp.swift
//  Shots
//
//  Created by Brett Rosen on 12/8/23.
//

import Firebase
import ComposableArchitecture
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        FirebaseApp.configure()
        return true
    }
}


extension AppFeature {
    struct ViewState: Equatable {
        var tab: Tab
        init(_ state: State) {
            tab = state.tab
        }
    }
}

@main
struct ShotsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let store: StoreOf<AppFeature> = Store(initialState: .init()) {
        AppFeature()
    }

    @Namespace private var namespace

    var body: some Scene {
        WindowGroup {
            WithViewStore(store, observe: AppFeature.ViewState.init, send: AppFeature.Action.view) { viewStore in
                HStack(spacing: 0) {
                    VTabView(selection: viewStore.binding(get: \.tab, send: AppFeature.Action.ViewAction.didUpdateTab).animation(.linear(duration: 0.2))) {
                        ForEach(AppFeature.Tab.allCases) { tab in
                            switch tab {
                            case .home:
                                HomeView(store: store.scope(state: \.home, action: AppFeature.Action.home))
                            case .explore:
                                Text("EXPLORE")
                            case .profile:
                                Text("PROFILE")
                            case .settings:
                                Text("SETTINGS")
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    Spacer()
                    VStack(alignment: .trailing) {
                        ForEach(AppFeature.Tab.allCases) { tab in
                            let isSelected = tab == viewStore.tab
                            Spacer()
                            Button {
                                viewStore.send(.didUpdateTab(tab), animation: .linear(duration: 0.2))
                            } label: {
                                VStack {
                                    Text(tab.rawValue.uppercased())
                                        .font(.footnote)
                                        .fontWeight(isSelected ? .bold : .regular)
                                        .foregroundStyle(isSelected ? Color.yellow : Color.primary)
                                        .sensoryFeedback(.impact(flexibility: .soft), trigger: isSelected)
                                    if isSelected {
                                        Rectangle()
                                            .fill(Color.yellow)
                                            .frame(width: 12, height: 2)
                                            .matchedGeometryEffect(id: tab, in: namespace)
                                    } else {
                                        Rectangle()
                                            .fill(Color.clear)
                                            .frame(width: 12, height: 2)
                                    }
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}
