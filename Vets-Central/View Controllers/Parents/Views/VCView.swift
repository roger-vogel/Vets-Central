//
//  VCView.swift
//  Vets-Central
//
//  VC Base Class adding keyboard, gesture, visibility and message support
//  Created by Roger Vogel on 7/21/20.
//  Copyright © 2020 Roger Vogel. All rights reserved.  
//

import UIKit
 
class VCView: UIView {
    
    // MARK: COMMON OUTLETS
    
    @IBOutlet weak var scrollView: UIScrollView?
    @IBOutlet weak var contentHeight: NSLayoutConstraint?
 
    // MARK: PROPERTIES
    
    var scrollService = VCScrollServices()
    var swipeInForm: UIView?
    var touchPosition: CGPoint?
    var webServices: VCWebServices?
   
    // MARK: COMPUTED PROPERTIES
    
    var parentController: VCViewController { return self.getParentViewController() as! VCViewController }
    
    // MARK: INITIALIZATION
    
    func initView() {
        
        webServices = VCWebServices(parent: parentController)
        
        // Add self as observer of keyboard show and hide notications
        NotificationCenter.default.addObserver(self, selector: #selector( VCView.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector( VCView.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // Setup swipe gesture capture
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        let upSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        let downSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
             
        leftSwipe.direction = .left
        rightSwipe.direction = .right
        upSwipe.direction = .up
        downSwipe.direction = .down
        
        self.addGestureRecognizer(leftSwipe)
        self.addGestureRecognizer(rightSwipe)
        self.addGestureRecognizer(upSwipe)
        self.addGestureRecognizer(downSwipe)
        
        // Initially hide form and set view frame to parent frame
        self.alpha = 0.0
        self.frame = parentController.view.frame
        
        // Setup the scroll service
        if scrollView != nil { scrollService.initService(scrollView: scrollView!, parent: parentController, view: self, height: contentHeight!.constant) }
        
        // Load fields with current data if any
        loadData()
    }
  
    func loadData() { /* Placeholder for subclasses to use*/ }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       
        // Get any non-control touch on the screen
        if let touch = touches.first { touchPosition = touch.location(in: self) }
    }
    
    // MARK: VIEW MANAGEMENT METHODS
    
    func endEditing () { self.endEditing(true) }
    
    func showView(withFade: Bool? = true ) {
        
        parentController.view.bringSubviewToFront(self)
        
        if withFade! { self.changeDisplayState(toState: .visible, withAlpha: 1.0, forDuration: 0.25, atCompletion: { return })}
        else { self.alpha = 1.0;self.isHidden = false }
        
        globalData.activeView = self
    }
        
    func hideView(withFade: Bool? = true) {
        
        if withFade! { self.changeDisplayState(toState: .hidden, forDuration: 0.25, atCompletion: { if self.scrollView != nil {self.scrollView!.scrollsToTop(animated: false) } } ) }
        
        else {
            
            self.alpha = 0.0
            self.isHidden = true
            if self.scrollView != nil {self.scrollView!.scrollsToTop(animated: false) }
        }
    }
    
    // MARK: GESTURE HANDLING METHODS
    
    func swipeInDidOccur (direction: UISwipeGestureRecognizer.Direction) {/* Placeholder for subclasses to use*/ }
    
    @objc func handleSwipes(_ sender: UISwipeGestureRecognizer) { swipeInDidOccur(direction: sender.direction) }
        
    // MARK: KEYBOARD HANDLERS
    
    @objc func dismissKeyboard() { endEditing() }
       
    @objc func keyboardWillShow(notification: NSNotification) {
        
        guard globalData.activeView != nil else { return }
        guard self == globalData.activeView! else { return }
        
        if scrollView != nil {
            
            let accomodation = scrollService.accomodateKeyboard(notification: notification)
       
            guard accomodation != nil else { return }
            contentHeight!.constant = accomodation!
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        
        guard globalData.activeView != nil else { return }
        guard self == globalData.activeView! else { return }
        
        if scrollView != nil { contentHeight!.constant = scrollService.resetFromKeyboard() }
    }
}



