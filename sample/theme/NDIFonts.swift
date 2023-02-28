//
//  NDIFonts.swift
//

import CoreGraphics
import UIKit

struct kNDIFont {
	static let Black = "Poppins-Black"
	static let BlackItalic = "Poppins-BlackItalic"
	static let Light = "Poppins-Light"
	static let LightItalic = "Poppins-LightItalic"
	static let Regular = "Poppins-Regular"
	static let Italic = "Poppins-Italic"
	static let Medium = "Poppins-Medium"
	static let MediumItalic = "Poppins-MediumItalic"
	static let SemiBold = "Poppins-SemiBold"
	static let SemiBoldItalic = "Poppins-SemiBoldItalic"
	static let Bold = "Poppins-Bold"
	static let BoldItalic = "Poppins-BoldItalic"
}

public extension UIFont {
	
	enum NDIFontType: String {
		case black
		case blackItalic
		case italic
		case light
		case lightItalic
		case medium
		case mediumItalic
		case regular
		case semiBold
		case semiBoldItalic
		case bold
		case boldItalic
		
		public var value: String {
			switch self {
			case .black: return kNDIFont.Black
			case .blackItalic: return kNDIFont.BlackItalic
			case .italic: return kNDIFont.Italic
			case .light: return kNDIFont.Light
			case .lightItalic: return kNDIFont.LightItalic
			case .medium: return kNDIFont.Medium
			case .mediumItalic: return kNDIFont.MediumItalic
			case .regular: return kNDIFont.Regular
			case .semiBold: return kNDIFont.SemiBold
			case .semiBoldItalic: return kNDIFont.SemiBoldItalic
			case .bold: return kNDIFont.Bold
			case .boldItalic: return kNDIFont.BoldItalic
			}
		}
	}
	
	static func NDIFont(type: NDIFontType = .regular, size: CGFloat = 16.0) -> UIFont {
		return UIFont(name: type.value, size: size) ?? UIFont.systemFont(ofSize: size)
	}
}

// MARK: - Heading
public extension UIFont {
	
	/**
	font-family: poppins, sans-serif;
	font-style: normal;
	font-weight: semibold;
	font-size: 22px;
	line-height: 32px;
	*/
	static func Heading_3_SemiBold() -> UIFont { return NDIFont(type: .semiBold, size: 22) }
}

// MARK: - Body
public extension UIFont {
	
	/**
	font-family: poppins, sans-serif;
	font-style: normal;
	font-weight: medium;
	font-size: 14px;
	line-height: 24px;
	*/
	static func Title() -> UIFont { return NDIFont(type: .medium, size: 14) }
	
	/**
	font-family: poppins, sans-serif;
	font-style: normal;
	font-weight: regular;
	font-size: 16px;
	line-height: 24px;
	*/
	static func Body() -> UIFont { return NDIFont(type: .regular, size: 16) }
}
