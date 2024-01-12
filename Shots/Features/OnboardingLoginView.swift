//
//  OnboardingLoginView.swift
//  Shots
//
//  Created by Brett Rosen on 1/11/24.
//

import _AuthenticationServices_SwiftUI
import ComposableArchitecture
import IdentifiedCollections
import SwiftUI
import UIKit

struct OnboardingInfoPage: Equatable, Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String
    let image: UIImage
    let color: Color

    /// This image represents the segmented subject, set by the `OnboardingLoginFeature`
    var maskedImage: UIImage?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static let all: IdentifiedArrayOf<OnboardingInfoPage> = [
        .init(
            title: "WELCOME TO \nSHOTS",
            description: "Share and discovery photography with an unmatched viewing experience",
            image: UIImage(named: "landing1")!,
            color: .blue
        ),
        .init(
            title: "CAPTURE YOUR STORY", 
            description: "Shot's \"Film rolls\" allow you to share a series of photos that weave together your unique narrative.",
            image: UIImage(named: "landing2")!,
            color: .red
        ),
        .init(
            title: "SUPPORT WITH PRINTS", 
            description: "Effortlessly purchase prints to support the artists behind your favorite shots.", 
            image: UIImage(named: "landing3")!,
            color: .green
        ),
    ]
}
