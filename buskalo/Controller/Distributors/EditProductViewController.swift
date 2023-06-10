//
//  EditProductViewController.swift
//  buskalo


import UIKit
import FirebaseFirestore

class EditProductViewController: UIViewController {

    @IBOutlet weak var nomprodTextField: UITextField!
    @IBOutlet weak var precprodTextField: UITextField!
    @IBOutlet weak var descprodTextView: UITextView!
 
    
        var db = Firestore.firestore()
    
        var product: Product!
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            nomprodTextField.text = product.nomprod
            descprodTextView.text = product.descprod
            precprodTextField.text = String(format: "%.2f", product.precprod)
        }
        

            
    @IBAction func updateProduct(_ sender: Any) {
            guard let nomprod = nomprodTextField.text, !nomprod.isEmpty,
                  let descprod = descprodTextView.text, !descprod.isEmpty,
                  let precprodString = precprodTextField.text,
                  let precprod = Double(precprodString)
            else {
                // Validar que los campos no estén vacíos y que el campo precprod sea un número válido
                return
            }
            
            let editdProduct = Product(nomprod: nomprod, descprod: descprod, precprod: precprod, urlprod: product.urlprod)
            editdProduct.documentID = product.documentID
            
            editProduct(editdProduct) { success in
                if success {
                    // Si se editó el producto con éxito, volver a la pantalla anterior
            
                    let alertController = UIAlertController(title: "Producto editado", message: "El producto ha sido editado exitosamente", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
                    self.navigationController?.popViewController(animated: true)
                    }
                    alertController.addAction(okAction)

                    self.present(alertController, animated: true, completion: nil)
                } else {
                    // Mostrar un mensaje de error si no se pudo editar el producto
                    let alert = UIAlertController(title: "Error", message: "No se pudo editar el producto", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    
    func editProduct(_ product: Product, completion: @escaping (Bool) -> Void) {
        guard let documentID = product.documentID else {
            completion(false)
            return
        }
        let productRef = db.collection("products").document(documentID)
        productRef.updateData([
            "nomprod": product.nomprod,
            "descprod": product.descprod,
            "precprod": product.precprod
        ]) { error in
            if let error = error {
                print("Error al actualizar el producto: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Producto actualizado correctamente")
                completion(true)
            }
        }
    }
}
