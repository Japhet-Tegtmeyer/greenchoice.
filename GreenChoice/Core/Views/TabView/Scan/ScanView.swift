//
//  ScanView.swift
//  GreenChoice
//
//  Created by Japhet Tegtmeyer on 9/21/24.
//

import SwiftUI
import CodeScanner
import Firebase
import FirebaseFirestore

enum FoundState {
    case notFound
    case found
    case null
}

struct ScanView: View {
    @State private var scannedCode: String?
    @State private var foundStatus: FoundState = .null
    @State private var showItemView = false
    @State private var showEnterDetailsView = false
    @State private var enterManually = false
    @State private var scannedItem: Item?
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // MARK: Scanner
                CodeScannerView(codeTypes: [.ean8, .ean13, .code39, .code128, .upce], simulatedData: "NO VALID CODE SCANNED") { response in
                    if case let .success(result) = response {
                        scannedCode = result.string
                        checkItemInDatabase()
                    }
                }
                .edgesIgnoringSafeArea(.all)
                
                // MARK: Mask
                Image("camerapreview_mask")
                    .resizable()
                    .frame(width: UIScreen.screenWidth, height: UIScreen.screenHeight)
                    .offset(y: -50)
                    .ignoresSafeArea()
                
                VStack {
                    Text("Place barcode into the square")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.top, 100)
                    
                    HStack {
                        Text("Not working?")
                        
                        Button {
                            enterManually = true
                        } label: {
                            Text("Enter manually")
                                .underline()
                                .bold()
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                                        
                    Spacer()
                }
            }
            .sheet(isPresented: $showItemView) {
                if let item = scannedItem {
                    ItemView(item: item)
                }
            }
            .sheet(isPresented: $showEnterDetailsView) {
                EnterDetailsView(barcodeId: scannedCode ?? "") { newItem in
                    saveItemToDatabase(newItem)
                    addItemToUserScannedItems(newItem.id ?? "")
                }
            }
            .sheet(isPresented: $enterManually) {
                ManualView()
                    .environmentObject(authManager)
                    .presentationDetents([.height(170)]) // Keep the original height
            }
        }
    }
    
    // MARK: Helper Functions
    
    private func checkItemInDatabase() {
        guard let code = scannedCode else { return }
        
        let db = Firestore.firestore()
        db.collection("items").whereField("barcodeId", isEqualTo: code).getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                return
            }
            
            if let document = querySnapshot?.documents.first {
                let item = try? document.data(as: Item.self)
                scannedItem = item
                foundStatus = .found
                showItemView = true
                if let itemId = item?.id {
                    addItemToUserScannedItems(itemId)
                }
            } else {
                foundStatus = .notFound
                showEnterDetailsView = true
            }
        }
    }
    
    private func saveItemToDatabase(_ item: Item) {
        let db = Firestore.firestore()
        do {
            _ = try db.collection("items").addDocument(from: item)
        } catch let error {
            print("Error writing item to Firestore: \(error)")
        }
    }
    
    private func addItemToUserScannedItems(_ itemId: String) {
        guard let userId = authManager.currentUser?.id else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "scannedProducts": FieldValue.arrayUnion([itemId])
        ]) { err in
            if let err = err {
                print("Error updating user's scanned items: \(err)")
            }
        }
    }
}

#Preview {
    ScanView()
        .environmentObject(AuthManager())
}
