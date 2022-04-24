//
//  VCViewController.swift
//  Vets-Central
//
//  VC Base Class adding gesture support
//  Created by Roger Vogel on 9/17/20.
//  Copyright © 2020 Roger Vogel. All rights reserved.  
//

import UIKit 

class VCViewController: UIViewController, UITabBarControllerDelegate {
    
    // MARK: PROPERTIES
    
    var theSubViews = [VCView]()
    var touchPosition: CGPoint?
    var controllerAlert: VCAlertServices?
    var webServices: VCWebServices?
    var selectedPet: Int?
    var selectedAppointment: Int?
    
    // MARK: COMPUTED PROPERTIES
    
    // Controllers
    var homeController: VCHomeViewController {
        
        let viewControllers = tabBarController!.viewControllers
        return (viewControllers![0] as! VCHomeViewController)
    }
    
    var petController: VCPetViewController {
        
        let viewControllers = tabBarController!.viewControllers
        return (viewControllers![1] as! VCPetViewController)
    }
    
    var clinicController: VCMapViewController {
        
        let viewControllers = tabBarController!.viewControllers
        return (viewControllers![2] as! VCMapViewController)
    }
    
    var appointmentController: VCAppointmentViewController {
        
        let viewControllers = tabBarController!.viewControllers
        return (viewControllers![3] as! VCAppointmentViewController)
    }
    
    var profileController: VCProfileViewController {
        
        let viewControllers = tabBarController!.viewControllers
        return (viewControllers![4] as! VCProfileViewController)
    }
    
    // Tabs
    var homeTab: UITabBarItem {
        
        let tabBarItems = tabBarController!.tabBar.items
        return tabBarItems![0]
    }
    
    var petTab: UITabBarItem {
        
        let tabBarItems = tabBarController!.tabBar.items
        return tabBarItems![1]
    }
    
    var clinicTab: UITabBarItem {
        
        let tabBarItems = tabBarController!.tabBar.items
        return tabBarItems![2]
    }
    
    var appointmentTab: UITabBarItem {
        
        let tabBarItems = tabBarController!.tabBar.items
        return tabBarItems![3]
    }
    
    var profileTab: UITabBarItem {
        
        let tabBarItems = tabBarController!.tabBar.items
        return tabBarItems![4]
    }
    
    // Tab Indices
    var homeIndex: Int { return 0 }

    var petIndex: Int { return 1 }

    var clinicIndex: Int { return 2 }

    var appointmentIndex: Int { return 3 }

    var profileIndex: Int { return 4 }

    // MARK: INITIALIZATION
    
    override func viewDidLoad() { super.viewDidLoad()
        
        tabBarController!.delegate = self
        
        controllerAlert = VCAlertServices(viewController: self)
        webServices = VCWebServices(parent: self)
        
        // Setup swipe gesture capture
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        let upSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        let downSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
             
        leftSwipe.direction = .left
        rightSwipe.direction = .right
        upSwipe.direction = .right
        downSwipe.direction = .right
         
        view.addGestureRecognizer(leftSwipe)
        view.addGestureRecognizer(rightSwipe)
        view.addGestureRecognizer(upSwipe)
        view.addGestureRecognizer(downSwipe)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
       
        view.alpha = 0.0
        view.changeDisplayState(toState: .visible, forDuration: 0.30, atCompletion: { return })
    }
    
    // MARK: METHODS
    
    func setSubViews (subviews: [VCView]) { for v in subviews { theSubViews.append(v); v.isHidden = true } }
    
    func hideSubViews () { for v in theSubViews { v.isHidden = true } }
    
    // MARK: RESERVED FOR SUBBVIEWS
    
    func doLogoutTasks() { /* Placeholder */ }
    
    func onClockChange() { /* Placeholder */ }
    
    // MARK: TAB NAVIGATION
    
    func gotoHome() { tabBarController!.selectedIndex = 0 }
    
    func gotoPets() { tabBarController!.selectedIndex = 1 }
    
    func gotoClinics() {tabBarController!.selectedIndex = 2 }
    
    func gotoAppointments () { tabBarController!.selectedIndex = 3 }
        
    func gotoProfile () {tabBarController!.selectedIndex = 4 }
  
    // MARK: TAB BAR DELEGATE PROTOCOL
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        if viewController is VCAppointmentViewController && globalData.user.pets.count == 0 {
            
            controllerAlert!.popupMessage(aMessage: "Please add your pet before requesting an appointment")
            return false
        }
            
        return true
    }
    
    // MARK: GESTURE HANDLING METHODS
    
    func swipeDidOccur (inDirection: UISwipeGestureRecognizer.Direction) {/* Placeholder for subclasses to use*/ }
    
    // Grab swipe start position and alert subclass
    @objc func handleSwipes(_ sender: UISwipeGestureRecognizer) {
        
        touchPosition = sender.location(in: view)
        swipeDidOccur(inDirection: sender.direction)
    }
}

