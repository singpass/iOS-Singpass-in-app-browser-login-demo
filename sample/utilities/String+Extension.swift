//
//  String+Extension.swift
//  sample
//
//  Created by Law Xun Da on 23/2/23.
//  Copyright © 2023 Govtech. All rights reserved.
//

import Foundation
import CommonCrypto

extension String {
	func sha256() -> String? {
		let data = Data(utf8)
		var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
		
		data.withUnsafeBytes { buffer in
			_ = CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &hash)
		}
		
		return Data(hash).base64URLEncodedString
	}
}
