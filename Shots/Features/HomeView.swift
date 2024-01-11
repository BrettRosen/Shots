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

@Reducer
struct HomeFeature {
    struct State: Equatable {
        var pickerItem: PhotosPickerItem?
        var image: Image?
        var filmOpacity: Double = 0.2
        var aspectRatio: Double = 1.0
        var iso: String = ""
        var focalLen: String = ""
        var exposureValue: String = ""
        var fStop: String = ""
        var shutterSpeed: String = ""
    }

    enum Action: Equatable, FeatureAction {
        enum ViewAction: Equatable {
            case updatePickerItem(PhotosPickerItem?)
            case updateFilmOpacity(Double)
        }

        enum ReducerAction: Equatable {
            case loadTransferableResult(Data)
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
                case let .updatePickerItem(item):
                    state.pickerItem = item
                    return .run { send in
                        if let data = try await item?.loadTransferable(type: Data.self) {
                            await send(.reducer(.loadTransferableResult(data)))
                        }
                    }
                case let .updateFilmOpacity(opacity):
                    state.filmOpacity = opacity
                    return .none
                }
            case let .reducer(action):
                switch action {
                case let .loadTransferableResult(data):
                    if let uiImage = UIImage(data: data) {
                        state.image = Image(uiImage: uiImage)
                    }

                    if let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
                       let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [NSString: Any] {

                        if let height = imageProperties["PixelHeight"] as? Double, let width = imageProperties["PixelWidth"] as? Double {
                            state.aspectRatio =  width / height
                        }

                        if let exif = imageProperties["{Exif}"] as? [NSString: Any] {
                            if let isoValues = exif["ISOSpeedRatings"] as? [Int], let iso = isoValues.first {
                                state.iso = "\(iso)"
                            }
                            if let focalLen = exif["FocalLenIn35mmFilm"] as? Int {
                                state.focalLen = "\(focalLen)"
                            }
                            if let exposureValue = exif["ExposureBiasValue"] as? Double {
                                state.exposureValue = "\(exposureValue)"
                            }
                            if let fStop = exif["FNumber"] as? Double {
                                state.fStop = "\(fStop)"
                            }
                            if let shutterSpeed = exif["ShutterSpeedValue"] as? Double {
                                state.shutterSpeed = convertApexToShutterSpeedString(shutterSpeed)
                            }
                        }
                    }

                    return .none
                }
            case .delegate:
                return .none
            }
        }
    }

    private func convertApexToShutterSpeedString(_ apexValue: Double) -> String {
        let shutterSpeed = 1 / pow(2.0, apexValue)

        // Find the nearest common shutter speed fraction
        let commonShutterSpeeds: [Double] = [1/4000, 1/2000, 1/1000, 1/500, 1/250, 1/125, 1/60, 1/30, 1/15, 1/8, 1/4, 1/2, 1]
        let closest = commonShutterSpeeds.min(by: { abs($0 - shutterSpeed) < abs($1 - shutterSpeed) }) ?? shutterSpeed

        // Convert to a fraction string
        let denominator = 1 / closest
        let roundedDenominator = round(denominator)
        return "1/\(Int(roundedDenominator))"
    }
}

extension HomeFeature {
    struct ViewState: Equatable {
        var pickerItem: PhotosPickerItem?
        var image: Image?
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

struct ContentView: View {
    let store: StoreOf<HomeFeature>

    var body: some View {
        WithViewStore(store, observe: HomeFeature.ViewState.init, send: HomeFeature.Action.view) { viewStore in
            VStack {
                PhotosPicker("Select image", selection: viewStore.binding(get: \.pickerItem, send: HomeFeature.Action.ViewAction.updatePickerItem), matching: .images)
                    .buttonStyle(.plain)
                Slider(value: viewStore.binding(get: \.filmOpacity, send: HomeFeature.Action.ViewAction.updateFilmOpacity), in: 0...0.5) {
                    Text("Film Opacity")
                }
                Spacer()
                if let image = viewStore.image {
                    VStack(alignment: .leading, spacing: 8) {
                        ZStack {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: screen.width - 32, height: screen.width / viewStore.aspectRatio)
                                .clipped()
                            Image("film2")
                                .resizable()
                                .scaledToFill()
                                .frame(width: screen.width - 32, height: screen.width / viewStore.aspectRatio)
                                .clipped()
                                .opacity(viewStore.filmOpacity)
                        }

                        HStack(spacing: 10) {
                            Text("ISO " + viewStore.iso)
                                .font(.nohemi)
                                .fontWeight(.regular)
                            Text(viewStore.focalLen + " mm")
                                .font(.nohemi)
                                .fontWeight(.regular)
                            Text(viewStore.exposureValue + " ev")
                                .font(.nohemi)
                                .fontWeight(.regular)
                            Text("f" + viewStore.fStop)
                                .font(.nohemi)
                                .fontWeight(.regular)
                            Text(viewStore.shutterSpeed + " s")
                                .font(.nohemi)
                                .fontWeight(.regular)
                        }
                        .foregroundStyle(.matching)

                    }
                    .padding(16)
                    .background(Color.primary)
                }
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView(store: .init(initialState: .init(), reducer: {
        HomeFeature()
    }))
}
