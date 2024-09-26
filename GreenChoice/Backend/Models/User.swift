//
//  User.swift
//  GreenChoice
//
//  Created by Japhet Tegtmeyer on 9/21/24.
//

import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable {
    @DocumentID var id: String?
    var email: String
    var displayName: String
    var createdAt: Date
    var lastLoginAt: Date
    var profileImageURL: String?
    var bannerImageURL: String?
    var scannedProducts: [String] // Array of product document IDs
    var favoriteProducts: [String] // Array of product document IDs
    var preferences: UserPreferences
    var isPremium: Bool
    var isAnonymous: Bool
}

struct UserPreferences: Codable {
    var hapticsEnabled: Bool
    var bannerColor: String
}
