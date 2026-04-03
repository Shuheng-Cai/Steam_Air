//
//  LoginViewController.swift
//  Steam_Air
//
//  Created by Sicheng on 3/30/26.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var steamButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var rememberMeButton: UIButton!
    
    
    @IBAction func rememberMeTapped(_ sender: UIButton) {
        isRememberMeSelected.toggle()
        updateRememberMeButton()
    }
    
    // variety
    private var isRememberMeSelected = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateRememberMeButton()
        
        // text field
        emailTextField.placeholder = "Email address"
        passwordTextField.placeholder = "Password"
        passwordTextField.isSecureTextEntry = true
        // button
        loginButton.layer.cornerRadius = 22
        loginButton.clipsToBounds = true
        steamButton.layer.cornerRadius = 22
        steamButton.clipsToBounds = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("LoginViewController appeared")
    }
    
    // remember me statue update function
    private func updateRememberMeButton() {
        let imageName = isRememberMeSelected ? "checkmark.square.fill" : "square"
        let image = UIImage(systemName: imageName)
        
        rememberMeButton.setImage(image, for: .normal)
        rememberMeButton.setTitle(" Remember me", for: .normal)
        rememberMeButton.setTitleColor(.gray, for: .normal)
        rememberMeButton.tintColor = .lightGray
        rememberMeButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
    }
   
    }
