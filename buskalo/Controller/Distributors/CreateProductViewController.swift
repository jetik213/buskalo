//
//  CreateProductViewController.swift
//  buskalo
//
//  Created by crizcode on 2/10/23.
//  Copyright © 2023 crizcode. All rights reserved.
//

import UIKit
import FirebaseFirestore
import Firebase
import FirebaseStorage


class CreateProductViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {


        // Outlets
    
    @IBOutlet weak var nomprodTextField: UITextField!
    @IBOutlet weak var descprodTextView: UITextView!
    @IBOutlet weak var precprodTextField: UITextField!
    @IBOutlet weak var imgprod: UIButton!
    

    private let db = Firestore.firestore()
    
    private let storage = Storage.storage()

      override func viewDidLoad() {
        super.viewDidLoad()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectImage))
        imgprod.isUserInteractionEnabled = true
        imgprod.addGestureRecognizer(tapGesture)
    }

    @IBAction func addProduct(_ sender: Any) {
  
     guard let productName = nomprodTextField.text,
                  let productDescription = descprodTextView.text,
                  let productPriceText = precprodTextField.text,
                  let productPrice = Double(productPriceText),
                  let productImage = imgprod.image(for: .normal) else {
                return
            }

            let storageRef = storage.reference().child("images") // <--- Ruta de img en Fire Storage
            let imageRef = storageRef.child(UUID().uuidString)

            guard let imageData = productImage.jpegData(compressionQuality: 0.5) else {
                print("Error al convertir la imagen en Data")
                return
            }

            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"

            let uploadTask = imageRef.putData(imageData, metadata: metadata)

            uploadTask.observe(.success) { snapshot in
                imageRef.downloadURL { (url, error) in
                    guard let imageUrl = url?.absoluteString else {
                        print("Error al obtener URL de descarga de imagen: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
            let product = Product(nomprod: productName, descprod: productDescription, precprod: productPrice, urlprod: imageUrl)

               // Obtiene una referencia a la colección "products" de Firebase Firestore
                let collectionRef = self.db.collection("products")

                // Genera un nuevo ID utilizando la función doc()
                let newDocRef = collectionRef.document()

                // Utiliza el ID generado para crear un nuevo documento en la colección
                newDocRef.setData([
                    "nomprod": product.getNomProd(),
                    "descprod": product.getDescProd(),
                    "precprod": product.getPrecProd(),
                    "urlprod": product.getURLProd()
                ]) { error in
                    if let error = error {
                        print("Error creating product: \(error.localizedDescription)")
                    } else {
                        // Producto creado
                        let alertController = UIAlertController(title: "Producto creado", message: "El producto ha sido creado exitosamente", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
                            self.navigationController?.popViewController(animated: true)
                        }
                        alertController.addAction(okAction)

                        self.present(alertController, animated: true, completion: nil)
                    }
                }
            }
        }
            uploadTask.observe(.failure) { snapshot in
                print("Error al subir imagen a Firebase Storage: \(snapshot.error?.localizedDescription ?? "Unknown error")")
            }
    }
    
    @IBAction func selectImage(_ sender: Any) {
 
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        imagePickerController.sourceType = .photoLibrary
        present(imagePickerController, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else {
            print("Error al obtener la imagen seleccionada")
            return
        }
        imgprod.setImage(image, for: .normal)
        dismiss(animated: true)
    }
}
