//
//  AppConfig.swift
//  sample
//
//  Firebase Cloud Function endpoint URLs and client configuration.
//  This file is listed in .gitignore — copy AppConfig.swift.example and fill in values.
//

import Foundation

enum AppConfig {

    // MARK: - FAPI 2 endpoints

    /// Step 1 — backend generates PAR request_uri (PKCE + DPoP handled server-side)
    static let fapiGenerateRequestUriEndpoint = ""
	
	/// Step 1 - Url 
	static func urlComponents(isMyinfo: Bool, encodedRedirect: String) -> URLComponents? {
		var components = URLComponents(string: AppConfig.fapiGenerateRequestUriEndpoint)
		components?.queryItems = [
			URLQueryItem(name: "authType", value: isMyinfo ? AppConfig.AuthType.userinfo.rawValue: AppConfig.AuthType.singpass.rawValue),
			URLQueryItem(name: "appLaunchUrl", value: encodedRedirect)
		]
		
		return components
	}

    /// Step 3 — backend receives auth code and exchanges for session token
    static let fapiReceiveAuthCodeEndpoint = ""
	
	enum AuthType: String {
		case singpass, sfv, userinfo
	}
}
