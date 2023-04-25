//
//  SampleView.swift
//  sample
//
//  Created by Law Xun Da on 23/2/23.
//  Copyright © 2023 Govtech. All rights reserved.
//

import UIKit

protocol LoginButtonDelegate: AnyObject {
	func loginAction()
	func myinfoAction()
}

class SampleView: UIView {
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var tableView: IntrinsicTableView!
	@IBOutlet weak var loginButton: UIButton!
	@IBOutlet weak var myinfoButton: UIButton!
	@IBOutlet weak var authCodeLabel: UILabel!
	@IBOutlet weak var responseLabel: UILabel!
	
	weak var buttonDelegate: LoginButtonDelegate?
	
	func setupUI() {
		titleLabel.font = .Heading_3_SemiBold()
		authCodeLabel.font = .Body()
		responseLabel.font = .Body()
		
		tableView.backgroundColor = .clear
		tableView.isScrollEnabled = false
		
		let loginTapGesture = UITapGestureRecognizer(target: self, action: #selector(loginAction))
		loginButton.addGestureRecognizer(loginTapGesture)
		let myinfoTapGesture = UITapGestureRecognizer(target: self, action: #selector(myinfoAction))
		myinfoButton.addGestureRecognizer(myinfoTapGesture)
	}
	
	func setAuthCode(_ code: String?) {
		authCodeLabel.text = code ?? ""
	}
	
	func setResponse(_ response: String?) {
		responseLabel.text = response ?? ""
	}
}

extension SampleView {
	@objc
	func loginAction() {
		buttonDelegate?.loginAction()
	}
	
	@objc
	func myinfoAction() {
		buttonDelegate?.myinfoAction()
	}
}

final class IntrinsicTableView: UITableView {
	override var contentSize: CGSize {
		didSet {
			invalidateIntrinsicContentSize()
		}
	}
	
	override var intrinsicContentSize: CGSize {
		layoutIfNeeded()
		return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
	}
}
