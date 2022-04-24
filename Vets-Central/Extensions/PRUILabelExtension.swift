//
//  PRLabelExtension.swift
//  Starfish Constellation
//
//  Created by Roger Vogel on 2/25/22.
//

import Foundation
import UIKit

extension UILabel {
    
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
