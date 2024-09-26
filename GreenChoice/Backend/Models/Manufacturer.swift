//
//  Manufacturer.swift
//  GreenChoice
//
//  Created by Japhet Tegtmeyer on 9/25/24.
//

import Foundation
import FirebaseFirestore

struct Manufacturer: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var name: String
    var website: String?
    var sustainabilityScores: SustainabilityScores
    var overallSustainabilityScore: Double
    var lastUpdated: Date
    var countryOfOrigin: String?
    var certifications: [Certification]
}

struct SustainabilityScores: Codable, Hashable {
    var carbonFootprint: Double // 0-100, lower is better
    var waterUsage: Double // 0-100, lower is better
    var wasteManagement: Double // 0-100, higher is better
    var energyEfficiency: Double // 0-100, higher is better
    var sustainableSourcing: Double // 0-100, higher is better
    var socialResponsibility: Double // 0-100, higher is better
}

enum Certification: String, Codable, CaseIterable, Hashable {
    case fairtrade = "Fairtrade"
    case organicUSDA = "USDA Organic"
    case rainforestAlliance = "Rainforest Alliance"
    case bCorp = "B Corporation"
    case energyStar = "Energy Star"
    case fsc = "Forest Stewardship Council (FSC)"
    case greenSeal = "Green Seal"
    case ecologo = "ECOLOGO"
    case cradle2Cradle = "Cradle to Cradle"
    case iso14001 = "ISO 14001"
    case globalOrganicTextile = "Global Organic Textile Standard (GOTS)"
    case bluesign = "Bluesign"
    case leatherWorkingGroup = "Leather Working Group"
    case greenguard = "GREENGUARD"
    case carbonTrust = "Carbon Trust Standard"
    case animalWelfare = "Animal Welfare Approved"
    case msc = "Marine Stewardship Council (MSC)"
    case asc = "Aquaculture Stewardship Council (ASC)"
}

extension Manufacturer {
    static func calculateOverallScore(from scores: SustainabilityScores) -> Double {
        // Define weights for each factor (must sum to 1)
        let weights: [String: Double] = [
            "carbonFootprint": 0.25,
            "waterUsage": 0.15,
            "wasteManagement": 0.15,
            "energyEfficiency": 0.20,
            "sustainableSourcing": 0.15,
            "socialResponsibility": 0.10
        ]
        
        // Normalize scores (0-100 scale)
        let normalizedScores: [String: Double] = [
            "carbonFootprint": normalizeInverse(scores.carbonFootprint),
            "waterUsage": normalizeInverse(scores.waterUsage),
            "wasteManagement": normalize(scores.wasteManagement),
            "energyEfficiency": normalize(scores.energyEfficiency),
            "sustainableSourcing": normalize(scores.sustainableSourcing),
            "socialResponsibility": normalize(scores.socialResponsibility)
        ]
        
        // Calculate weighted sum
        let weightedSum = weights.reduce(0) { (result, item) in
            result + (item.value * (normalizedScores[item.key] ?? 0))
        }
        
        // Apply non-linear transformation to emphasize differences
        let scaledScore = sigmoid(weightedSum, midpoint: 50, steepness: 0.1)
        
        // Round to two decimal places
        return (scaledScore * 100).rounded() / 100
    }
    
    private static func normalize(_ value: Double) -> Double {
        return max(0, min(value, 100)) / 100
    }
    
    private static func normalizeInverse(_ value: Double) -> Double {
        return 1 - (max(0, min(value, 100)) / 100)
    }
    
    private static func sigmoid(_ x: Double, midpoint: Double, steepness: Double) -> Double {
        return 1 / (1 + exp(-steepness * (x - midpoint)))
    }
}
