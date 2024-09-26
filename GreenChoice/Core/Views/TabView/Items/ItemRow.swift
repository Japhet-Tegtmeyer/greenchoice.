//
//  ItemRow.swift
//  GreenChoice
//
//  Created by Japhet Tegtmeyer on 9/24/24.
//

import SwiftUI
import FirebaseFirestore

struct ItemRow: View {
    var item: Item

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let photoUrl = item.photoUrl, let url = URL(string: photoUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .cornerRadius(6)
                    } placeholder: {
                        ProgressView()
                            .frame(width: 120, height: 120)
                    }
                } else {
                    Rectangle()
                        .foregroundColor(Color(.systemGray6))
                        .frame(width: 120, height: 120)
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading) {
                    Text(item.itemName)
                        .lineLimit(2)
                        .bold()
                        .multilineTextAlignment(.leading)
                    
                    Text(item.barcodeId)
                        .bold()
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                    
                    Text(item.manufacturer)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                
                Spacer ()
                
                Image(systemName: "chevron.right")
                    .imageScale(.small)
                    .foregroundStyle(.gray)
                    .padding(.trailing, 4)
            }
        }
    }
}
