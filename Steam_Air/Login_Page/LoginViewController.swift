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
    @IBOutlet weak var orLabel: UILabel!
    
    private lazy var featureIconsStack: UIStackView = {
        let icons = ["house.fill", "books.vertical.fill", "bag.fill", "heart.fill"]
            .map { symbolName -> UIView in
                let container = UIView()
                container.backgroundColor = UIColor.secondarySystemBackground
                container.layer.cornerRadius = 22
                container.translatesAutoresizingMaskIntoConstraints = false
                container.widthAnchor.constraint(equalToConstant: 44).isActive = true
                container.heightAnchor.constraint(equalToConstant: 44).isActive = true

                let imageView = UIImageView(image: UIImage(systemName: symbolName))
                imageView.tintColor = .systemBlue
                imageView.contentMode = .scaleAspectFit
                imageView.translatesAutoresizingMaskIntoConstraints = false
                container.addSubview(imageView)
                NSLayoutConstraint.activate([
                    imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                    imageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                    imageView.widthAnchor.constraint(equalToConstant: 20),
                    imageView.heightAnchor.constraint(equalToConstant: 20),
                ])
                return container
            }

        let stack = UIStackView(arrangedSubviews: icons)
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    
    @IBAction func rememberMeTapped(_ sender: UIButton) {
        isRememberMeSelected.toggle()
        updateRememberMeButton()
    }
    
    @IBAction func continueWithSteamTapped(_ sender: UIButton) {
        startSteamLogin()
    }

    @IBAction func signUpTapped(_ sender: UIButton) {
        guard let url = URL(string: "https://store.steampowered.com/join/") else { return }
        UIApplication.shared.open(url)
    }
    
    // variety
    private var isRememberMeSelected = false
    private var authSession: ASWebAuthenticationSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("LoginViewController loaded")
        updateRememberMeButton()
        
        // Keep Steam-only login flow on this page.
        emailTextField.isHidden = true
        passwordTextField.isHidden = true
        loginButton.isHidden = true
        rememberMeButton.isHidden = true
        orLabel.isHidden = true

        steamButton.layer.cornerRadius = 22
        steamButton.clipsToBounds = true

        setupFeatureIconsStrip()
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
    
    private func setupFeatureIconsStrip() {
        view.addSubview(featureIconsStack)
        NSLayoutConstraint.activate([
            featureIconsStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            featureIconsStack.bottomAnchor.constraint(equalTo: steamButton.topAnchor, constant: -120),
        ])
    }
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.view.window ?? ASPresentationAnchor()
    }
}
