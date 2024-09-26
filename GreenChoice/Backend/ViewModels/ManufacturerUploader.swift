//
//  ManufacturerUploader.swift
//  GreenChoice
//
//  Created by Japhet Tegtmeyer on 9/25/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestore

class ManufacturerUploader: ObservableObject {
    private let db = Firestore.firestore()
    
    func createManufacturers() -> [Manufacturer] {
        return [
            Manufacturer(
                name: "Apple Inc.",
                website: "https://www.apple.com",
                sustainabilityScores: SustainabilityScores(
                    carbonFootprint: 25, // Lower is better
                    waterUsage: 30,
                    wasteManagement: 85,
                    energyEfficiency: 90,
                    sustainableSourcing: 80,
                    socialResponsibility: 85
                ),
                overallSustainabilityScore: 0, // Will be calculated
                lastUpdated: Date(),
                certifications: [.energyStar, .iso14001]
            ),
            Manufacturer(
                name: "Unilever",
                website: "https://www.unilever.com",
                sustainabilityScores: SustainabilityScores(
                    carbonFootprint: 35,
                    waterUsage: 40,
                    wasteManagement: 80,
                    energyEfficiency: 75,
                    sustainableSourcing: 85,
                    socialResponsibility: 80
                ),
                overallSustainabilityScore: 0,
                lastUpdated: Date(),
                countryOfOrigin: "United Kingdom/Netherlands",
                certifications: [.rainforestAlliance, .fairtrade]
            ),
            Manufacturer(
                name: "Patagonia",
                website: "https://www.patagonia.com",
                sustainabilityScores: SustainabilityScores(
                    carbonFootprint: 20,
                    waterUsage: 25,
                    wasteManagement: 90,
                    energyEfficiency: 85,
                    sustainableSourcing: 95,
                    socialResponsibility: 95
                ),
                overallSustainabilityScore: 0,
                lastUpdated: Date(),
                countryOfOrigin: "USA",
                certifications: [.bCorp, .fairtrade, .bluesign]
            ),
            Manufacturer(
                name: "Tesla, Inc.",
                website: "https://www.tesla.com",
                sustainabilityScores: SustainabilityScores(
                    carbonFootprint: 30,
                    waterUsage: 45,
                    wasteManagement: 80,
                    energyEfficiency: 95,
                    sustainableSourcing: 75,
                    socialResponsibility: 70
                ),
                overallSustainabilityScore: 0,
                lastUpdated: Date(),
                countryOfOrigin: "USA",
                certifications: [.iso14001, .energyStar]
            ),
            Manufacturer(
                name: "Nestlé",
                website: "https://www.nestle.com",
                sustainabilityScores: SustainabilityScores(
                    carbonFootprint: 40,
                    waterUsage: 50,
                    wasteManagement: 75,
                    energyEfficiency: 70,
                    sustainableSourcing: 80,
                    socialResponsibility: 75
                ),
                overallSustainabilityScore: 0,
                lastUpdated: Date(),
                countryOfOrigin: "Switzerland",
                certifications: [.rainforestAlliance, .fairtrade]
            ),
            Manufacturer(
                name: "IKEA",
                website: "https://www.ikea.com",
                sustainabilityScores: SustainabilityScores(
                    carbonFootprint: 35,
                    waterUsage: 40,
                    wasteManagement: 85,
                    energyEfficiency: 80,
                    sustainableSourcing: 90,
                    socialResponsibility: 85
                ),
                overallSustainabilityScore: 0,
                lastUpdated: Date(),
                countryOfOrigin: "Sweden",
                certifications: [.fsc, .energyStar]
            ),
            Manufacturer(
                name: "Adidas",
                website: "https://www.adidas.com",
                sustainabilityScores: SustainabilityScores(
                    carbonFootprint: 35,
                    waterUsage: 45,
                    wasteManagement: 80,
                    energyEfficiency: 75,
                    sustainableSourcing: 85,
                    socialResponsibility: 80
                ),
                overallSustainabilityScore: 0,
                lastUpdated: Date(),
                countryOfOrigin: "Germany",
                certifications: [.bluesign, .leatherWorkingGroup]
            ),
            Manufacturer(
                name: "Philips",
                website: "https://www.philips.com",
                sustainabilityScores: SustainabilityScores(
                    carbonFootprint: 30,
                    waterUsage: 35,
                    wasteManagement: 85,
                    energyEfficiency: 90,
                    sustainableSourcing: 80,
                    socialResponsibility: 85
                ),
                overallSustainabilityScore: 0,
                lastUpdated: Date(),
                countryOfOrigin: "Netherlands",
                certifications: [.iso14001, .energyStar, .carbonTrust]
            )
        ]
    }
    
    func uploadManufacturers() async {
        let manufacturers = createManufacturers()
        
        for var manufacturer in manufacturers {
            // Calculate the overall sustainability score
            manufacturer.overallSustainabilityScore = Manufacturer.calculateOverallScore(from: manufacturer.sustainabilityScores)
            
            do {
                // Use the manufacturer's name as the document ID
                let docRef = db.collection("manufacturers").document(manufacturer.name)
                try await docRef.setData(from: manufacturer)
                print("Successfully uploaded manufacturer: \(manufacturer.name)")
            } catch {
                print("Error uploading manufacturer \(manufacturer.name): \(error.localizedDescription)")
            }
        }
        
        print("Finished uploading manufacturers")
    }
}

// Usage example
// Note: Ensure Firebase is properly configured in your app before running this
func runManufacturerUpload() async {
    let uploader = ManufacturerUploader()
    await uploader.uploadManufacturers()
}

// Extension to add new certifications
