//
//  ShotsApp.swift
//  Shots
//
//  Created by Brett Rosen on 12/8/23.
//

import ComposableArchitecture
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        return true
    }
}

@main
struct ShotsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            HomeView(store: .init(initialState: .init(), reducer: {
                HomeFeature()
            }))
        }
    }
}
