//
//  ContentView.swift
//  GreenChoice
//
//  Created by Japhet Tegtmeyer on 9/21/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack {
            VStack(spacing: 16) {
                if authManager.authState != .signedOut {
                    MainTabView()
                } else {
                    AuthView()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
