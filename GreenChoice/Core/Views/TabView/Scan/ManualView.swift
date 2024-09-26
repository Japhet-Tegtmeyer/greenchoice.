//
//  ManualView.swift
//  GreenChoice
//
//  Created by Japhet Tegtmeyer on 9/22/24.
//

import SwiftUI
import FirebaseFirestore

struct ManualView: View {
    @State private var code = ""
    @State private var showItemView = false
    @State private var showEnterDetailsView = false
    @State private var scannedItem: Item?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationStack {
            VStack {
                VStack(alignment: .leading) {
                    TextField("Enter Code", text: $code)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                        .keyboardType(.decimalPad)
                    
                    Text("Enter the code found on the barcode.")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                
                NavigationLink {
                    ScanInfoView()
                } label: {
                    Text("Need Help?")
                        .underline()
                        .foregroundStyle(.black)
                        .bold()
                        .font(.subheadline)
                }
            }
//            .navigationTitle("Enter the code")
            .navigationBarTitleDisplayMode(.inline)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    searchDatabase()
                } label: {
                    Text("Done")
                        .font(.subheadline)
                        .bold()
                        .tint(.black)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(5)
                }.disabled(code.isEmpty)
            }
        }
        .fullScreenCover(isPresented: $showItemView) {
            if let item = scannedItem {
                ItemView(item: item)
            }
        }
        .sheet(isPresented: $showEnterDetailsView) {
            EnterDetailsView(barcodeId: code) { newItem in
                saveItemToDatabase(newItem)
                addItemToUserScannedItems(newItem.id ?? "")
                scannedItem = newItem
                showItemView = true
            }
        }
    }
    
    private func searchDatabase() {
        let db = Firestore.firestore()
        db.collection("items").whereField("barcodeId", isEqualTo: code).getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                return
            }
            
            if let document = querySnapshot?.documents.first {
                scannedItem = try? document.data(as: Item.self)
                if let itemId = scannedItem?.id {
                    addItemToUserScannedItems(itemId)
                }
                showItemView = true
            } else {
                showEnterDetailsView = true
            }
            
            dismiss()
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
