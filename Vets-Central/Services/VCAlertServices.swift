//
//  VCAlert.swift
//  Vets Central
//
//  Created by Roger Vogel on 10/24/21.
//

import UIKit

class VCAlertServices: NSObject {
    
    // MARK: PROPERTIES
    
    var theViewController: UIViewController?
    var thisAlert: UIAlertController?
    var textFieldInitParams: VCAlertTextFieldInit?
    var indicator: UIActivityIndicatorView?
    var progressBar: UIProgressView?
    
    // MARK: COMPUTED PROPERTIES
    
    var theTitle: String {
        
        get {  return thisAlert!.title! }
        set { thisAlert!.title = newValue }
    }
    
    var theMessage: String {
        
        get {  return thisAlert!.message! }
        set { thisAlert!.message = newValue }
    }
    
    var isDismissed: Bool {
        
        if thisAlert == nil { return true }
        else { return false }
    }
        
    // MARK: INITIALIZATION
    
    init(viewController: UIViewController) {
        
        super.init()
        theViewController = viewController
    }

    // MARK: POPUP OK
    
    func popupOK (aTitle: String? = "", aMessage: String? = "") { popupWithCustomButton(aTitle: aTitle!, aMessage: aMessage!, buttonTitle: "OK", theStyle: .default) }

    func popupOK (aTitle: String? = "",  aMessage: String? = "", callBack: @escaping () -> Void ) { popupWithCustomButton(aTitle: aTitle!, aMessage: aMessage!, buttonTitle: "OK", theStyle: .default, callBack: callBack) }

    // MARK: POPUP CANCEL
    
    func popupCancel (aTitle: String? = "",  aMessage: String? = "", callBack: @escaping () -> Void ) { popupWithCustomButton(aTitle: aTitle!, aMessage: aMessage!, buttonTitle: "Cancel", theStyle: .default, callBack: callBack)}
    
    // MARK: POPUP QUESTIONS
    
    func popupOKCancel (aTitle: String? = "",  aMessage: String? = "", callBack: @escaping (Int) -> Void ) {
        
        popupWithCustomButtons(aTitle: aTitle!, aMessage: aMessage!, buttonTitles: ["OK","Cancel"], theStyle: [.default,.cancel], callBack: callBack)
    }
    
    func popupYesNo (aTitle: String? = "", aMessage: String, aStyle: [UIAlertAction.Style]? = [.default,.destructive], callBack: @escaping (Int) -> Void ) {
        
        popupWithCustomButtons(aTitle: aTitle!, aMessage: aMessage, buttonTitles: ["Yes","No"], theStyle: aStyle!, callBack: callBack)
    }
    
    // MARK: POPUP WITH ACTIVITY INDICATOR
    
    func popupPendingMsg (aTitle: String? = "", aMessage: String, withProgressBar: Bool? = false) {
        
        if thisAlert != nil { dismiss() }
        
        let messageFont = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13)]
        let messageAttrString = NSMutableAttributedString(string: aMessage + "\n\n", attributes: messageFont)
        
        thisAlert = UIAlertController(title: aTitle!, message: "", preferredStyle: .alert)
        thisAlert!.setValue(messageAttrString, forKey:"attributedMessage")
       
        if withProgressBar! { setupProgressIndicator() }
        else { setupPendingIndicator()}
      
        self.theViewController!.present(self.thisAlert!, animated: true, completion: nil)
    }
    
    func popupPendingMsg (aTitle: String? = "", aMessage: String, buttonTitles: [String], aStyle: [UIAlertAction.Style], withProgressBar: Bool? = false, callBack: @escaping (Int) -> Void) {
        
        if thisAlert != nil { dismiss() }
        
        let messageFont = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13)]
        let messageAttrString = NSMutableAttributedString(string: aMessage + "\n\n", attributes: messageFont)
        
        thisAlert = UIAlertController(title: aTitle!, message: "", preferredStyle: .alert)
        thisAlert!.setValue(messageAttrString, forKey:"attributedMessage")
       
        if withProgressBar! { setupProgressIndicator() }
        else { setupPendingIndicator()}
        
        for (index,title) in buttonTitles.enumerated() {
            
            self.thisAlert!.addAction(UIAlertAction(title: title, style: aStyle[index], handler: { action in DispatchQueue.main.async(execute: { () -> Void in callBack(index) } ) } ) )
        }
     
        self.theViewController!.present(self.thisAlert!, animated: true, completion: nil)
    }
    
    func popupPendingCancel (aTitle: String? = "", aMessage: String, withProgressBar: Bool? = false, callBack: @escaping () -> Void) {
        
        if thisAlert != nil { dismiss() }
        
        let messageFont = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13)]
        let messageAttrString = NSMutableAttributedString(string: aMessage + "\n\n", attributes: messageFont)
        
        thisAlert = UIAlertController(title: aTitle!, message: "", preferredStyle: .alert)
        thisAlert!.setValue(messageAttrString, forKey:"attributedMessage")
       
        if withProgressBar! { setupProgressIndicator() }
        else { setupPendingIndicator()}
        
        self.thisAlert!.addAction(UIAlertAction(title: "CANCEL", style: .destructive, handler: { action in DispatchQueue.main.async(execute: { () -> Void in callBack() } ) } ) )
        self.theViewController!.present(self.thisAlert!, animated: true, completion: nil)
    }
    
    // MARK: POPUP WITH TEXTFIELD
    
    func popupWithTextField (aTitle: String? = "", aMessage: String, aPlaceholder: String, aDefault: String, buttonTitles: [String], aStyle: [UIAlertAction.Style], callBack: @escaping (Int,String) -> Void ) {
        
        if thisAlert != nil { dismiss() }
        
        thisAlert = UIAlertController(title: aTitle!, message: aMessage, preferredStyle: .alert)
        textFieldInitParams = VCAlertTextFieldInit(placeHolder: aPlaceholder, defaultText: aDefault)
        
        for (index,title) in buttonTitles.enumerated() {
            
            self.thisAlert!.addAction(UIAlertAction(title: title, style: aStyle[index], handler: { action in DispatchQueue.main.async(execute: { () -> Void in callBack(index,self.thisAlert!.textFields!.first!.text!) } ) } ) )
        }
        
        self.thisAlert!.addTextField(configurationHandler: { (theTextField) in
            
            theTextField.placeholder = self.textFieldInitParams!.placeHolder
            theTextField.text = self.textFieldInitParams!.defaultText
            theTextField.autocapitalizationType = .sentences
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            
            self.theViewController!.present(self.thisAlert!, animated: true, completion: nil)
        })
    }
    
    // MARK: POPUP WITH CUSTOM BUTTON(S)
    
    func popupWithCustomButton (aTitle: String? = "", aMessage: String, buttonTitle: String, theStyle: UIAlertAction.Style) {
        
        if thisAlert != nil { dismiss() }
        
        thisAlert = UIAlertController(title: aTitle!, message: aMessage, preferredStyle: .actionSheet)
        thisAlert!.addAction(UIAlertAction(title: buttonTitle, style: theStyle, handler: { action in return } ) )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            
            self.theViewController!.present(self.thisAlert!, animated: true, completion: nil)
        })
    }
    
    func popupWithCustomButton (aTitle: String? = "", aMessage: String, buttonTitle: String, theStyle: UIAlertAction.Style, callBack: @escaping () -> Void ) {
        
        if thisAlert != nil { dismiss() }
        
        thisAlert = UIAlertController(title: aTitle!, message: aMessage, preferredStyle: .actionSheet)
        thisAlert!.addAction(UIAlertAction(title: buttonTitle, style: theStyle, handler: { action in DispatchQueue.main.async(execute: { () -> Void in callBack() } ) } ) )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            
            self.theViewController!.present(self.thisAlert!, animated: true, completion: nil)
        })
    }
    
    func popupWithCustomButtons (aTitle: String? = "", aMessage: String, buttonTitles: [String], theStyle: [UIAlertAction.Style], callBack: @escaping (Int) -> Void) {
        
        if thisAlert != nil { dismiss() }
    
        thisAlert = UIAlertController(title: aTitle!, message: aMessage, preferredStyle: .actionSheet)
        
        for (index,title) in buttonTitles.enumerated() {
            
            thisAlert!.addAction(UIAlertAction(title: title, style: theStyle[index], handler: { action in DispatchQueue.main.async(execute: { () -> Void in callBack(index) } ) } ) )
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            
            self.theViewController!.present(self.thisAlert!, animated: true, completion: nil)
        })
    }
    
    // MARK: POPUP MESSAGE
    
    func popupMessage (aTitle: String? = "", aMessage: String, aViewDelay: TimeInterval? = 2.0) {
        
        if thisAlert != nil { dismiss() }
        thisAlert = UIAlertController(title: aTitle!, message: aMessage, preferredStyle: .actionSheet)
       
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            
            self.theViewController!.present(self.thisAlert!, animated: true, completion: { self.dismissWithDelay(wait: aViewDelay!) })
        })
    }
    
    func popupMessage (aTitle: String? = "", aMessage: String, aViewDelay: TimeInterval? = 2.0, callBack: @escaping () -> Void ) {
        
        if thisAlert != nil { dismiss() }
        thisAlert = UIAlertController(title: aTitle!, message: aMessage, preferredStyle: .actionSheet)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            
            self.theViewController!.present(self.thisAlert!, animated: true, completion: { self.dismissWithDelay(wait: aViewDelay!, aCallBack: callBack) })
        })
    }
    
    // MARK: DISMISS ALERT
    
    func dismiss() {
        
        if self.thisAlert != nil {
            
            self.progressBar = nil
            self.thisAlert!.dismiss(animated: true, completion: nil)
            self.thisAlert = nil
        }
    }
    
    func dismissWithDelay(wait: TimeInterval? = 2.0) { DispatchQueue.main.asyncAfter(deadline: .now() + wait!, execute: { self.dismiss() }) }
  
    func dismissWithDelay(wait: TimeInterval? = 2.0, aCallBack: @escaping () -> Void ) { DispatchQueue.main.asyncAfter(deadline: .now() + wait!, execute: { aCallBack(); self.dismiss() }) }
    
    func setProgressBar(value: Float) { progressBar?.setProgress(value, animated: true) }
    
    // MARK: INTERNAL USE ONLY
    
    private func setupPendingIndicator() {
     
        indicator = UIActivityIndicatorView(frame: self.thisAlert!.view.bounds)
        indicator!.color = .black
        indicator!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        indicator!.frame.origin.y = (self.thisAlert!.view.bounds.height/2 - indicator!.frame.height/2) + 10
        
        // Add the activity indicator as a subview of the alert controller's view
        thisAlert!.view.addSubview(indicator!)
        indicator!.isUserInteractionEnabled = false
        indicator!.startAnimating()
        indicator!.isHidden = false
    }
    
    private func setupProgressIndicator() {
        
        progressBar = UIProgressView(frame: self.thisAlert!.view.bounds)
        progressBar!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      
        progressBar!.frame.origin.y += 50
        progressBar!.frame.origin.x += 20
        progressBar!.frame.size.width -= 40
        progressBar!.setProgress(0, animated: true)
        
        // Add the activity indicator as a subview of the alert controller's view
        thisAlert!.view.addSubview(progressBar!)
        progressBar!.isHidden = false
    }
}
