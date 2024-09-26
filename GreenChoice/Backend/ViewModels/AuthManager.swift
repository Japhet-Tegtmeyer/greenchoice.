//
//  AuthManager.swift
//  GreenChoice
//
//  Created by Japhet Tegtmeyer on 9/21/24.
//

import AuthenticationServices
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage

enum AuthState {
    case authenticated // Anonymously authenticated in Firebase.
    case signedIn // Authenticated in Firebase using one of service providers, and not anonymous.
    case signedOut // Not authenticated in Firebase.
}

@MainActor
class AuthManager: ObservableObject {
    @Published var currentUser: User?
    @Published var authState = AuthState.signedOut
    
    private var authStateHandle: AuthStateDidChangeListenerHandle!
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    init() {
        configureAuthStateChanges()
    }

    // MARK: Config Auth State Changes
    func configureAuthStateChanges() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            print("Auth changed: \(firebaseUser != nil)")
            self?.updateState(firebaseUser: firebaseUser)
        }
    }

    // MARK: Remove Listener
    func removeAuthStateListener() {
        Auth.auth().removeStateDidChangeListener(authStateHandle)
    }

    // MARK: Update State
    func updateState(firebaseUser: FirebaseAuth.User?) {
        let isAuthenticatedUser = firebaseUser != nil
        let isAnonymous = firebaseUser?.isAnonymous ?? false

        if isAuthenticatedUser {
            self.authState = isAnonymous ? .authenticated : .signedIn
            Task {
                await fetchUserData(for: firebaseUser!.uid)
            }
        } else {
            self.authState = .signedOut
            self.currentUser = nil
        }
    }
    
    // MARK: Fetch User Data
    func fetchUserData(for uid: String) async {
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            if let user = try? document.data(as: User.self) {
                self.currentUser = user
            }
        } catch {
            print("FirestoreError: Failed to fetch user data. \(error)")
        }
    }
    
    // MARK: Sign Out
    func signOut() async throws {
        if Auth.auth().currentUser != nil {
            do {
                try Auth.auth().signOut()
            } catch let error as NSError {
                print("FirebaseAuthError: failed to sign out from Firebase, \(error)")
                throw error
            }
        }
    }
    
    // MARK: Authenticate User
    private func authenticateUser(credentials: AuthCredential) async throws -> AuthDataResult? {
        if Auth.auth().currentUser != nil {
            return try await authLink(credentials: credentials)
        } else {
            return try await authSignIn(credentials: credentials)
        }
    }

    // MARK: Auth Sign In
    private func authSignIn(credentials: AuthCredential) async throws -> AuthDataResult? {
        do {
            let result = try await Auth.auth().signIn(with: credentials)
            await updateDisplayName(for: result.user)
            return result
        } catch {
            print("FirebaseAuthError: signIn(with:) failed. \(error)")
            throw error
        }
    }
    
    // MARK: Auth Link
    private func authLink(credentials: AuthCredential) async throws -> AuthDataResult? {
        do {
            guard let user = Auth.auth().currentUser else { return nil }
            let result = try await user.link(with: credentials)
            await updateDisplayName(for: result.user)
            return result
        } catch {
            print("FirebaseAuthError: link(with:) failed, \(error)")
            throw error
        }
    }
    
    // MARK: Update Display Name
    private func updateDisplayName(for firebaseUser: FirebaseAuth.User) async {
        if let currentDisplayName = firebaseUser.displayName, !currentDisplayName.isEmpty {
            // Display name is already set, no need to update
        } else {
            let displayName = firebaseUser.providerData.first?.displayName
            let changeRequest = firebaseUser.createProfileChangeRequest()
            changeRequest.displayName = displayName
            do {
                try await changeRequest.commitChanges()
                // Update the display name in Firestore as well
                try await db.collection("users").document(firebaseUser.uid).updateData([
                    "displayName": displayName ?? ""
                ])
            } catch {
                print("FirebaseAuthError: Failed to update the user's displayName. \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: Apple Auth
    func appleAuth(
        _ appleIDCredential: ASAuthorizationAppleIDCredential,
        nonce: String?
    ) async throws -> AuthDataResult? {
        guard let nonce = nonce else {
            fatalError("Invalid state: A login callback was received, but no login request was sent.")
        }
        
        guard let appleIDToken = appleIDCredential.identityToken else {
            print("Unable to fetch identity token")
            return nil
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
            return nil
        }
        
        let credentials = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                        rawNonce: nonce,
                                                        fullName: appleIDCredential.fullName)
        
        do {
            let authResult = try await Auth.auth().signIn(with: credentials)
            
            // Check if the user already exists in Firestore
            let userDoc = try await db.collection("users").document(authResult.user.uid).getDocument()
            
            if !userDoc.exists {
                // If the user doesn't exist, create a new user document
                let newUser = User(
                    id: authResult.user.uid,
                    email: authResult.user.email ?? "",
                    displayName: authResult.user.displayName ?? appleIDCredential.fullName?.givenName ?? "Apple User",
                    createdAt: Date.now,
                    lastLoginAt: Date(),
                    scannedProducts: [],
                    favoriteProducts: [],
                    preferences: UserPreferences(
                        hapticsEnabled: true,
                        bannerColor: "#76F387"
                    ),
                    isPremium: false,
                    isAnonymous: false
                )
                
                try await db.collection("users").document(authResult.user.uid).setData(from: newUser)
                self.currentUser = newUser
            } else {
                // If the user exists, update the last login time
                try await db.collection("users").document(authResult.user.uid).updateData([
                    "lastLoginAt": Date()
                ])
                await fetchUserData(for: authResult.user.uid)
            }
            
            updateState(firebaseUser: authResult.user)
            return authResult
        } catch {
            print("FirebaseAuthError: appleAuth(appleIDCredential:nonce:) failed. \(error)")
            throw error
        }
    }
    
    // MARK: Verify Sign In With Apple
    func verifySignInWithAppleID() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        guard let firebaseUser = Auth.auth().currentUser else { return }
        let providerData = firebaseUser.providerData
        if let appleProviderData = providerData.first(where: { $0.providerID == "apple.com" }) {
            Task {
                let credentialState = try await appleIDProvider.credentialState(forUserID: appleProviderData.uid)
                switch credentialState {
                case .authorized:
                    break // The Apple ID credential is valid.
                case .revoked, .notFound:
                    // The Apple ID credential is either revoked or was not found, so show the sign-in UI.
                    do {
                        try await self.signOut()
                    } catch {
                        print("FirebaseAuthError: signOut() failed. \(error)")
                    }
                default:
                    break
                }
            }
        }
    }
    
    func uploadProfilePicture(_ image: UIImage) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "AuthManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not convert image to data"])
        }
        
        let storageRef = storage.reference().child("profile_pictures/\(userId).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        let userRef = db.collection("users").document(userId)
        try await userRef.updateData([
            "profileImageURL": downloadURL.absoluteString
        ])
        
        // Update the local user object
        currentUser?.profileImageURL = downloadURL.absoluteString
        
        // Fetch updated user data
        await fetchUserData(for: userId)
    }
    
    func fetchRecentlyScannedItems(for userId: String, limit: Int) async throws -> [Item] {
        var recentlyScannedItems: [Item] = []

        do {
            let userRef = db.collection("users").document(userId)
            let userDoc = try await userRef.getDocument(as: User.self)

            if let scannedItemIds = userDoc.scannedProducts as? [String] {
                let itemsRef = db.collection("items")
                for itemId in scannedItemIds.prefix(limit) {
                    let itemDoc = try await itemsRef.document(itemId).getDocument()
                    if let item = try? itemDoc.data(as: Item.self) {
                        recentlyScannedItems.append(item)
                    } else {
                        print("FirestoreError: Failed to decode item from document: \(itemId)")
                    }
                }
            } else {
                print("FirestoreError: Failed to get scanned item IDs from user document.")
            }
        } catch {
            print("FirestoreError: Failed to fetch recently scanned items. \(error)")
            throw error
        }

        return recentlyScannedItems
    }
}
