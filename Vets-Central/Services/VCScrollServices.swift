//
//  VCScrollServices.swift
//  Vets-Central
//
//  Scroll Control Methods Container
//  Created by Roger Vogel on 6/27/20.
//  Copyright © 2020 Roger Vogel. All rights reserved.
//

import UIKit

class VCScrollServices: NSObject {
    
    var contentHeight: CGFloat?
    var lastControl: UIControl?
    var theScrollView: UIScrollView?
    var theparent: VCViewController?
    var theView: UIView?
    var bottomLimit: CGFloat?
    var needsScroll: Bool?
    var initialConstraint: CGFloat?
    var theParent: VCViewController?
    
    // MARK: INITIALIZATION
    
    func initService(scrollView: UIScrollView, parent: VCViewController, view: UIView, height: CGFloat) {
        
        // Set up info from the scrollview's superview
        theScrollView = scrollView
        theParent = parent
        theView = view
        contentHeight = height
        initialConstraint = height
    }
    
    // MARK: METHODS
    
    func accomodateKeyboard (notification: NSNotification) -> CGFloat? {
        
        // Make sure we have a valid notification and if so, get the keyboard size
        guard let userInfo = notification.userInfo else { return nil }
        guard let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return nil}
        
        let keyboardFrame = keyboardSize.cgRectValue
        let keyboardHeight = keyboardFrame.size.height
        theScrollView?.isScrollEnabled = true

        // Return the scroll adjustment necessary to accomodate the keyboard
        return (contentHeight! + keyboardHeight - theParent!.tabBarController!.tabBar.frame.height)
    }
    
    func resetFromKeyboard () -> CGFloat { return initialConstraint! }
}
