//
//  ShotsApp.swift
//  Shots
//
//  Created by Brett Rosen on 12/8/23.
//

import Firebase
import ComposableArchitecture
import SwiftUI

extension AppDelegate {
    struct ViewState: Equatable {
        init(_ state: AppFeature.State) { }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    let store = Store(
        initialState: AppFeature.State(),
        reducer: { AppFeature() }
    )

    lazy var viewStore: ViewStore = ViewStore(
        store,
        observe: Self.ViewState.init,
        send: AppFeature.Action.view
    )

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        FirebaseApp.configure()

        self.viewStore.send(.didFinishLaunching)
        return true
    }
}

@main
struct ShotsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            AppView(store: appDelegate.store)
        }
    }
}

struct AppView: View {
    let store: StoreOf<AppFeature>

    @Namespace private var namespace

    struct ViewState: Equatable {
        var tab: AppFeature.Tab
        init(_ state: AppFeature.State) {
            tab = state.tab
        }
    }

    var body: some View {
        WithViewStore(store, observe: ViewState.init, send: AppFeature.Action.view) { viewStore in
            ZStack {
                IfLetStore(store.scope(
                    state: \.onboarding,
                    action: AppFeature.Action.onboarding
                ),
                then: OnboardingLoginView.init(store:),
                else: {
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
                })
                .transition(.opacity)

                IfLetStore(store.scope(
                    state: \.landing,
                    action: AppFeature.Action.landing
                ), then: LandingView.init(store:))
                .transition(.opacity)
            }
            .sheet(store: store.scope(state: \.$loginModal, action: AppFeature.Action.loginModal)) { store in
                LoginModal(store: store)
            }
        }
    }
}
