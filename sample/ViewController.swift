//
//  ViewController.swift
//  sample
//
//  Created by Law Xun Da on 23/2/23.
//  Copyright © 2023 Govtech. All rights reserved.
//

import UIKit
import AppAuth

class ViewController: UIViewController {

	typealias PostRegistrationCallback = (_ configuration: OIDServiceConfiguration?, _ registrationResponse: OIDRegistrationResponse?) -> Void
	
	var myInfo: Bool = true
	
	/**
	 The OIDC issuer from which the configuration will be discovered.
	 */
	var serviceConfigEndpoints: [String: String] {
		if myInfo {
			return [
				"issuer": "https://test.api.myinfo.gov.sg",
				"authorizationEndpoint": "https://test.api.myinfo.gov.sg/com/v4/authorize",
				"tokenEndpoint": "https://test.api.myinfo.gov.sg/com/v4/token"
			]
		} else {
			return [
				"issuer": "https://stg-id.singpass.gov.sg",
				"authorizationEndpoint": "https://stg-id.singpass.gov.sg/auth",
				"tokenEndpoint": "https://test.api.myinfo.gov.sg/com/v4/token"
			]
		}
	}
	
	/**
	 The OAuth client ID.
	 
	 For client configuration instructions, see the [README](https://github.com/openid/AppAuth-iOS/blob/master/Examples/Example-iOS_Swift-Carthage/README.md).
	 Set to nil to use dynamic registration with this example.
	 */
	//let kClientID: String? = "YOUR_CLIENT_ID"
	var kClientID: String? {
		if myInfo {
			return "STG2-MYINFO-SELF-TEST"
		} else {
			return "xKdfiRj368NJ2F0OVlBjdjBBYdEc46gp"
		}
	}
	
	/**
	 The OAuth redirect URI for the client @c kClientID.
	 
	 For client configuration instructions, see the [README](https://github.com/openid/AppAuth-iOS/blob/master/Examples/Example-iOS_Swift-Carthage/README.md).
	 */
	//let kRedirectURI: String = "com.example.app:/oauth2redirect/example-provider"
	let kRedirectURI: String = "sg.gov.singpass.app://ndisample.gov.sg/rp/sample"
	
	/**
	 RP Mobile App requests for PKCE code challenge for 1a
	 */
	var generatePKCECodeChallenge: String = ""
	
	/**
	 RP Backend endpoints for 3a
	 */
	let authCodeEndpoint: String = ""
	
	/**
	 NSCoding key for the authState property.
	 */
	let kAppAuthExampleAuthStateKey: String = "authState"
	
	let appLaunchURL: String = "app_launch_url"
	let appLinkURL: String = "ndisample://ndisample.gov.sg/rp/sample"
	
	private var authState: OIDAuthState?
	
	private var sessionVerifier: String?
	private var sessionChallenge: String?
	private var session_id: String?
	private var codeChallenge: String?
	private var codeChallengeMethod: String?
	private var state: String?
	private var nonce: String?
	
	@IBOutlet weak var sampleView: SampleView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.title = "NDI Rp Sample"
		self.navigationController?.navigationBar.titleTextAttributes = [
			NSAttributedString.Key.font: UIFont.Title()
		]
		
		sampleView.setupUI()
		sampleView.buttonDelegate = self
		self.loadState()
	}
}

extension ViewController {
	
	///	1a) Call RP Backend to generate PKCE code
	///	1b) RP Backend responds with requested parameters. (code_challenge, code_challenge_method, state, nonce)
	func getPKCECode() {
		guard let randomBytes = generateRandomBytes() else {
			printd("Error generating session verifier for : \(generatePKCECodeChallenge)")
			return
		}
		printd("The session verifier is : \(String(describing: sessionVerifier))")
		guard let sessionChallenge = randomBytes.sha256() else {
			printd("Error generating session challenge for : \(generatePKCECodeChallenge)")
			return
		}
		self.sessionChallenge = sessionChallenge
		printd("The session challenge is : \(sessionChallenge)")
		
		var urlString: String
		
		if myInfo {
			urlString = generatePKCECodeChallenge + "&myinfo=%@"
			urlString = String(format: urlString, sessionChallenge, String(myInfo))
		} else {
			urlString = String(format: generatePKCECodeChallenge, sessionChallenge)
		}
		
		guard let url = URL(string: urlString) else {
			printd("Error creating URL for : \(urlString)")
			return
		}
		
		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
		
		printd("Generating code challenge for auth code: \(url)")
		
		sampleView.setAuthCode("Getting PKCE params...")
		let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
			guard let data = data, let encodedData = String(data: data, encoding: .utf8) else {
				printd("Failed to get any data")
				return
			}
			printd("The response is : \(encodedData)")
			
			if let json = try? JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? [String: Any] {
				self.session_id = json["session_id"] as? String
				self.codeChallenge = json["code_challenge"] as? String
				self.codeChallengeMethod = json["code_challenge_method"] as? String
				self.state = json["state"] as? String
				self.nonce = json["nonce"] as? String

				printd("The response is: \(String(describing: json))")
				
				self.performAuthCodeExchange()
			}
		}
		task.resume()
	}
	
	///	Prepare Service Configuration to perform authorization code exchange, 2a and 2b
	func performAuthCodeExchange() {
		printd("Constructing configuration for issuer: \(String(describing: serviceConfigEndpoints["issuer"]))")
		
		guard let authEndpoint = serviceConfigEndpoints["authorizationEndpoint"], let authURL = URL(string: authEndpoint) else {
			printd("Failed to construct configuration as authorizationEndpoint is not set")
			return
		}
		
		guard let tokenEndpoint = serviceConfigEndpoints["tokenEndpoint"], let tokenURL = URL(string: tokenEndpoint) else {
			printd("Failed to construct configuration as tokenEndpoint is not set")
			return
		}
		
		guard let issuerEndpoint = serviceConfigEndpoints["issuer"], let issuerURL = URL(string: issuerEndpoint) else {
			printd("Failed to construct configuration as issuer is not set")
			return
		}
		
		let configuration = OIDServiceConfiguration(authorizationEndpoint: authURL, tokenEndpoint: tokenURL, issuer: issuerURL)
		
		guard let clientId = kClientID else {
			printd("Failed to construct configuration as kClientID is not set")
			return
		}
		
		DispatchQueue.main.async {
			self.doAuthWithoutCodeExchange(configuration: configuration, clientID: clientId, clientSecret: nil)
		}
	}
	
	///	3b) Sends authorization code back to RP backend
	func postAuthCode(nonce: String? = nil, state: String? = nil) {
		guard let url = URL(string: authCodeEndpoint) else {
			printd("Error creating URL for : \(authCodeEndpoint)")
			return
		}
		
		guard let tokenExchangeRequest = self.authState?.lastAuthorizationResponse.tokenExchangeRequest(), let authCode = tokenExchangeRequest.authorizationCode else {
			printd("Error creating authorization code exchange request for : \(url)")
			return
		}
		
		guard let session_id else {
			printd("No session_id for : \(url)")
			printd("Ending request.")
			return
		}
		
		guard let sessionVerifier else {
			printd("No session verifier for : \(url)")
			printd("Ending request.")
			return
		}
		
		var reqBody: [String: String] = [
			"code": authCode,
			"session_id": session_id,
			"session_verifier": sessionVerifier
		]
		
		if let state, let nonce {
			reqBody["state"] = state
			reqBody["nonce"] = nonce
		} else {
			printd("No state and nonce for : \(url)")
		}
		
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.httpBody = getFormDataPostString(params: reqBody).data(using: .utf8)
		request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
		request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
		
		printd("Passing auth code to RP Backend: \(url)")
		sampleView.setResponse("Sending authCode back to backend and waiting for response...")
		let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
			guard let data = data, let encodedData = String(data: data, encoding: .utf8) else {
				printd("Failed to get any data")
				return
			}
			printd("The response is : \(encodedData)")
			DispatchQueue.main.async {
				self.sampleView.setResponse("Access Token: \(encodedData)")
			}
		}
		task.resume()
	}
}

//MARK: AppAuth Methods
extension ViewController {
	
	func doAuthWithoutCodeExchange(configuration: OIDServiceConfiguration, clientID: String, clientSecret: String?) {
		guard let redirectURI = URL(string: kRedirectURI) else {
			printd("Error creating URL for : \(kRedirectURI)")
			return
		}
		
		guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
			printd("Error accessing AppDelegate")
			return
		}
		
		// builds authentication request
		var request: OIDAuthorizationRequest {
			var dict: [String: String] = [appLaunchURL: appLinkURL]
			
			if myInfo {
				dict["purpose_id"] = "demonstration"
				
				return OIDAuthorizationRequest(configuration: configuration,
											   clientId: clientID,
											   clientSecret: nil,
											   scope: "name",
											   redirectURL: redirectURI,
											   responseType: OIDResponseTypeCode,
											   state: nil,
											   nonce: nil,
											   codeVerifier: nil,
											   codeChallenge: codeChallenge,
											   codeChallengeMethod: codeChallengeMethod,
											   additionalParameters: dict)
			} else {
				return OIDAuthorizationRequest(configuration: configuration,
											   clientId: clientID,
											   clientSecret: nil,
											   scope: OIDScopeOpenID,
											   redirectURL: redirectURI,
											   responseType: OIDResponseTypeCode,
											   state: state,
											   nonce: nonce,
											   codeVerifier: nil,
											   codeChallenge: codeChallenge,
											   codeChallengeMethod: codeChallengeMethod,
											   additionalParameters: dict)
			}
		}
		
		// performs authentication request
		printd("Initiating authorization request with scope: \(request.scope ?? "no scope set")")
		
		sampleView.setAuthCode("Waiting for authCode...")
		appDelegate.currentAuthorizationFlow = OIDAuthorizationService.present(request, presenting: self) { (response, error) in
			
			if let response = response {
				let authState = OIDAuthState(authorizationResponse: response)
				self.setAuthState(authState)
				
				printd("Authorization response with code: \(response.authorizationCode ?? "no code returned")")
				
				self.sampleView.setAuthCode("AuthCode: \(response.authorizationCode ?? "no code returned")")
				
				if self.myInfo {
					self.postAuthCode()
				} else {
					self.postAuthCode(nonce: request.nonce, state: request.state)
				}
			} else {
				printd("Authorization error: \(error?.localizedDescription ?? "DEFAULT_ERROR")")
			}
		}
	}
}

//MARK: OIDAuthState Delegate
extension ViewController: OIDAuthStateChangeDelegate, OIDAuthStateErrorDelegate {
	
	func didChange(_ state: OIDAuthState) {
		self.stateChanged()
	}
	
	func authState(_ state: OIDAuthState, didEncounterAuthorizationError error: Error) {
		printd("Received authorization error: \(error)")
	}
}

//MARK: IBActions
extension ViewController {
	
	@IBAction func trashClicked(_ sender: UIBarButtonItem) {
		let alert = UIAlertController(title: nil,
									  message: nil,
									  preferredStyle: UIAlertController.Style.actionSheet)
		
		let clearAuthAction = UIAlertAction(title: "Clear OAuthState", style: .destructive) { (_: UIAlertAction) in
			self.setAuthState(nil)
			self.sampleView.setAuthCode("No authCode obtained yet!")
			self.sampleView.setResponse("No idToken obtained yet!")
		}
		alert.addAction(clearAuthAction)
		
		if let popoverController = alert.popoverPresentationController {
			popoverController.barButtonItem = sender
		}
		
		self.present(alert, animated: true, completion: nil)
	}
}

extension ViewController: LoginButtonDelegate {
	
	func loginAction() {
		myInfo = false
		getPKCECode()
	}
	
	func myinfoAction() {
		myInfo = true
		getPKCECode()
	}
}

//MARK: Helper Methods
extension ViewController {
	
	func saveState() {
		
		var data: Data? = nil
		
		if let authState = self.authState {
			data = try? NSKeyedArchiver.archivedData(withRootObject: authState, requiringSecureCoding: false)
		}
		
		if let data, let userDefaults = UserDefaults(suiteName: "group.net.openid.appauth.Example") {
			userDefaults.set(data, forKey: kAppAuthExampleAuthStateKey)
			userDefaults.synchronize()
		}
	}
	
	func loadState() {
		guard let data = UserDefaults(suiteName: "group.net.openid.appauth.Example")?.object(forKey: kAppAuthExampleAuthStateKey) as? Data else {
			return
		}
		
		if let authState = NSKeyedUnarchiver.unarchiveObject(with: data) as? OIDAuthState {
			self.setAuthState(authState)
		}
	}
	
	func setAuthState(_ authState: OIDAuthState?) {
		if (self.authState == authState) {
			return
		}
		self.authState = authState
		self.authState?.stateChangeDelegate = self
		self.stateChanged()
	}
	
	func stateChanged() {
		self.saveState()
	}
}

extension ViewController {
	func generateRandomBytes() -> String? {
		var bytes = [UInt8](repeating: 0, count: 64)
		let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
		
		guard result == errSecSuccess else {
			printd("Problem generating random bytes")
			return nil
		}
	
		sessionVerifier = Data(bytes).base64URLEncodedString
		return sessionVerifier
	}
	
	func getFormDataPostString(params: [String: String]) -> String {
		var components = URLComponents()
		
		components.queryItems = params.keys.compactMap {
			URLQueryItem(name: $0, value: params[$0])
		}
		
		return components.query ?? ""
	}
}
