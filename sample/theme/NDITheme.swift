//
//  NDITheme.swift
//

import UIKit

public class NDITheme: ThemeColorsProtocol {
	
    public static var colorBackground: UIColor { return nameColor("colorBackground") }
    public static var colorOnBackground: UIColor { return nameColor("colorOnBackground") }

	public static var colorSurface: UIColor { return nameColor("colorSurface") }
    public static var colorOnSurface: UIColor { return nameColor("colorOnSurface") }

}

extension NDITheme {
    
    static func nameColor(_ named: String) -> UIColor {
        let defaultColor = UIColor.gray
        guard let bundle = Bundle(identifier: "sg.ndi.sample") else { return defaultColor }
        if #available(iOS 13.0, *) {
            return UIColor(named: named, in: bundle, compatibleWith: .current) ?? defaultColor
        }
        else {
            return UIColor(named: named, in: bundle, compatibleWith: .none) ?? defaultColor
        }
    }
}

public protocol ThemeColorsProtocol {
    
    // Theme
    /**
     The background color appears behind scrollable content.
     */
    static var colorBackground: UIColor { get }
    
    /**
     A color that passes accessibility guidelines for text/iconography when drawn on top of the background color.
     */
    static var colorOnBackground: UIColor { get }
    
    /**
     Surface colors affect surfaces of components, such as cards, sheets, and menus.
     */
    static var colorSurface: UIColor { get }
    
    /**
     A color that passes accessibility guidelines for text/iconography when drawn on top of the surface color.
     */
    static var colorOnSurface: UIColor { get }
}
