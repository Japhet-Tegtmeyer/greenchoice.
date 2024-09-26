//
//  SettingsRow.swift
//  GreenChoice
//
//  Created by Japhet Tegtmeyer on 9/22/24.
//

import SwiftUI

struct SettingsRow: View {
    let destination: any View
    let symbol: String
    let text: String
    let color: Color
    var body: some View {
        NavigationLink {
            AnyView(destination)
                .navigationBarBackButtonHidden()
        } label: {
            HStack {
                Image(systemName: symbol)
                    .foregroundStyle(color)
                
                Text(text)
                    .foregroundStyle(.black)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .imageScale(.small)
                    .foregroundStyle(.gray)
            }
            .padding(.horizontal)
            .frame(height: 44, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal, 30)
            .padding(.vertical, 5)
        }
    }
}
