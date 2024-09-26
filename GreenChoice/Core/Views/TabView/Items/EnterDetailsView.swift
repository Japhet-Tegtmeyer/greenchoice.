//
//  EnterDetailsView.swift
//  GreenChoice
//
//  Created by Japhet Tegtmeyer on 9/22/24.
//

import SwiftUI
import FirebaseStorage
import FirebaseFirestore

struct EnterDetailsView: View {
    var barcodeId: String
    var onSave: (Item) -> Void
    
    @State private var itemName = ""
    @State private var selectedManufacturer: Manufacturer?
    @State private var image: UIImage?
    @State private var showingImagePicker = false
    @State private var photoUrl: String?
    @State private var isUploading = false
    @State private var manufacturers: [Manufacturer] = []
    @State private var isLoadingManufacturers = true
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        if let image = image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 200, height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                        } else {
                            Image(systemName: "photo")
                                .font(.system(size: 50))
                                .frame(width: 200, height: 200)
                                .foregroundColor(Color(.darkGray))
                                .background(Color(.systemGray5))
                                .cornerRadius(15)
                        }
                    }
                    .padding()
                    
                    VStack(alignment: .leading) {
                        
                        // MARK: Barcode ID
                        Text("Barcode ID")
                            .font(.caption2)
                            .bold()
                            .padding(.leading)
                            .padding(.bottom, -4)
                        
                        HStack {
                            Text(barcodeId)
                                .foregroundColor(.gray)
                                .bold()
                            
                            Spacer()
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                        
                        HStack(alignment: .bottom) {
                            Text("This is the code we got from the barcode you scanned. If the code appears as blank please")
                                .frame(width: 280)
                            
                            Button {
                                dismiss()
                            } label: {
                                Text("scan again.")
                                    .underline()
                                    .padding(.leading, -27)
                                    .foregroundColor(.black)
                            }
                        }
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                        .padding(.bottom, 8)
                        .padding(.leading, 4)
                        .padding(.top, -2)
                        
                        // MARK: Item Name
                        Text("Item Name")
                            .font(.caption2)
                            .bold()
                            .padding(.horizontal)
                            .padding(.bottom, -4)
                        
                        TextField("", text: $itemName)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        
                        Text("Please enter the name of the product you scanned.")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.leading)
                            .frame(width: 280)
                            .padding(.bottom, 8)
                            .padding(.leading)
                            .padding(.top, -2)
                        
                        // MARK: Manufacturer
                        Text("Manufacturer")
                            .font(.caption2)
                            .bold()
                            .padding(.leading)
                            .padding(.bottom, -4)
                        
                        if isLoadingManufacturers {
                            ProgressView()
                                .padding()
                        } else {
                            Picker("Select Manufacturer", selection: $selectedManufacturer) {
                                Text("Select a manufacturer").tag(nil as Manufacturer?)
                                ForEach(manufacturers, id: \.id) { manufacturer in
                                    Text(manufacturer.name).tag(manufacturer as Manufacturer?)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                        
                        
                        Spacer()
                    }
                }
                .navigationTitle("Enter Item Details")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(trailing: Button {
                    if let image = image {
                        isUploading = true
                        uploadPhoto(image) { url in
                            if let selectedManufacturer = selectedManufacturer {
                                let newItem = Item(barcodeId: barcodeId,
                                                   itemName: itemName,
                                                   manufacturer: selectedManufacturer.id ?? "",
                                                   photoUrl: url)
                                onSave(newItem)
                                presentationMode.wrappedValue.dismiss()
                            } else {
                                // Handle the case where no manufacturer is selected
                                print("Error: No manufacturer selected")
                            }
                        }
                    } else {
                        if let selectedManufacturer = selectedManufacturer {
                            let newItem = Item(barcodeId: barcodeId,
                                               itemName: itemName,
                                               manufacturer: selectedManufacturer.id ?? "",
                                               photoUrl: nil)
                            onSave(newItem)
                            presentationMode.wrappedValue.dismiss()
                        } else {
                            // Handle the case where no manufacturer is selected
                            print("Error: No manufacturer selected")
                        }
                    }
                } label: {
                    if isUploading {
                        ProgressView()
                    } else {
                        Text("Done")
                            .font(.subheadline)
                            .bold()
                            .tint(.black)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(5)
                    }
                }.disabled(barcodeId.isEmpty || itemName.isEmpty || selectedManufacturer == nil || isUploading))
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            TakePhoto(image: $image)
                .ignoresSafeArea()
        }
        .onAppear {
            fetchManufacturers()
        }
    }
    
    // MARK: Helper Func
    
    func uploadPhoto(_ image: UIImage, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            completion(nil)
            return
        }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imageName = UUID().uuidString
        let imageRef = storageRef.child("product_images/\(imageName).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        imageRef.putData(imageData, metadata: metadata) { (metadata, error) in
            if let error = error {
                print("Error uploading image: \(error)")
                completion(nil)
            } else {
                imageRef.downloadURL { (url, error) in
                    if let downloadURL = url?.absoluteString {
                        completion(downloadURL)
                    } else {
                        completion(nil)
                    }
                }
            }
        }
    }
    
    func fetchManufacturers() {
        let db = Firestore.firestore()
        db.collection("manufacturers").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                self.manufacturers = querySnapshot?.documents.compactMap { document -> Manufacturer? in
                    try? document.data(as: Manufacturer.self)
                } ?? []
                self.isLoadingManufacturers = false
            }
        }
    }
}

// MARK: Take Photo
struct TakePhoto: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) private var presentationMode

    func makeUIViewController(context: UIViewControllerRepresentableContext<TakePhoto>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<TakePhoto>) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: TakePhoto

        init(_ parent: TakePhoto) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
