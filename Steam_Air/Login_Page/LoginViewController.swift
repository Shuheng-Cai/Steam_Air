//
//  LoginViewController.swift
//  Steam_Air
//
//  Created by Sicheng on 3/30/26.
//

internal import UIKit
import AuthenticationServices

class LoginViewController: UIViewController, ASWebAuthenticationPresentationContextProviding {
    
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
    
    @IBAction func continueWithSteamTapped(_ sender: UIButton) {
        startSteamLogin()
    }
    
    // variety
    private var isRememberMeSelected = false
    private var authSession: ASWebAuthenticationSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("LoginViewController loaded")
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
    
    private func startSteamLogin() {
        guard let url = URL(string:"http://18.136.66.102/auth/steam/login") else{return}
        authSession = ASWebAuthenticationSession(url: url, callbackURLScheme: "steamair") {callbackURL, error in
            if let error = error {
                print("Steam login error:", error.localizedDescription)
                return
            }

            guard let callbackURL = callbackURL else {
                print("No Callback URL")
                return
            }
            
            print("Callback URL:", callbackURL.absoluteString)
            
            let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
            let steamID = components?.queryItems?.first(where: { $0.name == "steamid" })?.value
            print("Steam ID:", steamID ?? "Not found")
            
            if let steamID = steamID {
                DispatchQueue.main.async {
                    let storyboard = UIStoryboard(name: "HomePageScreen", bundle: nil)
                    guard let tabBarVC = storyboard.instantiateViewController(withIdentifier: "HomePageScreen") as? UITabBarController else {
                        print("Failed to load HomePageScreen tab bar controller")
                        return
                    }

                    for case let nav as UINavigationController in tabBarVC.viewControllers ?? [] {
                        guard let rootVC = nav.viewControllers.first else { continue }
                        if let homeVC = rootVC as? HomeViewController {
                            homeVC.steamID = steamID
                        } else if let libraryVC = rootVC as? LibraryViewController {
                            libraryVC.steamID = steamID
                        } else if let wishlistVC = rootVC as? WishlistViewController {
                            wishlistVC.steamID = steamID
                        }
                    }

                    tabBarVC.modalPresentationStyle = .fullScreen
                    self.present(tabBarVC, animated: true)
                }
            }
        }
        authSession?.presentationContextProvider = self
        authSession?.prefersEphemeralWebBrowserSession = true
        authSession?.start()
    }
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.view.window ?? ASPresentationAnchor()
    }
}
