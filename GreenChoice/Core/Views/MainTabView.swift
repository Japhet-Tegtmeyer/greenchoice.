//
//  HomeView.swift
//  GreenChoice
//
//  Created by Japhet Tegtmeyer on 9/21/24.
//

import SwiftUI

// MARK: - Tab Model
enum Tab: String, CaseIterable {
    case home, scan, search, profile
    
    var title: String {
        rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .home: return "house"
        case .scan: return "barcode.viewfinder"
        case .search: return "magnifyingglass"
        case .profile: return "person"
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(Tab.home.title, systemImage: Tab.home.icon)
                }
                .tag(Tab.home)
            
            ScanView()
                .tabItem {
                    Label(Tab.scan.title, systemImage: Tab.scan.icon)
                }
                .tag(Tab.scan)
            
            SearchView()
                .tabItem {
                    Label(Tab.search.title, systemImage: Tab.search.icon)
                }
                .tag(Tab.search)
            
            ProfileView()
                .tabItem {
                    Label(Tab.profile.title, systemImage: Tab.profile.icon)
                }
                .tag(Tab.profile)
        }
        .accentColor(Color(hex: "#76F387"))
    }
}
#Preview {
    MainTabView()
}
