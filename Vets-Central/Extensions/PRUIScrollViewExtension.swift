//
//  PRScrollViewExtension.swift
//  Starfish Constellation
//
//  Created by Roger Vogel on 2/25/22.
//

import Foundation
import UIKit

extension UIScrollView {
    
    func scrollsToBottom(animated: Bool) {
        
        let bottomOffset = CGPoint(x: contentOffset.x, y: contentSize.height - bounds.height + adjustedContentInset.bottom)
        setContentOffset(bottomOffset, animated: animated)
    }
    
    func scrollsToTop(animated: Bool) {
        
        let topOffset = CGPoint(x: contentOffset.x, y: 0)
        setContentOffset(topOffset, animated: animated)
    }
    
    // Fade in and out control
    func fade (toState: FadeTo, withAlpha: CGFloat, forDuration: Double ) {
        
        switch toState {
            
        case FadeTo.hidden:
            UIView.animate ( withDuration: forDuration, animations: { self.alpha = withAlpha }, completion: { finished in self.isHidden = true } )
            
        case FadeTo.dimmed:
            UIView.animate ( withDuration: forDuration, animations: { self.alpha = withAlpha }, completion: { finished in } )
            
        case FadeTo.visible:
            self.isHidden = false
            UIView.animate( withDuration: forDuration, animations: { self.alpha = withAlpha}, completion: { finished in } )
        }
    }
}
