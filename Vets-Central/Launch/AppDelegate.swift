//
//  AppDelegate.swift
//  Vets-Central
//
//  Application Delegate (entry point)
//  Created by Roger Vogel on 5/28/20.
//  Copyright © 2020 Roger Vogel. All rights reserved.  
//

import UIKit

var globalData = VCGlobalData()
var refreshData = VCGlobalData()

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
                
        // Override point for customization after application launch.
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func applicationWillTerminate(_ application: UIApplication) { }
    
    func applicationWillResignActive(_ application: UIApplication) { }
    
    func applicationDidBecomeActive(_ application: UIApplication) { }
      
    func applicationDidEnterBackground(_ application: UIApplication) { }

    func applicationWillEnterForeground(_ application: UIApplication) { }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        
        NSLog("MEMORY WARNING RECEIVED")
        
        // Loop through the pet records
        for var p in globalData.user.pets {
            
            // Delete the local copy of documents associated with the pet, if any
            for m in p.docMetadata { if m.localURL != "" { _ = VCFileServices().deleteFile(name: m.localURL) } }
                
            // Flag that documents are no longer downloaded and clear the metadata
            p.metadataIsDownloaded = false
            p.docMetadata.removeAll()
        }
    }
}


