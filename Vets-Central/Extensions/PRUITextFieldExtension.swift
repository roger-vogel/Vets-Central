//
//  PRTextFieldExtension.swift
//  Starfish Constellation
//
//  Created by Roger Vogel on 2/25/22.
//

import Foundation
import UIKit

extension UITextField{
    
    // Set the placeholder color for a text field
    @IBInspectable var placeholderColor: UIColor {
       
        get {
            return self.attributedPlaceholder!.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor ?? .lightText
        }
        
        set {
            self.attributedPlaceholder = NSAttributedString(string: self.placeholder ?? "", attributes: [.foregroundColor: newValue])
        }
    }
    
    // Fade in and out control
    func fade (toState: FadeTo, withAlpha: CGFloat, forDuration: Double ) {
        
        switch toState {
            
        case FadeTo.hidden:
            self.isEnabled = false
            UIView.animate ( withDuration: forDuration, animations: { self.alpha = withAlpha }, completion: { finished in self.isHidden = true } )
            
        case FadeTo.dimmed:
            self.isEnabled = false
            UIView.animate ( withDuration: forDuration, animations: { self.alpha = withAlpha }, completion: { finished in } )
            
        case FadeTo.visible:
            self.isEnabled = true
            self.isHidden = false
            UIView.animate( withDuration: forDuration, animations: { self.alpha = withAlpha}, completion: { finished in } )
        }
    }
}
