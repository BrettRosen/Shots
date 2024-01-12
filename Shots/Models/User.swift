//
//  User.swift
//  Shots
//
//  Created by Brett Rosen on 1/11/24.
//

import Foundation

struct User: Equatable, Codable, Hashable, Identifiable {
    var id: String
    var createdAt: Date
    var email: String?
    var name: String?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
