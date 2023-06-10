//  buskalo


import UIKit
import AVFoundation
import CoreImage
import FirebaseFirestore
import FirebaseStorage

class ClientsProductsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,UISearchBarDelegate,AVCaptureMetadataOutputObjectsDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    

    @IBOutlet weak var clientProductTableView: UITableView!
    @IBOutlet weak var buscarProductos: UISearchBar!
    
    var alertShown = false

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    var products: [Product] = []

    // Search QR
    var captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer!
    var qrCodeFrameView: UIView?
    var scannedImage: UIImage? {
        didSet {
            processImage()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        clientProductTableView.dataSource = self
        clientProductTableView.delegate = self
        buscarProductos.delegate = self
        
        // Search QR
        initializeCaptureSession()
 
        // List products
        DispatchQueue.main.async {
        self.listProducts()
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "clientProductCell", for: indexPath) as! ClientsProductsTableViewCell
        let product = products[indexPath.row]
        cell.nomprod.attributedText = getAttributedBoldString(str: String(format: "%@ %@","Producto: ", product.getNomProd()),boldTxt : "Producto: ")
        cell.descprod.attributedText = getAttributedBoldString(str: String(format: "%@ %@","Descrip.: ", product.getDescProd()),boldTxt : "Descrip.: ")
        cell.precprod.attributedText = getAttributedBoldString(str: String(format: "%@ %.2f", "Precio: S/ ", product.getPrecProd()),boldTxt : "Precio: S/ ")
        let attributedString = NSAttributedString(string: "Ir al enlace", attributes: [.link: URL(string: product.getURLProd())!])
        cell.urlprod.attributedText = attributedString
        cell.urlprod.isSelectable = true
        cell.urlprod.isEditable = false
        
        cell.imgprod.image = product.image
        
        return cell
    }
    
    
    // Funcion para poner en negrita un texto
    func getAttributedBoldString(str : String, boldTxt : String) -> NSMutableAttributedString {
        let attrStr = NSMutableAttributedString.init(string: str)
        let boldedRange = NSRange(str.range(of: boldTxt)!, in: str)
        attrStr.addAttributes([NSAttributedString.Key.font : UIFont.systemFont(ofSize: 10, weight: .bold)], range: boldedRange)
        return attrStr
    }
    

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            // Mostrar todos los prod si no hay texto ingresado en el searchBar
            listProducts()
        } else {
            searchProducts(for: searchText, in: products)
        }
    
        clientProductTableView.reloadData()
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
                        self.clientProductTableView.reloadData()
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

    func searchProducts(for query: String, in products: [Product]) {
        let filteredProducts = products.filter { $0.nomprod.lowercased().range(of: query.lowercased(), options: .diacriticInsensitive) != nil }
        self.products = products.isEmpty ? products : filteredProducts
        if self.products.isEmpty {
            let alert = UIAlertController(title: "No se encontraron resultados", message: "Intenta con otra palabra clave", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
        clientProductTableView.reloadData()
    }
    
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
        listProducts()
    }
  
    
    
        // Seccion de busqueda productos por QR //
    
        // La función inicializa la sesión de captura de video utilizando la clase AVCaptureSession
        private func initializeCaptureSession() {
            guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else { return }
    
                do {
                    let input = try AVCaptureDeviceInput(device: captureDevice)
                    captureSession.addInput(input)
    
                    let captureMetadataOutput = AVCaptureMetadataOutput()
                    captureSession.addOutput(captureMetadataOutput)
                    captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                    captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
    
                } catch {
                    print(error)
                    return
                }
    
                captureSession.startRunning()
            }
    
    
        // Se activa con los datos que envia la funcion initializeCaptureSession() y recibe un array de objetos de metadatos y una conexión de captura de video.
            func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
                guard let metadataObj = metadataObjects.first as? AVMetadataMachineReadableCodeObject else { return }
    
                if metadataObj.type == AVMetadataObject.ObjectType.qr {
                    let barCodeObject = previewLayer.transformedMetadataObject(for: metadataObj)
    
                    qrCodeFrameView?.frame = barCodeObject!.bounds
    
                    if let qrCodeContent = metadataObj.stringValue {
                   }
                }
            }
        
        // Este método procesa la imagen escaneada en busca de códigos QR y realiza una acción en función del contenido del código QR.
        // Utiliza la biblioteca CoreImage para realizar el procesamiento de la imagen.
        func processImage() {
             guard let image = scannedImage else { return }
    
             let context = CIContext(options: nil)
             let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
    
             if let ciImage = CIImage(image: image), let features = detector?.features(in: ciImage) {
                 for feature in features as! [CIQRCodeFeature] {
                     if let urlString = feature.messageString {
                        // Pasa el url obtenido - urlString
                         searchProductsQR(for: urlString, in: products)
                         
                        // Actualizar la tabla
                         clientProductTableView.reloadData()
                     }
                 }
             }
         }
    
        // Ejecuta la busqueda con el URL obtenitdo de la imagen QR
        func searchProductsQR(for query: String, in products: [Product]) {
              let filteredProducts = products.filter { $0.urlprod.lowercased().range(of: query.lowercased(), options: .diacriticInsensitive) != nil }
              self.products = products.isEmpty ? products : filteredProducts
              if self.products.isEmpty {
                  let alert = UIAlertController(title: "No se encontraron resultados", message: "Intenta con otra palabra clave", preferredStyle: .alert)
                  alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                  present(alert, animated: true, completion: nil)
              }
              clientProductTableView.reloadData()
          }
        
        
        

    @IBAction func scanProduct(_ sender: Any) {
              let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .photoLibrary
            present(picker, animated: true, completion: nil)
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
            scannedImage = image

            dismiss(animated: true, completion: nil)
        
    }
}
    
    


