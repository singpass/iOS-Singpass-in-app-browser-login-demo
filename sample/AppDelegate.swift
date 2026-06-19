//
//  AppDelegate.swift
//  sample
//
//  Created by Law Xun Da on 23/2/23.
//  Copyright © 2023 Govtech. All rights reserved.
//

import UIKit
import AuthenticationServices

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		return true
	}
	
	func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
		return false
	}
	
	func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
		
		printd("DEBUG - ASWeb callback: \(userActivity.webpageURL?.absoluteString, default: "<nil>")")
		
		guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
			  let url = userActivity.webpageURL else {
			return false
		}
		
		let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
		
		guard let queryItems = urlComponents?.queryItems,
			  let code = queryItems.first(where: { $0.name == "code" })?.value,
			  !code.isEmpty,
			  let state = queryItems.first(where: { $0.name == "state" })?.value,
			  !state.isEmpty
		else {
			return false
		}
		
		if #available(iOS 13.0, *) {
			if let session = WebSessionManager.shared.webAuthSession, let vc = WebSessionManager.shared.viewController {
				WebSessionManager.shared.webAuthSession = nil
				session.cancel()
				
				vc.authSessionCallback(code: code, state: state)
			} else {
				printd("DEBUG - app invoked, but no webAuthSession active, for \(userActivity.webpageURL?.absoluteString, default: "<nil>")")
			}
		}

		return false
	}
}

