//
//  HomeFeature.swift
//  Shots
//
//  Created by Brett Rosen on 12/20/23.
//

import ComposableArchitecture
import Foundation
import PhotosUI
import SwiftUI

@Reducer
struct HomeFeature {
    @Dependency(\.imageClient) var imageClient

    struct State: Equatable {
        var pickerItem: PhotosPickerItem?
        var image: Image?
        var maskedImage: UIImage?
        var filmOpacity: Double = 0.1
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
            case maskedImageResult(TaskResult<UIImage?>)
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
                    state.maskedImage = nil
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
                    var imageEffect: Effect<Action>?
                    if let uiImage = UIImage(data: data), let cgImage = uiImage.cgImage {
                        state.image = Image(uiImage: uiImage)

                        imageEffect = .run { send in
                            await send(.reducer(.maskedImageResult(await TaskResult {
                                try await imageClient.analyzeImage(cgImage)
                            })))
                        }
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
                                state.shutterSpeed = convertApexToShutterSpeedString(shutterSpeed).replacingOccurrences(of: " ", with: "")
                            }
                        }
                    }

                    if let imageEffect {
                        return imageEffect.animation(.easeIn(duration: 1.5))
                    } else {
                        return .none
                    }
                case let .maskedImageResult(.success(image)):
                    state.maskedImage = image
                    return .none
                case .maskedImageResult(.failure):
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
