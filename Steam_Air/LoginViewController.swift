//
//  LoginViewController.swift
//  Steam_Air
//
//  Created by Sicheng on 3/30/26.
//

import UIKit
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
        guard let url = URL(string:"http://10.232.214.33:5050/auth/steam/login") else{return}
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
                let fetcher = FetchGame()
                fetcher.fetchOwnedGames(steamID: steamID) { games in
                    print("Games count:", games.count)
                    
                    for game in games.prefix(10) {
                        print("Name:", game.name)
                        print("Hours:", game.playtimeHours)
                        print("Icon URL:", game.iconURL?.absoluteString ?? "nil")
                        print("-----")
                    }
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
