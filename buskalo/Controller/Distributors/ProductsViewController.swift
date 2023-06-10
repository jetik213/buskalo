//
//  ProductsViewController.swift
//  buskalo


import UIKit
import FirebaseFirestore
import FirebaseStorage

class ProductsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,UISearchBarDelegate  {

   
    @IBOutlet weak var buscarProductosSearchBar: UISearchBar!
    @IBOutlet weak var productsTableView: UITableView!
    var alertShown = false

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    var products: [Product] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        productsTableView.dataSource = self
        productsTableView.delegate = self
        buscarProductosSearchBar.delegate = self
        productsTableView.reloadData()
        listProducts()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "productCell", for: indexPath) as! ProductsTableViewCell
        let product = products[indexPath.row]
        cell.nomprodLabel.attributedText = getAttributedBoldString(str: String(format: "%@ %@","Producto: ", product.getNomProd()),boldTxt : "Producto: ")
        cell.descprodtextView.attributedText = getAttributedBoldString(str: String(format: "%@ %@","Descrip.: ", product.getDescProd()),boldTxt : "Descrip.: ")
        cell.precprodLabel.attributedText = getAttributedBoldString(str: String(format: "%@ %.2f", "Precio: S/ ", product.getPrecProd()),boldTxt : "Precio: S/ ")
        let attributedString = NSAttributedString(string: "Ir al enlace", attributes: [.link: URL(string: product.getURLProd())!])
        cell.urlprodTextView.attributedText = attributedString
        cell.urlprodTextView.isSelectable = true
        cell.urlprodTextView.isEditable = false
        
        cell.imgLabel.image = product.image
        
        return cell
    }
    
    
    // Funcion para poner en negrita un texto
    func getAttributedBoldString(str : String, boldTxt : String) -> NSMutableAttributedString {
        let attrStr = NSMutableAttributedString.init(string: str)
        let boldedRange = NSRange(str.range(of: boldTxt)!, in: str)
        attrStr.addAttributes([NSAttributedString.Key.font : UIFont.systemFont(ofSize: 10, weight: .bold)], range: boldedRange)
        return attrStr
    }
    
    // Eliminar y Editar
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
         let deleteAction = UIContextualAction(style: .destructive, title: "Eliminar") { [weak self] (_, _, completion) in
             guard let self = self else { return }
             
             // Obtener el producto seleccionado
             let product = self.products[indexPath.row]
             
             // Eliminar el producto de Firebase
             self.deleteProduct(product)
             
             // Completar la acción de eliminación
             completion(true)
     }
     
       let editAction = UIContextualAction(style: .normal, title: "Editar") { [weak self] (_, _, completion) in
                guard let self = self else { return }

                // Obtener el producto seleccionado
                let product = self.products[indexPath.row]

                // Crear una instancia de la vista de edición
                let storyboard = UIStoryboard(name: "Distributors", bundle: nil)
                guard let editProductVC = storyboard.instantiateViewController(withIdentifier: "EditProductViewController") as? EditProductViewController else { return }

                // Pasar los datos necesarios a la vista de edición
                editProductVC.product = product
                editProductVC.db = self.db

                // Activar el segue
                self.navigationController?.pushViewController(editProductVC, animated: true)

                // Completar la acción de edición
                self.productsTableView.reloadData()
                completion(true)
            }

             // Establecer el color de fondo de las acciones
             deleteAction.backgroundColor = .red
             editAction.backgroundColor = .blue

             // Crear la configuración de acciones
             let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
             return configuration
     }
     
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            // Mostrar todos los prod si no hay texto ingresado en el searchBar
            listProducts()
        } else {
            searchProducts(for: searchText, in: products)
        }
    
        productsTableView.reloadData()
    }
    

    func listProducts() {
         var count = 0
        db.collection("products").getDocuments { snapshot, error in
            if let error = error {
                print("Error al cargar productos desde la db de firestore: \(error.localizedDescription)")
            } else {
                self.products = []
                for document in snapshot!.documents {
                    let data = document.data()
                    let nomprod = data["nomprod"] as! String
                    let descprod = data["descprod"] as! String
                    let precprod = data["precprod"] as! Double
                    let urlprod = data["urlprod"] as! String
                    //  Se descarga la imagen correspondiente a la URL indicada en el documento
                    self.downloadImage(url: urlprod) { image in
                    let product = Product(nomprod: nomprod, descprod: descprod, precprod: precprod, urlprod: urlprod)
                    product.image = image
                    product.documentID = document.documentID
                    self.products.append(product)
                      count += 1
                        if count == snapshot!.documents.count {
                        self.productsTableView.reloadData()
                        }
                    }
                }
            }
        }
    }

    func downloadImage(url: String, completion: @escaping (UIImage?) -> Void) {
        let storageRef = storage.reference(forURL: url)
        storageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let error = error {
                print("Error al descargar la imagen: \(error.localizedDescription)")
                completion(nil)
            } else {
                let image = UIImage(data: data!)
                completion(image)
            }
        }
    }
    
    
    func deleteProduct(_ product: Product) {
        guard let documentID = product.documentID else {
            print("Error al borrar el producto: documentID es nullo")
            return
        }
        let productRef = db.collection("products").document(documentID)
        productRef.delete() { error in
            if let error = error {
                print("Error al borrar el producto: \(error.localizedDescription)")
            } else {
                // Borrar imagen de  Firebase Storage
                let storageRef = self.storage.reference(forURL: product.getURLProd())
                storageRef.delete() { error in
                    if let error = error {
                        print("Error al borrar la imagen: \(error.localizedDescription)")
                    }
                }
                
                // Remover producto y actualizar la tabla
                self.products.removeAll(where: { $0.documentID == product.documentID })
                self.productsTableView.reloadData()
            }
        }
    }
    
    
    func searchProducts(for query: String, in products: [Product]) {
        let filteredProducts = products.filter { $0.nomprod.lowercased().range(of: query.lowercased(), options: .diacriticInsensitive) != nil }
        self.products = products.isEmpty ? products : filteredProducts
        if self.products.isEmpty {
            let alert = UIAlertController(title: "No se encontraron resultados", message: "Intenta con otra palabra clave", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
        productsTableView.reloadData()
    }
    
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
        listProducts()
    }
  
}
