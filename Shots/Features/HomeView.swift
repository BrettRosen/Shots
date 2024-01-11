//
//  ContentView.swift
//  Shots
//
//  Created by Brett Rosen on 12/8/23.
//

import ComposableArchitecture
import PhotosUI
import SwiftUI

let screen = UIScreen.main.bounds

extension HomeFeature {
    struct ViewState: Equatable {
        var pickerItem: PhotosPickerItem?
        var image: Image?
        var maskedImage: UIImage?
        var filmOpacity: Double
        var aspectRatio: Double
        var iso: String = ""
        var focalLen: String = ""
        var exposureValue: String = ""
        var fStop: String = ""
        var shutterSpeed: String = ""

        init(_ state: State) {
            pickerItem = state.pickerItem
            image = state.image
            maskedImage = state.maskedImage
            filmOpacity = state.filmOpacity
            aspectRatio = state.aspectRatio
            iso = state.iso
            focalLen = state.focalLen
            exposureValue = state.exposureValue
            fStop = state.fStop
            shutterSpeed = state.shutterSpeed
        }
    }
}

struct HomeView: View {
    let store: StoreOf<HomeFeature>

    var body: some View {
        WithViewStore(store, observe: HomeFeature.ViewState.init, send: HomeFeature.Action.view) { viewStore in
            HStack {
//                Slider(value: viewStore.binding(get: \.filmOpacity, send: HomeFeature.Action.ViewAction.updateFilmOpacity), in: 0...0.3) {
//                    Text("Film Opacity")
//                }

                ScrollView(.horizontal) {
                    HStack {
                        if let image = viewStore.image {
                            HStack(spacing: 8) {
                                ZStack {
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .clipped()

                                //                                if let maskedImage = viewStore.maskedImage {
                                //                                    Image(uiImage: maskedImage)
                                //                                        .resizable()
                                //                                        .aspectRatio(contentMode: .fill)
                                //                                        .frame(width: screen.width / viewStore.aspectRatio, height: screen.height)
                                //                                        .brightness(0.04)
                                //                                        .shadow(color: .black.opacity(0.6), radius: 10, x: 0, y: 0)
                                //                                        .transition(.opacity)
                                //                                        .clipped()
                                //                                }

                                }

                                VStack {
                                    Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
                                        GridRow {
                                            Text(viewStore.fStop)
                                                .font(.largeTitle)
                                                .bold()
                                                .padding(32)
                                                .overlay(alignment: .topLeading) {
                                                    Text("IRIS")
                                                        .font(.footnote)
                                                }

                                            Text(viewStore.focalLen)
                                                .font(.largeTitle)
                                                .bold()
                                                .padding([.vertical, .leading], 32)
                                                .overlay(alignment: .topLeading) {
                                                    Text("MM")
                                                        .font(.footnote)
                                                }
                                        }
                                        .padding(6)

                                        Divider()

                                        GridRow {
                                            Text(viewStore.shutterSpeed)
                                                .font(.largeTitle)
                                                .bold()
                                                .padding(32)
                                                .overlay(alignment: .topLeading) {
                                                    Text("SPEED")
                                                        .font(.footnote)
                                                }

                                            Text(viewStore.exposureValue)
                                                .font(.largeTitle)
                                                .bold()
                                                .padding([.vertical, .leading], 32)
                                                .overlay(alignment: .topLeading) {
                                                    Text("EV")
                                                        .font(.footnote)
                                                }
                                        }
                                        .padding(6)

                                        Divider()

                                        GridRow {
                                            Text(viewStore.iso)
                                                .font(.largeTitle)
                                                .bold()
                                                .padding([.vertical, .leading], 32)
                                                .overlay(alignment: .topLeading) {
                                                    Text("ISO")
                                                        .font(.footnote)
                                                }
                                        }
                                        .padding(6)
                                    }

                                    Spacer()
                                }
                            }
                        }

                        PhotosPicker("select", selection: viewStore.binding(get: \.pickerItem, send: HomeFeature.Action.ViewAction.updatePickerItem), matching: .images)
                            .buttonStyle(.plain)
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}

#Preview {
    HomeView(store: .init(initialState: .init(), reducer: {
        HomeFeature()
    }))
}
