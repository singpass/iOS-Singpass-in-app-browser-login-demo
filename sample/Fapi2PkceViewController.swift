//
//  Fapi2PkceViewController.swift
//  sample
//
//  FAPI 2 PAR flow using ASWebAuthenticationSession (no AppAuth dependency).
//  The backend handles PKCE code_verifier, code_challenge, and DPoP entirely.
//

import UIKit
import AuthenticationServices

@available(iOS 13.0, *)
class WebSessionManager {
	
	private init() {}
	static var shared = WebSessionManager()
	
	var viewController: Fapi2PkceViewController?
	var webAuthSession: ASWebAuthenticationSession?
}

@available(iOS 13.0, *)
class Fapi2PkceViewController: UIViewController {
	
	var myInfo: Bool = false
	
	// MARK: - Service endpoints
	
	var authorizationEndpoint: String = "https://stg-id.singpass.gov.sg/fapi/auth"
	
	// MARK: - Client IDs
	
	var clientID: String {
		myInfo ? "f5bB48EimWijVzti0f7J5oqbHyLVvckX" : "pJ4rxHxQBiGtHSbNCLUxoD3fUVi850SD"
	}
	
	let redirectURI: String = "https://app.singpass.gov.sg/rp/sample"
	
	let callbackHostURL: String = "app.singpass.gov.sg"
	let callbackPath: String = "/rp/sample"
	
	let fapiGenerateRequestUriEndpoint: String = ""

	// MARK: - State
	
	private var state: String?
	private var nonce: String?
	private var requestUri: String?
	
	@IBOutlet weak var sampleView: SampleView!
	
	// MARK: - Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.title = "FAPI2 PKCE"
		self.navigationController?.navigationBar.titleTextAttributes = [
			NSAttributedString.Key.font: UIFont.Title()
		]
		
		sampleView.setupUI()
		sampleView.buttonDelegate = self
		
		sampleView.tableView.allowsSelection = true
	}
}

// MARK: - FAPI 2 Flow
@available(iOS 13.0, *)
extension Fapi2PkceViewController {
	
	/// FAPI Step 1 — GET request_uri from RP Backend (backend handles PKCE + DPoP + PAR)
	func getFapiRequestUri() {
		let encodedRedirect = redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? redirectURI
		
		/// Step 1 - fapiGenerateRequestUriEndpoint
		let components = AppConfig.urlComponents(isMyinfo: myInfo, encodedRedirect: encodedRedirect)
		
		guard let url = components?.url else {
			self.log("Error: failed to build fapiGenerateRequestUriEndpoint URL", label: 0)
			return
		}
		
		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
		
		self.log("Requesting FAPI request_uri...", label: 0)
		
		URLSession.shared.dataTask(with: request) { data, _, error in
			guard let data else {
				self.log("Error: no data from getFapiRequestUri — \(error?.localizedDescription ?? "unknown")", label: 0)
				return
			}
			
			guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
				self.log("Error: failed to parse getFapiRequestUri response", label: 0)
				return
			}
			
			printd("FAPI generate response: \(json)")
			
			guard let requestUri = json["requestUri"] as? String,
				  let state = json["state"] as? String,
				  let nonce = json["nonce"] as? String else {
				self.log("Error: missing requestUri or state in response", label: 0)
				return
			}
			
			self.requestUri = requestUri
			self.state = state
			self.nonce = nonce
			
			self.performFapiAuthCodeExchange(requestUri: requestUri)
		}.resume()
	}
	
	/// FAPI Step 2 — Launch authorization URL with request_uri via ASWebAuthenticationSession
	func performFapiAuthCodeExchange(requestUri: String) {
		
		var components = URLComponents(string: authorizationEndpoint)
		components?.queryItems = [
			URLQueryItem(name: "client_id", value: clientID),
			URLQueryItem(name: "request_uri", value: requestUri)
		]
		
		guard let authURL = components?.url else {
			self.log("Error: failed to build authorization URL", label: 0)
			return
		}
		
		DispatchQueue.main.async {
			self.sampleView.setAuthCode("Waiting for authCode...")
			
			WebSessionManager.shared.viewController = self
			let session: ASWebAuthenticationSession = if #available(iOS 17.4, *) {
				ASWebAuthenticationSession(url: authURL, callback: .https(host: self.callbackHostURL, path: self.callbackPath)) { callbackURL, error in
					if let error {
						self.log("Error: \(error.localizedDescription)", label: 0)
						return
					}
					
					guard let callbackURL else {
						self.log("Error: no callback URL received", label: 0)
						return
					}
					
					printd("Callback URL: \(callbackURL)")
					
					let queryItems = URLComponents(url: callbackURL, resolvingAgainstBaseURL: true)?.queryItems
					
					guard let code = queryItems?.first(where: { $0.name == "code" })?.value,
						  !code.isEmpty,
						  let state = queryItems?.first(where: { $0.name == "state" })?.value,
						  !state.isEmpty else {
						self.log("AuthCode: no code returned in callback", label: 0)
						return
					}
					
					self.log("AuthCode: \(code)", label: 0)
					self.postFapiAuthCode(authCode: code, state: state)
				}
			} else {
				// iOS < 17.4: pass nil so ASWebAuthenticationSession does not intercept the
				// HTTPS redirect itself. The redirect arrives as a Universal Link and is
				// handled by AppDelegate → WebSessionManager → authSessionCallback.
				ASWebAuthenticationSession(url: authURL, callbackURLScheme: nil) { _, error in
					if let error = error as? ASWebAuthenticationSessionError,
					   error.code != .canceledLogin {
						self.log("Error: \(error.localizedDescription)", label: 0)
					}
				}
			}
			
			session.presentationContextProvider = self
			session.prefersEphemeralWebBrowserSession = true
			WebSessionManager.shared.webAuthSession = session
			session.start()
		}
	}
	
	/// FAPI Step 3 — POST auth code to RP Backend to exchange for session token
	func postFapiAuthCode(authCode: String, state: String?) {
		guard let url = URL(string: AppConfig.fapiReceiveAuthCodeEndpoint) else {
			self.log("Error: failed to build fapiReceiveAuthCodeEndpoint URL", label: 1)
			return
		}
		
		let body: [String: String] = [
			"code": authCode,
			"state": state ?? "",
			"nonce": self.nonce ?? "",
			"redirectUri": self.redirectURI
		]
		
		guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
			self.log("Error: failed to serialize request body", label: 1)
			return
		}
		
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.httpBody = bodyData
		request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		
		self.sampleView.setResponse("Exchanging auth code via FAPI...")
		
		URLSession.shared.dataTask(with: request) { data, _, error in
			guard let data else {
				self.log("Error: no data from postFapiAuthCode — \(error?.localizedDescription ?? "unknown")", label: 1)
				return
			}
			
			if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
				self.log("\(json)", label: 1)
				
				printd("FAPI receive response: \(json)")
			}
		}.resume()
	}
}

@available(iOS 13.0, *)
extension Fapi2PkceViewController {
	
	func authSessionCallback(code: String, state: String) {
		if WebSessionManager.shared.webAuthSession == nil {
			self.log("AuthCode: \(code)", label: 0)
			self.postFapiAuthCode(authCode: code, state: state)
			
			return
		}
	}
}

// MARK: - ASWebAuthenticationPresentationContextProviding
@available(iOS 13.0, *)
extension Fapi2PkceViewController: ASWebAuthenticationPresentationContextProviding {
	
	func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
		return self.view.window ?? ASPresentationAnchor()
	}
}

// MARK: - LoginButtonDelegate
@available(iOS 13.0, *)
extension Fapi2PkceViewController: LoginButtonDelegate {
	
	func loginAction() {
		myInfo = false
		self.getFapiRequestUri()
	}
	
	func myinfoAction() {
		myInfo = true
		self.getFapiRequestUri()
	}
}

// MARK: - Helper
@available(iOS 13.0, *)
extension Fapi2PkceViewController {
	
	func log(_ string: String, label: Int) {
		printd(string)
		DispatchQueue.main.async { [weak self] in
			guard let self else { return }
			if label == 0 {
				self.sampleView.setAuthCode(string)
			} else {
				self.sampleView.setResponse(string)
			}
		}
	}
}
