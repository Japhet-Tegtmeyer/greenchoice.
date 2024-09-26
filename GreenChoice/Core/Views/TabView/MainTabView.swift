//
//  HomeView.swift
//  GreenChoice
//
//  Created by Japhet Tegtmeyer on 9/21/24.
//

import SwiftUI

// MARK: - Tab Model

enum TabItems: Int, CaseIterable{
    case home = 0
    case favorite
    case chat
    case profile
    
    var title: String{
        switch self {
        case .home:
            return "Home"
        case .favorite:
            return "Scan"
        case .chat:
            return "Search"
        case .profile:
            return "Profile"
        }
    }
    
    var iconName: String{
        switch self {
        case .home:
            return "house"
        case .favorite:
            return "barcode.viewfinder"
        case .chat:
            return "magnifyingglass"
        case .profile:
            return "person"
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @AppStorage("tab") var selectedTab: Int = 0
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tag(0)
                .onAppear {
                    fetchUserData()
                }
            
            ScanView()
                .tag(1)
                .onAppear {
                    fetchUserData()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            SearchView()
                .tag(2)
                .onAppear {
                    fetchUserData()
                }
            
            ProfileView()
                .tag(3)
                .onAppear {
                    fetchUserData()
                }
        }
        .accentColor(.black)
        .edgesIgnoringSafeArea(.all)
        
        // MARK: UI
        HStack {
            ForEach(TabItems.allCases, id: \.self) { item in
                Button {
                    selectedTab = item.rawValue
                } label: {
                    CustomTabItem(imageName: item.iconName, title: item.title, isActive: (selectedTab == item.rawValue))
                }
            }
        }
        .padding(6)
        .frame(height: 70)
        .background(.green.opacity(0.2))
        .cornerRadius(35)
        .padding(.horizontal, 26)
    }
    
    // MARK: Helper Functions
    
    private func fetchUserData() {
        Task {
            if let uid = authManager.currentUser?.id {
                await authManager.fetchUserData(for: uid)
            }
        }
    }
}

// MARK: TabView Extension
extension MainTabView{
    func CustomTabItem(imageName: String, title: String, isActive: Bool) -> some View{
        HStack(spacing: 10){
            Spacer()
            Image(systemName: imageName)
                .resizable()
                .renderingMode(.template)
                .foregroundColor(isActive ? .black : .gray)
                .frame(width: 20, height: 20)
            if isActive{
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(isActive ? .black : .gray)
            }
            Spacer()
        }
        .frame(width: isActive ? .infinity : 60, height: 60)
        .background(isActive ? .green.opacity(0.4) : .clear)
        .cornerRadius(30)
    }
}
