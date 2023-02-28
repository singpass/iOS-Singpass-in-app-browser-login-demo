//
//  Data+Extension.swift
//  sample
//
//  Created by Koh Chin Wee on 27/2/23.
//  Copyright © 2023 Govtech. All rights reserved.
//

import Foundation

extension Data {
	
	///
	/// Returns a Base64 URL-encoded string _without_ padding.
	///
	/// This string is compatible with the PKCE Code generation process, and uses the algorithm as defined in the [PKCE standard](https://datatracker.ietf.org/doc/html/rfc7636#appendix-A).
	///
	var base64URLEncodedString: String {
		base64EncodedString()
			.replacingOccurrences(of: "=", with: "") // Remove any trailing '='s
			.replacingOccurrences(of: "+", with: "-") // 62nd char of encoding
			.replacingOccurrences(of: "/", with: "_") // 63rd char of encoding
			.trimmingCharacters(in: .whitespaces)
	}
}
