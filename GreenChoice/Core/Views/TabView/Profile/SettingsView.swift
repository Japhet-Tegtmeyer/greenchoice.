//
//  SettingsView.swift
//  GreenChoice
//
//  Created by Japhet Tegtmeyer on 9/22/24.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var hapticsEnabled: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    HStack {
                        Image("defaultpfp")
                            .resizable()
                            .frame(width: 93, height: 93)
                            .cornerRadius(25)
                            .padding(.trailing)
                        
                        VStack(alignment: .leading) {
                            Text("GreenChoice.")
                                .font(.title3)
                            Text("Built in Atlanta")
                                .foregroundStyle(.gray)
                            Text("Version 1.0.0.0")
                                .foregroundStyle(.gray)
                        }
                    }
                    
                    HStack {
                        Button {
                            if let url = URL(string: "mailto:japhet.tegtmeyer@icloud.com") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Image(systemName: "envelope.fill")
                                .frame(width: 40, height: 40)
                                .background(.blue)
                                .foregroundStyle(.white)
                                .cornerRadius(99)
                        }
                    }
                }
                .padding(.top, 8)
                
                List {
                    Section {
                        Toggle("Haptics", isOn: $hapticsEnabled)
                            .onChange(of: hapticsEnabled) { newValue in
                                updateFirebase(key: "hapticsEnabled", value: newValue)
                            }
                    }
                    
                    Button {
                        Task {
                            try await authManager.signOut()
                        }
                    } label: {
                        Text("Sign Out")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.subheadline)
                            .bold()
                            .tint(.black)
                            .padding(8)
                            .background(Color(.systemGreen).opacity(0.2))
                            .cornerRadius(5)
                    }
                }
            }
            .onAppear(perform: loadUserPreferences)
        }
    }
    
    // MARK: Helper Functions
    
    private func loadUserPreferences() {
        hapticsEnabled = authManager.currentUser?.preferences.hapticsEnabled ?? false
    }
    
    private func updateFirebase(key: String, value: Bool) {
        guard let userId = authManager.currentUser?.id else {
            print("Error: User ID not found")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "preferences.\(key)": value
        ]) { error in
            if let error = error {
                print("Error updating Firebase: \(error.localizedDescription)")
            } else {
                print("Successfully updated \(key) to \(value) in Firebase")
                // Update local user object
                switch key {
                case "hapticsEnabled":
                    authManager.currentUser?.preferences.hapticsEnabled = value
                default:
                    break
                }
            }
        }
    }
}
