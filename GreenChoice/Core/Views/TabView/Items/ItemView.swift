//
//  ItemView.swift
//  GreenChoice
//
//  Created by Japhet Tegtmeyer on 9/22/24.
//

import SwiftUI
import FirebaseFirestore

struct ItemView: View {
    var item: Item
    @State private var manufacturer: Manufacturer?
    @State private var isLoading = true
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                itemHeader
                
                if isLoading {
                    ProgressView()
                } else if let manufacturer = manufacturer {
                    manufacturerInfo(manufacturer)
                    sustainabilityScores(manufacturer)
                    certifications(manufacturer)
                } else {
                    Text("Manufacturer information not available")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Product Details")
        .onAppear(perform: fetchManufacturerInfo)
    }
    
    private var itemHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(item.itemName)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Barcode: \(item.barcodeId)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let url = item.photoUrl, let imageUrl = URL(string: url) {
                AsyncImage(url: imageUrl) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
                .frame(height: 200)
                .cornerRadius(10)
            }
        }
    }
    
    private func manufacturerInfo(_ manufacturer: Manufacturer) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Manufacturer")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(manufacturer.name)
                .font(.title3)
            
            if let website = manufacturer.website {
                Link("Website", destination: URL(string: website)!)
                    .font(.subheadline)
            }
            
            if let country = manufacturer.countryOfOrigin {
                Text("Country of Origin: \(country)")
                    .font(.subheadline)
            }
            
            Text("Overall Sustainability Score")
                .font(.headline)
                .padding(.top, 5)
            
            ProgressView(value: manufacturer.overallSustainabilityScore / 100)
                .accentColor(sustainabilityColor(score: manufacturer.overallSustainabilityScore))
            
            Text(String(format: "%.1f", manufacturer.overallSustainabilityScore))
                .font(.caption)
                .foregroundColor(sustainabilityColor(score: manufacturer.overallSustainabilityScore))
        }
    }
    
    private func sustainabilityScores(_ manufacturer: Manufacturer) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sustainability Scores")
                .font(.title2)
                .fontWeight(.bold)
            
            sustainabilityScoreRow(title: "Carbon Footprint", score: manufacturer.sustainabilityScores.carbonFootprint, invertColor: true)
            sustainabilityScoreRow(title: "Water Usage", score: manufacturer.sustainabilityScores.waterUsage, invertColor: true)
            sustainabilityScoreRow(title: "Waste Management", score: manufacturer.sustainabilityScores.wasteManagement)
            sustainabilityScoreRow(title: "Energy Efficiency", score: manufacturer.sustainabilityScores.energyEfficiency)
            sustainabilityScoreRow(title: "Sustainable Sourcing", score: manufacturer.sustainabilityScores.sustainableSourcing)
            sustainabilityScoreRow(title: "Social Responsibility", score: manufacturer.sustainabilityScores.socialResponsibility)
        }
    }
    
    private func sustainabilityScoreRow(title: String, score: Double, invertColor: Bool = false) -> some View {
        HStack {
            Text(title)
            Spacer()
            ProgressView(value: score / 100)
                .frame(width: 100)
                .accentColor(sustainabilityColor(score: invertColor ? 100 - score : score))
            Text(String(format: "%.1f", score))
                .frame(width: 40, alignment: .trailing)
                .foregroundColor(sustainabilityColor(score: invertColor ? 100 - score : score))
        }
    }
    
    private func certifications(_ manufacturer: Manufacturer) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Certifications")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 10) {
                ForEach(manufacturer.certifications, id: \.self) { certification in
                    Text(certification.rawValue)
                        .padding(8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
    }
    
    private func sustainabilityColor(score: Double) -> Color {
        switch score {
        case 0..<33:
            return .red
        case 33..<66:
            return .yellow
        default:
            return .green
        }
    }
    
    private func fetchManufacturerInfo() {
        let db = Firestore.firestore()
        db.collection("manufacturers").document(item.manufacturer).getDocument { (document, error) in
            isLoading = false
            if let document = document, document.exists {
                do {
                    manufacturer = try document.data(as: Manufacturer.self)
                } catch {
                    print("Error decoding manufacturer: \(error)")
                }
            } else {
                print("Manufacturer document does not exist")
            }
        }
    }
}
