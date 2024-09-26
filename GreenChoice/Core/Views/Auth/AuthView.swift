//
//  AuthView.swift
//  GreenChoice
//
//  Created by Japhet Tegtmeyer on 9/21/24.
//

import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
//    @State private var showEmailSignUp = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Rectangle()
                    .foregroundColor(Color(hex: "#76F387").opacity(0.5))
                    .offset(y: -420)
                
                VStack {
                    Text("Welcome to")
                        .font(.system(size: 16, weight: .medium))
                        .padding(.top, 245)
                    
                    Text("GreenChoice.")
                        .font(.system(size: 48, weight: .heavy))
                    
                    VStack(spacing: 23) {
                        Text("Please sign in to continue")
                            .font(.system(size: 13, weight: .medium))
                        
                        // MARK: Apple Button
                        SignInWithAppleButton(.continue) { request in
                            AppleSignInManager.shared.requestAppleAuthorization(request)
                        } onCompletion: { result in
                            handleAppleID(result)
                        }
                        .frame(width: 275, height: 44)
                        .cornerRadius(15)
                        
                        Text("Thank you for downloading!")
                            .font(.system(size: 12, weight: .medium))
                            .frame(width: 280, height: 45, alignment: .center)
                        
                        Spacer()
                        
                        Text("By signing in you agree to our Privacy Policy and Terms of Service")
                            .font(.system(size: 10, weight: .light))
                            .frame(width: 200)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                }
            }
        }
    }
    
    // MARK: Helper Functions
    
    func handleAppleID(_ result: Result<ASAuthorization, Error>) {
        if case let .success(auth) = result {
            guard let appleIDCredentials = auth.credential as? ASAuthorizationAppleIDCredential else {
                print("AppleAuthorization failed: AppleID credential not available")
                return
            }
            
            Task {
                do {
                    let result = try await authManager.appleAuth(
                        appleIDCredentials,
                        nonce: AppleSignInManager.nonce
                    )
                    if let result = result {
                        dismiss()
                    }
                } catch {
                    print("AppleAuthorization failed: \(error)")
                }
            }
        }
        else if case let .failure(error) = result {
            print("AppleAuthorization failed: \(error)")
        }
    }
    
}

#Preview {
    AuthView()
}
