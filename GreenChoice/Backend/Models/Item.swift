//
//  Item.swift
//  GreenChoice
//
//  Created by Japhet Tegtmeyer on 9/22/24.
//

import Foundation
import FirebaseFirestore

struct Item: Codable, Identifiable {
    @DocumentID var id: String?
    var barcodeId: String
    var itemName: String
    var manufacturer: String // Manufacturer Id
    var photoUrl: String?
    var scanCount: Int = 0
}
