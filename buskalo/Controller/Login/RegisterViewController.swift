//
//  RegisterViewController.swift
//  buskalo
//
//  Created by crizcode on 2/6/23.
//  Copyright © 2023 crizcode. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

class RegisterViewController: UIViewController {
    
    
    //Outlets
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var eyeButton: UIButton!
    
    // Variables
    private let db = Firestore.firestore()
    private var isPasswordVisible = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    
    }
    

    @IBAction func registerButtonTapped(_ sender: Any) {
         guard let name = nameTextField.text,
                    let email = emailTextField.text,
                    let password = passwordTextField.text,
                    !name.isEmpty,
                    !email.isEmpty,
                    !password.isEmpty else {
                        showAlert(withTitle: "Error", message: "Por favor ingrese nombre, correo electrónico y contraseña.")
                        return
                }
                
                guard isValidEmail(email) else {
                    showAlert(withTitle: "Error", message: "Por favor ingrese un correo electrónico válido.")
                    return
                }
                
                Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
                    guard let user = authResult?.user, error == nil else {
                        self.showAlert(withTitle: "Error", message: error!.localizedDescription)
                        return
                    }
                    
                    let data = ["name": name, "email": email]
                    self.db.collection("users").document(user.uid).setData(data, completion: { (error) in
                        if let error = error {
                            self.showAlert(withTitle: "Error", message: error.localizedDescription)
                        } else {
                            self.showAlert(withTitle: "Exito", message: "Usuario registrado exitosamente") {
                                self.nameTextField.text = ""
                                self.emailTextField.text = ""
                                self.passwordTextField.text = ""
                            }
                        }
                    })
                }
            }
            
            @IBAction func eyeButtonTapped(_ sender: Any) {
                isPasswordVisible.toggle()
                passwordTextField.isSecureTextEntry = !isPasswordVisible
                
                let imageName = isPasswordVisible ? "eye.fill" : "eye.slash.fill"
                eyeButton.setImage(UIImage(systemName: imageName), for: .normal)
            }
            
            // MARK: - Helpers
            
            private func isValidEmail(_ email: String) -> Bool {
                let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
                let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
                return emailPred.evaluate(with: email)
            }
            
            private func showAlert(withTitle title: String, message: String, completion: (() -> Void)? = nil) {
                let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                    completion?()
                }
                alertController.addAction(okAction)
                present(alertController, animated: true, completion: nil)
            }
        }
