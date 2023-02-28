//
//  Print.swift
//  sample
//
//  Created by Law Xun Da on 23/2/23.
//  Copyright © 2023 Govtech. All rights reserved.
//

import Foundation

let DEBUG = "NDI Rp Sample: DEBUG"

var dateFormatter: DateFormatter = {
	let formatter = DateFormatter()
	formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSXXXX"
	return formatter
}()

public func printd(_ message: Any? = nil, file: String = #file, function: String = #function, line: Int = #line ) {
	print("\(getTimestamp()) \(DEBUG) \(getBody(file: file, function: function, line: line, message: messageAsString(message)))")
}

/// Helper method to get the body to be printed. Keeping our codes DRY here.
/// Note that if the file where the log method is called is not a swift file (very unlikely), it will show the file extension.
private func getBody(file: String, function: String, line: Int, message: String) -> String {
	return "\(file.split(separator: "/").last?.replacingOccurrences(of: ".swift", with: "") ?? "UnknownFile").\(function):\(line) - \(message)"
}

/// Helper method to get the timestamp to be printed. Keeping our codes DRY here.
private func getTimestamp() -> String {
	return dateFormatter.string(from: Date())
}

/// If it's a string, don't wrap it with describing:
private func messageAsString(_ messageOrNil: Any?) -> String {
	if let messageStr = messageOrNil as? String? {
		return messageStr ?? "<nil>"
	} else if let message = messageOrNil {
		return String(describing: message)
	} else {
		return String(describing: messageOrNil)
	}
}
