//
//  VCHomeViewController.swift
//  Vets-Central
//
//  Home Scene Controller and Subviews
//  Created by Roger Vogel on 5/28/20.
//  Copyright © 2020 Roger Vogel. All rights reserved.

import UIKit
import MapKit
import Network

class VCHomeViewController: VCViewController { 
    
    // MARK: OUTLETS
    
    @IBOutlet var loginFormView: VCLoginFormView!
    @IBOutlet var messagesFormView: VCMessageFormView!
    @IBOutlet var messageReaderView: VCMessageReaderView!
    @IBOutlet var homeSettingsView: VCHomeSettingsView!
    
    @IBOutlet weak var messageBadgeButton: UIButton!
    @IBOutlet weak var messageAlertButton: UIButton!
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var scheduledApptLabel: UILabel!
    @IBOutlet weak var scheduledApptButton: UIButton!
    @IBOutlet weak var credentialsButton: UIButton!
 
    @IBOutlet weak var loginActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loginMessageLabel: UILabel!

    @IBOutlet weak var settingsButton: UIButton! 
    @IBOutlet weak var buildNumberTextField: UILabel!
    
    // MARK: PROPERTIES 
    
    var petCounter: Int = 0
    var clinicCounter: Int = 0
    var vcLogin: VCLoginServices?
    var vcRefresh: VCRefreshServices?
    var vcEvents: VCEventServices?
    var notesAreLoaded: Bool = false
    var savedUser: String?
   
    // MARK: INITIALIZATION
    
    override func viewDidLoad() { super.viewDidLoad()
        
        buildNumberTextField.text = VCSystemInfo().buildLevel
      
        VCKeychainServices().readKeychain()
        savedUser = globalData.user.data.userEmail
        
        tabBarController!.tabBar.backgroundColor = .white
        setSubViews(subviews: [loginFormView,messagesFormView,messageReaderView])
        
        // Set up the login/logout page button
        credentialsButton.setBorder(width: 1.0, color: CGColor.init(srgbRed: 0.75, green: 0.75, blue: 0.75, alpha: 1.0))
        credentialsButton.roundAllCorners(value: 10.0)
        
        scheduledApptButton.setBorder(width: 0.5, color: UIColor.lightGray.cgColor)
        scheduledApptButton.roundAllCorners(value: 5)
        scheduledApptButton.isHidden = true
        scheduledApptLabel.text!.removeAll()
        
        // Set up the login page view
        view.addSubview(loginFormView)
        loginFormView.initView()
        
        // Set up the notes view
        view.addSubview(messagesFormView)
        messagesFormView.initView()
        
        // Set up the notes view
        view.addSubview(messageReaderView)
        messageReaderView.initView()
        
        // Set up the settings view
        view.addSubview(homeSettingsView)
        homeSettingsView.initView()
        
        // Initialize the user feedback items
        loginActivityIndicator.isHidden = true
        loginMessageLabel.isHidden = true
        loginMessageLabel.sizeToFit()
        
        messageBadgeButton.roundAllCorners(value: messageBadgeButton.frame.height/2)
        messageBadgeButton!.isHidden = true
   
        // Instantiate classes for login and background refresh
        vcLogin = VCLoginServices(parent: self)
        vcRefresh = VCRefreshServices(parent: self)
        vcEvents = VCEventServices(parent: self)
        globalData.messageService.setParent(parent: self)
        
        credentialsButton.alpha = 0.0
        setBadges(clear: true)
        
        globalData.homeController = self
        
        globalData.flags.loginState = LoginState.bootUp
        enableTabs()
    }
        
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated)

        if globalData.flags.loginState == .loggedIn || globalData.flags.loginState == .awaitingLogin {loginActivityIndicator.isHidden = true }
        else { loginActivityIndicator.isHidden = false }
      
        globalData.activeController = self
        if globalData.flags.loginState == .loggedIn { setHomePageUIElements() }
        
        hideSubViews()
    }
    
    override func viewDidAppear(_ animated: Bool) { super.viewDidAppear(animated)
              
        // Set the initial state of the message alert
        if globalData.flags.loginState == .loggedIn {
            
            messageAlertButton.isEnabled = true
            settingsButton.isEnabled = true
            messageAlertButton.changeDisplayState(toState: .visible, withAlpha: 1.0, forDuration: 0.25, atCompletion: { return })
            settingsButton.changeDisplayState(toState: .visible, withAlpha: 1.0, forDuration: 0.25, atCompletion: { return })
            
        }
        else {
            
            messageAlertButton.isEnabled = false
            settingsButton.isEnabled = false
            messageAlertButton.changeDisplayState(toState: .dimmed, withAlpha: 0.30, forDuration: 0.25, atCompletion: { return })
            settingsButton.changeDisplayState(toState: .dimmed, withAlpha: 0.30, forDuration: 0.25, atCompletion: { return })
        }
        
        // Get the list of nearby VC clinics if we don't already have it
        if globalData.clinics.count == 0 && globalData.flags.loginState == LoginState.bootUp { vcLogin!.preload(isReLogin: false) }
    }
    
    override func viewWillDisappear(_ animated: Bool) { super.viewWillDisappear(animated); loginActivityIndicator.isHidden = true }
    
    override func onClockChange() {
        
        showUpcomingAppointments()
       
        petController.onClockChange()
        clinicController.onClockChange()
        appointmentController.onClockChange()
        profileController.onClockChange()
    }
    
    // MARK: METHODS
    
    func showUpcomingAppointments() {
        
        var nextAppointmentDate = VCDate()
        var firstElement = true
    
        if globalData.user.currentAppointments.count == 0 { scheduledApptLabel.text = "You have no appointments scheduled" }
        
        else {
            
            for appt in globalData.user.currentAppointments {
                
                if firstElement {
                    
                    nextAppointmentDate = appt.startDate
                    firstElement = false
                    
                } else { if appt.startDate.theDate! < nextAppointmentDate.theDate! { nextAppointmentDate = appt.startDate } }
            }
       
            if nextAppointmentDate |>| VCDate(date: Date().addingTimeInterval(600)) {
                
                scheduledApptLabel.text = "  Your next appointment is scheduled for " + nextAppointmentDate.dateAndTimeString
            
            } else {
                
                scheduledApptLabel.text = "  You had an appointment at " + nextAppointmentDate.dateAndTimeString + ". The telvet conference may still be available."}
        }   
    }
  
    func setHomePageUIElements () {
        
        // At the home view activity indicator and message label are hidden
        loginActivityIndicator.isHidden = true
        loginMessageLabel.isHidden = true
      
        // If we've arrived here from a login
        if globalData.flags.loginState == .loggedIn {
        
            // Set the button to logout since we're logged in
            credentialsButton.setTitle("LOGOUT", for: .normal)
          
            // Prepare the welcome message
            let welcomeName = globalData.user.data.givenName
            
            if welcomeName != "" { welcomeLabel.text = "Hi " + welcomeName + ". Welcome to Vets-Central!" }
            else { welcomeLabel.text = "Welcome to Vets-Central!" }
            
            welcomeLabel.sizeToFit()
            
            // Display the welcome message, login button, and alerts
            messageAlertButton.changeDisplayState(toState: .visible, forDuration: 0.25, atCompletion: {return})
            settingsButton.changeDisplayState(toState: .visible, forDuration: 0.25, atCompletion: {return})
            setBadges()
            globalData.messageService.setMessageBadge()
            
            credentialsButton.isHidden = false
            scheduledApptButton.isHidden = false
            
            showUpcomingAppointments()
        }
        
        // Otherwise logout actions
        else  {
            
            // Clear alerts and messages, dim out the message alert
            setBadges()
            messageBadgeButton.isHidden = true
            messageAlertButton.changeDisplayState(toState: .dimmed, withAlpha: 0.30, forDuration: 0.25, atCompletion: { return })
            settingsButton.changeDisplayState(toState: .dimmed, withAlpha: 0.30, forDuration: 0.25, atCompletion: { return })
           
            // Clear welcome message and reset button
            welcomeLabel.text = ""
            credentialsButton.setTitle("  LOGIN | REGISTER", for: .normal)
            globalData.flags.loginState = .awaitingLogin
            
            // Clear scheduled appointment info
            scheduledApptLabel.text!.removeAll()
            scheduledApptButton.isHidden = true
        }
        
        // Fade the welcome text in and show the button
        welcomeLabel.changeDisplayState(toState: .visible, forDuration: 0.25, atCompletion: {return} )
        credentialsButton.changeDisplayState(toState: .visible, forDuration: 0.25, atCompletion: {return})
    }
    
    func setTabBarMessageBadge (theCount: Int? = 0) {
        
        if theCount == 0 { tabBarController!.tabBar.items![homeIndex].badgeValue = nil }
        else { tabBarController!.tabBar.items![homeIndex].badgeValue = String(format: "%d", theCount!) }
    }
    
    func setBadges(clear: Bool? = false) {
        
        let tabBarItems = tabBarController!.tabBar.items
        
        guard !globalData.settings.recordCountsAreHidden else { for t in 1...3 { tabBarItems![t].badgeValue = nil }; return }
            
        for t in 1...3 { tabBarItems![t].badgeColor = UIColor.init(displayP3Red: 0, green: 176/255, blue: 80/255, alpha: 1.0) }
        
        if clear! || globalData.user.pets.count == 0 { tabBarItems![1].badgeValue = nil } else { tabBarItems![1].badgeValue = String(globalData.user.pets.count)}
        if clear! || globalData.user.currentAppointments.count == 0 { tabBarItems![3].badgeValue = nil } else { tabBarItems![3].badgeValue = String(globalData.user.currentAppointments.count) }
        
        let nearbyClinics = globalData.numClinicsNearUser()
        if nearbyClinics == 0 { tabBarItems![2].badgeValue = nil } else { tabBarItems![2].badgeValue = String(nearbyClinics) }
        
    }

    func enableTabs() {
        
        let tabBarItems = tabBarController!.tabBar.items
        
        if globalData.flags.loginState != .loggedIn {
            
            tabBarItems![0].isEnabled = true
            tabBarItems![1].isEnabled = false
           
            tabBarItems![3].isEnabled = false
            tabBarItems![4].isEnabled = false
            
            let status = CLLocationManager().authorizationStatus
            if status == .authorizedAlways || status == .authorizedWhenInUse  { tabBarItems![2].isEnabled = true } else { tabBarItems![2].isEnabled = false }
        }
        
        else {
            
            tabBarItems![0].isEnabled = true
            tabBarItems![1].isEnabled = true
          
            tabBarItems![4].isEnabled = true
            
            let status = CLLocationManager().authorizationStatus
            if status == .authorizedAlways || status == .authorizedWhenInUse  { tabBarItems![2].isEnabled = true; tabBarItems![3].isEnabled = true } else { tabBarItems![2].isEnabled = false; tabBarItems![3].isEnabled = false }
        }
    }
    
    // MARK: ACTION HANDLERS
    
    @IBAction func messageAlertButtonTapped(_ sender: Any) { messagesFormView.messagesTableView.reloadData(); messagesFormView.showView() }
        
    @IBAction func settingsButtonTapped(_ sender: Any) { homeSettingsView.initControls(); homeSettingsView.showView() }
    
    @IBAction func loginPageButtonTapped(_ sender: Any) {
  
        // If logged in this tap is to now logout
        if globalData.flags.loginState == .loggedIn {
            
            VCAlertServices(viewController: self).popupYesNo(aMessage: "Are you sure you want to logout?", aStyle: [.destructive,.default]) { choice in
                
                if choice == 0 {
                    
                    globalData.stopTimers()
                    globalData.flags.loginState = .loggedOut
                    
                    if !globalData.webServiceQueue.isEmpty { for t in globalData.webServiceQueue { t.dataTask!.cancel() } }
                    if !globalData.settings.rememberMe { self.loginFormView.clear() } else { self.loginFormView.confirmationTextField.text = "" }
                    
                    self.credentialsButton.changeDisplayState(toState: .hidden, forDuration: 0.1, atCompletion: { return } )
                    self.loginActivityIndicator.isHidden = false
                    self.loginMessageLabel.text = "LOGGING OUT"
                    self.loginMessageLabel.isHidden = false
                    self.loginFormView.setPasswordSecurity(true)
                    
                    self.loginFormView.hideView()
                    self.messageReaderView.hideView()
                    self.messagesFormView.hideView()
                    self.homeSettingsView.hideView()
                    
                    globalData.messageService.setMessageBadge(setToZero: true)
                 
                    VCWebServices(parent: self).logout() { (json, webServiceSuccess) in
                        
                        globalData.reinit()
                        
                        self.petController.doLogoutTasks()
                        self.clinicController.doLogoutTasks()
                        self.appointmentController.doLogoutTasks()
                        self.profileController.doLogoutTasks()
                        
                        self.enableTabs()
                        self.setHomePageUIElements()
                    }
                }
            }
        }
       
        // Else bring up the login form
        else {
        
            loginFormView.loadData()
            loginFormView.showView()
            credentialsButton.alpha = 0.0
        }
    }
    
    @IBAction func scheduledApptButtonTapped(_ sender: Any) { gotoAppointments() }
    
    // MARK: FOR TESTING
    
    func clearKeychain () {
        
        VCKeychainServices().clearKeychain()
        exit(1)
    }
}
 
 
