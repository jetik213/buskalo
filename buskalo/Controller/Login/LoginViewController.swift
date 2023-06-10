//
//  LoginViewController.swift
//  buskalo
//
//  Created by crizcode on 2/3/23.
//  Copyright © 2023 crizcode. All rights reserved.
//
import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

class LoginViewController: UIViewController {
    
    private var isPasswordVisible = false
    private let db = Firestore.firestore()
    
    // Outlets
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var eyeButton: UIButton!
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    
    @IBAction func eyeButtonTapped(_ sender: Any) {
        isPasswordVisible = !isPasswordVisible
        passwordTextField.isSecureTextEntry = !isPasswordVisible
        
        let imageName = isPasswordVisible ? "eye.fill" : "eye.slash.fill"
        eyeButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        guard let email = emailTextField.text, let password = passwordTextField.text else { return }
            
            // Validar el formato del correo electrónico
            if !isValidEmail(email) {
                showErrorMessage("Por favor, ingrese un correo electrónico válido.")
                return
            }
            
            // Validar la longitud de la contraseña
            if password.count < 6 {
                showErrorMessage("La contraseña debe tener al menos 6 caracteres.")
                return
            }

            // Mostrar un indicador de actividad mientras se realiza la autenticación
            let activityIndicator = UIActivityIndicatorView(style: .gray)
            view.addSubview(activityIndicator)
            activityIndicator.center = view.center
            activityIndicator.startAnimating()
            
           let userRef = db.collection("users").whereField("email", isEqualTo: email)

           userRef.getDocuments { (snapshot, error) in
               if let error = error {
                   // Handle error
                   self.showErrorMessage(error.localizedDescription)
                   return
               } else {
                   guard let snapshot = snapshot, !snapshot.isEmpty else {
                       // El email no está registrado en Firestore
                       self.showErrorMessage("El correo electrónico no está registrado.")
                       return
                   }
                   // El email está registrado en Firestore
                   Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
                       activityIndicator.stopAnimating()

                       if let error = error {

                           if error._code == AuthErrorCode.invalidEmail.rawValue {
                               self.showErrorMessage("Por favor ingrese un correo electrónico válido.")
                           } else if error._code == AuthErrorCode.wrongPassword.rawValue {
                               self.showErrorMessage("La contraseña ingresada es incorrecta. Por favor inténtelo nuevamente.")
                           }

                       } else {
                           // Autenticación exitosa
                        let userRef = self.db.collection("users").document(result!.user.uid)
                           
                           userRef.getDocument { (document, error) in
                               if let document = document, document.exists {
                                   let data = document.data()!
                                   let name = data["name"] as! String
                                   let email = data["email"] as! String
                                   print("Bienvenido, \(name)! Te has autenticado con éxito con la dirección de correo electrónico \(email).")
                                   
                                     // Transición a otra vista distributors
                                    guard let navigationController = self.navigationController else {
                                          fatalError("No se ecnontro navigation controller")
                                        }
                                        let storyboard = UIStoryboard(name: "Distributors", bundle: nil)
                                        guard let distributorsProductVC = storyboard.instantiateViewController(withIdentifier: "ProductsViewController") as? ProductsViewController else {
                                        fatalError("No se econtro instancia de VC con id DistributorsViewController'")
                                        }
                                    navigationController.pushViewController(distributorsProductVC, animated: true)
                                                        
                                
                               } else {
                                   print("No se encontró el documento de usuario.")
                               }
                           }
                       }
                   }
               }
           }
        }
        
        private func isValidEmail(_ email: String) -> Bool {
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
            return emailPred.evaluate(with: email)
        }
        
        private func showErrorMessage(_ message: String) {
            let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(okayAction)
            present(alertController, animated: true, completion: nil)
        }
    }
