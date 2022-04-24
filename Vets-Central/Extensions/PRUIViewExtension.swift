//
//  PRViewExtension.swift
//  Starfish Constellation
//
//  Created by Roger Vogel on 2/25/22.
//

import Foundation
import UIKit

extension UIView {
    
    func changeDisplayState(toState: FadeTo, withAlpha: CGFloat? = 0.0, forDuration: Double, atCompletion: @escaping ()-> Void ) {
        
        switch toState {
            
            case .hidden:
                
                UIView.animate ( withDuration: forDuration, animations: { self.alpha = 0.0 }, completion: { finished in self.isHidden = true; atCompletion() } )
                
            case .dimmed:
                
                if self is UIButton { (self as! UIButton).isEnabled = false }
                UIView.animate ( withDuration: forDuration, animations: { self.alpha = withAlpha! }, completion: { finished in atCompletion() } )
                
            case .visible:
                
                self.isHidden = false
                if self is UIButton { (self as! UIButton).isEnabled = true }
                UIView.animate( withDuration: forDuration, animations: { self.alpha = 1.0}, completion: { finished in atCompletion() } )
        }
    }
    
    func changeDisplayState(toState: FadeTo) {
        
        switch toState {
            
            case .hidden:
                
                self.isHidden = true
              
            case .dimmed:
                
                if self is UIButton { (self as! UIButton).isEnabled = false }
                self.alpha = 0.30
                
            case .visible:
                
                self.isHidden = false
                if self is UIButton { (self as! UIButton).isEnabled = true }
                self.alpha = 1.0
        }
    }
    
    func slideIn (forDuration: Double, atCompletion: @escaping ()-> Void) {
        
        self.alpha = 1.0
        UIView.animate( withDuration: forDuration, animations: { self.frame.origin.x = 0 }, completion: { finished in atCompletion() } )
    }
    
    func slideOut (slideType: SlideIn, forDuration: Double, atCompletion: @escaping ()-> Void) {
        
        if slideType == .childr { UIView.animate( withDuration: forDuration, animations: { self.frame.origin.x = self.frame.size.width }, completion: { finished in atCompletion() } ) }
        else  { UIView.animate( withDuration: forDuration, animations: { self.frame.origin.x = -self.frame.size.width }, completion: { finished in atCompletion() } ) }
    }
    
    func roundCorners(corners: Corners, radius: CGFloat? = 5) {
         
        self.clipsToBounds = true
        self.layer.cornerRadius = radius!
        
        switch corners {
            
            case .topLeft:     self.layer.maskedCorners = [.layerMinXMinYCorner]
            case .topRight:    self.layer.maskedCorners = [.layerMaxXMinYCorner]
            case .bottomLeft:  self.layer.maskedCorners = [.layerMinXMaxYCorner]
            case .bottomRight: self.layer.maskedCorners = [.layerMaxXMaxYCorner]
            case .left:        self.layer.maskedCorners = [.layerMinXMinYCorner,.layerMinXMaxYCorner]
            case .right:       self.layer.maskedCorners = [.layerMaxXMinYCorner,.layerMaxXMaxYCorner]
            case .top:         self.layer.maskedCorners = [.layerMinXMinYCorner,.layerMaxXMinYCorner]
            case .bottom:      self.layer.maskedCorners = [.layerMinXMaxYCorner,.layerMaxXMaxYCorner]
            case .all:         self.layer.maskedCorners = [.layerMinXMinYCorner,.layerMaxXMinYCorner,.layerMinXMaxYCorner,.layerMaxXMaxYCorner]
        }
    }
    
    func roundAllCorners(value: CGFloat? = 5) { self.layer.cornerRadius = value! }
    
    func setBorder(width: CGFloat, color: CGColor? = nil) {
        
        self.layer.borderWidth = width
        if color != nil { self.layer.borderColor = color }
    }
    
    func addBorders(edges: UIRectEdge, color: UIColor? = .lightGray, width: CGFloat? = 1.0) {
        
        if edges.contains(UIRectEdge.top) { addTopBorder(with: color!, andWidth: width!) }
        if edges.contains(UIRectEdge.bottom) { addBottomBorder(with: color!, andWidth: width!) }
        if edges.contains(UIRectEdge.left) { addLeftBorder(with: color!, andWidth: width!) }
        if edges.contains(UIRectEdge.right) { addRightBorder(with: color!, andWidth: width!) }
    }
    
    func addTopBorder(with color: UIColor?, andWidth borderWidth: CGFloat) {
      
        let border = UIView()
        border.backgroundColor = color
        border.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        border.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: borderWidth)
        addSubview(border)
    }

    func addBottomBorder(with color: UIColor?, andWidth borderWidth: CGFloat) {
      
        let border = UIView()
        border.backgroundColor = color
        border.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        border.frame = CGRect(x: 0, y: frame.size.height - borderWidth, width: frame.size.width, height: borderWidth)
        addSubview(border)
    }

    func addLeftBorder(with color: UIColor?, andWidth borderWidth: CGFloat) {
   
        let border = UIView()
        border.backgroundColor = color
        border.frame = CGRect(x: 0, y: 0, width: borderWidth, height: frame.size.height)
        border.autoresizingMask = [.flexibleHeight, .flexibleRightMargin]
        addSubview(border)
    }

    func addRightBorder(with color: UIColor?, andWidth borderWidth: CGFloat) {
       
        let border = UIView()
        border.backgroundColor = color
        border.autoresizingMask = [.flexibleHeight, .flexibleLeftMargin]
        border.frame = CGRect(x: frame.size.width - borderWidth, y: 0, width: borderWidth, height: frame.size.height)
        addSubview(border)
    }
}
