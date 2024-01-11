//
//  ImageClient.swift
//  Shots
//
//  Created by Brett Rosen on 12/20/23.
//

import ComposableArchitecture
import CoreImage
import Foundation
import OSLog
import UIKit
import Vision

struct ImageClient {
    var analyzeImage: @Sendable (CGImage) async throws -> UIImage?

    static func image(from pixelBuffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            Logger().log(level: .error, "Could not create CGImage from CVPixelBuffer")
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}

extension ImageClient: DependencyKey {
    static var liveValue: Self = .init(
        analyzeImage: { sourceImage -> UIImage? in
            let request = VNGenerateForegroundInstanceMaskRequest()
            let handler = VNImageRequestHandler(cgImage: sourceImage)
            do {
                try handler.perform([request])
                guard let result = request.results?.first else {
                    return nil
                }
                let output = try result.generateMaskedImage(
                    ofInstances: result.allInstances,
                    from: handler,
                    croppedToInstancesExtent: false
                )
                return Self.image(from: output)
            } catch {
                Logger().log(level: .error, "Failed to analyze image")
                print(error.localizedDescription)
                throw error
            }
        }
    )
}

extension DependencyValues {
    var imageClient: ImageClient {
        get { self[ImageClient.self] }
        set { self[ImageClient.self] = newValue }
    }
}
