//
//  EquatableIgnored.swift
//  Shots
//
//  Created by Brett Rosen on 12/8/23.
//
import Foundation

@propertyWrapper
public struct EquatableIgnored<Wrapped>: Equatable {
    public var wrappedValue: Wrapped

    public init(wrappedValue: Wrapped) {
        self.wrappedValue = wrappedValue
    }

    public static func == (_: Self, _: Self) -> Bool { true }
}

/// Allows for the use of this property wrapper without losing the `Wrapped`'s Codable conformance
extension EquatableIgnored: Decodable where Wrapped: Decodable {
    public init(from decoder: Decoder) throws {
        do {
            self.init(wrappedValue: try decoder.singleValueContainer().decode(Wrapped.self))
        } catch {
            self.init(wrappedValue: try .init(from: decoder))
        }
    }
}

extension EquatableIgnored: Encodable where Wrapped: Encodable {
    public func encode(to encoder: Encoder) throws {
        do {
            var container = encoder.singleValueContainer()
            try container.encode(wrappedValue)
        } catch {
            try wrappedValue.encode(to: encoder)
        }
    }
}
