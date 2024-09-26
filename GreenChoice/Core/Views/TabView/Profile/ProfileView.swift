//
//  ProfileView.swift
//  GreenChoice
//
//  Created by Japhet Tegtmeyer on 9/21/24.
//

import SwiftUI
import FirebaseFirestore

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showingBannerCustomization = false
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isLoading = false
    @AppStorage("tab") var selectedTab: Int = 0
    @State private var recentlyScannedItems: [Item] = []
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Top section with banner and profile picture
                ZStack(alignment: .topLeading) {
                    // MARK: Banner
                    Group {
                        if let bannerImageURL = authManager.currentUser?.bannerImageURL,
                           let url = URL(string: bannerImageURL),
                           authManager.currentUser?.isPremium ?? false {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                            } placeholder: {
                                ProgressView()
                            }
                        } else {
                            Rectangle().foregroundColor(Color(hex: authManager.currentUser?.preferences.bannerColor ?? "#76F387"))
                        }
                    }
                    .frame(height: 172)
                    .onTapGesture {
                        showingBannerCustomization = true
                    }
                    
                    VStack(alignment: .leading) {
                        HStack(alignment: .bottom) {
                            // MARK: PFP
                            Group {
                                if let profileImageURL = authManager.currentUser?.profileImageURL,
                                   let url = URL(string: profileImageURL) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        ProgressView()
                                    }
                                } else {
                                    Image("defaultpfp")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                }
                            }
                            .frame(width: 118, height: 118)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 5)
                            )
                            .offset(y: 118/2)
                            .zIndex(1)
                            .onTapGesture {
                                showingImagePicker = true
                            }
                            
                            // MARK: Plan Tag
                            Text(authManager.currentUser?.isPremium ?? false ? "PREMIUM" : "BASIC")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(authManager.currentUser?.isPremium ?? false ? .red : .blue)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        .padding(.top, 45)
                        
                        // MARK: User Info
                        VStack(alignment: .leading, spacing: 4) {
                            // MARK: Name
                            Text(authManager.currentUser?.displayName ?? "NO NAME")
                                .font(.title)
                                .fontWeight(.bold)
                                .padding(.top, 60)
                            
                            // MARK: Email
                            Text(authManager.currentUser?.email ?? "NO EMAIL")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom)
                        .padding(.leading)
                    }
                    .padding(.horizontal)
                }
                
                // MARK: Rows
                SettingsRow(destination: SettingsView(), symbol: "gearshape", text: "Settings", color: .blue)
                SettingsRow(destination: FavoriteProductsView(), symbol: "heart", text: "Favorite Products", color: .red)
                
                // MARK: Scanned Items
                VStack(alignment: .leading) {
                    Text("Recently Scanned")
                        .font(.subheadline)
                        .bold()
                        .padding(.top)
                    
                    if recentlyScannedItems.isEmpty {
                        VStack {
                            Text("No Items Scanned")
                            Button {
                                selectedTab = 1
                            } label: {
                                Text("Scan Some")
                                    .foregroundStyle(.black)
                                    .underline()
                                    .bold()
                            }
                        }
                        .frame(height: 100)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    } else {
                        VStack {
                            ForEach(recentlyScannedItems) { item in
                                NavigationLink(destination: ItemView(item: item)) {
                                    ItemRow(item: item)
                                        .padding(8)
                                        .frame(maxWidth: .infinity)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            .edgesIgnoringSafeArea(.top)
            .sheet(isPresented: $showingBannerCustomization) {
                BannerCustomizationView(isPresented: $showingBannerCustomization)
                    .presentationDetents([.height(150)])
            }
            .sheet(isPresented: $showingImagePicker) {
                CameraPicker { image in
                    selectedImage = image
                    uploadProfilePicture()
                }
            }
            .overlay(
                Group {
                    if isLoading {
                        ProgressView()
                    }
                }
            )
            .onAppear {
                fetchRecentlyScannedItems()
            }
        }
    }
    
    // MARK: Helper Functions
    
    private func fetchUserData() {
        Task {
            if let uid = authManager.currentUser?.id {
                await authManager.fetchUserData(for: uid)
            }
        }
    }
    
    private func fetchRecentlyScannedItems() {
        Task {
            if let userId = authManager.currentUser?.id {
                 try recentlyScannedItems = await authManager.fetchRecentlyScannedItems(for: userId, limit: 5)
            }
        }
    }
    
    private func uploadProfilePicture() {
        guard let image = selectedImage else { return }
        isLoading = true
        Task {
            do {
                try await authManager.uploadProfilePicture(image)
                isLoading = false
            } catch {
                print("Error uploading profile picture: \(error)")
                isLoading = false
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
}
