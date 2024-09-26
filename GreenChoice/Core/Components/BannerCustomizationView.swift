//
//  BannerCustomizationView.swift
//  GreenChoice
//
//  Created by Japhet Tegtmeyer on 9/22/24.
//

import SwiftUI
import FirebaseStorage
import FirebaseFirestore

struct BannerCustomizationView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var isPresented: Bool
    @State private var selectedColor: Color = .green
    @State private var isShowingImagePicker = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Text("Banner Color")
                    Spacer()
                    ColorPicker("", selection: $selectedColor)
                        .labelsHidden()
                        .frame(width: 50)
                    Text((authManager.currentUser?.preferences.bannerColor)!)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(8)
                .padding(.horizontal, 5)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.vertical)
                
                
                // MARK: Image Upload
//                if authManager.currentUser?.isPremium ?? false {
//                    Section(header: Text("Banner Image")) {
//                        Button(action: {
//                            isShowingImagePicker = true
//                        }) {
//                            HStack {
//                                Text("Add Banner")
//                                Spacer()
//                                Image(systemName: "chevron.right")
//                                    .foregroundColor(.gray)
//                            }
//                        }
//                        .foregroundColor(.primary)
//                        
//                        if let bannerImageURL = authManager.currentUser?.bannerImageURL,
//                           let url = URL(string: bannerImageURL) {
//                            AsyncImage(url: url) { image in
//                                image.resizable().aspectRatio(contentMode: .fit)
//                            } placeholder: {
//                                ProgressView()
//                            }
//                            .frame(height: 200)
//                            
//                            Button("Remove Image") {
//                                removeBannerImage()
//                            }
//                            .foregroundColor(.red)
//                        }
//                    }
//                }
                
                Spacer()
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Profile Banner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        saveChanges()
                        fetchUserData()
                    } label: {
                        Text("Done")
                            .font(.subheadline)
                            .bold()
                            .tint(.black)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(5)
                    }
                }
            }
            .sheet(isPresented: $isShowingImagePicker) {
                CameraPicker(imageSelected: uploadImage)
            }
            .overlay(
                Group {
                    if isLoading {
                        ProgressView()
                    }
                }
            )
        }
        .onAppear {
            if let bannerColor = authManager.currentUser?.preferences.bannerColor {
                selectedColor = Color(hex: bannerColor) ?? .green
            }
        }
    }
    
    // MARK: Helper Functions
    
    // MARK: Save Changes
    private func saveChanges() {
        guard let userId = authManager.currentUser?.id else { return }
        
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "preferences.bannerColor": selectedColor.hexString ?? "#76F387"
        ]) { error in
            if let error = error {
                errorMessage = "Failed to update banner color: \(error.localizedDescription)"
            } else {
                isPresented = false
            }
            isLoading = false
        }
    }
    
    // MARK: Upload Image
    private func uploadImage(_ image: UIImage) {
        guard let userId = authManager.currentUser?.id else { return }
        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return }
        
        isLoading = true
        errorMessage = nil
        
        let storageRef = Storage.storage().reference().child("banners/\(userId).jpg")
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                errorMessage = "Failed to upload image: \(error.localizedDescription)"
                isLoading = false
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    errorMessage = "Failed to get download URL: \(error.localizedDescription)"
                    isLoading = false
                    return
                }
                
                guard let downloadURL = url else {
                    errorMessage = "Failed to get download URL"
                    isLoading = false
                    return
                }
                
                let db = Firestore.firestore()
                db.collection("users").document(userId).updateData([
                    "bannerImageURL": downloadURL.absoluteString
                ]) { error in
                    if let error = error {
                        errorMessage = "Failed to update banner image URL: \(error.localizedDescription)"
                    } else {
                        // Update the local user object
                        authManager.currentUser?.bannerImageURL = downloadURL.absoluteString
                    }
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: Remove Image
    private func removeBannerImage() {
        guard let userId = authManager.currentUser?.id else { return }
        
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "bannerImageURL": FieldValue.delete()
        ]) { error in
            if let error = error {
                errorMessage = "Failed to remove banner image: \(error.localizedDescription)"
            } else {
                // Update the local user object
                authManager.currentUser?.bannerImageURL = nil
            }
            isLoading = false
        }
        
        // Optionally, you can also delete the image from Firebase Storage
        let storageRef = Storage.storage().reference().child("banners/\(userId).jpg")
        storageRef.delete { error in
            if let error = error {
                print("Failed to delete banner image from storage: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: Fetch User Data
    private func fetchUserData() {
        Task {
            if let uid = authManager.currentUser?.id {
                await authManager.fetchUserData(for: uid)
            }
        }
    }
}
