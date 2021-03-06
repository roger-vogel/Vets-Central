//
//  SceneDelegate.swift
//  Vets-Central
//
//  Created by Roger Vogel on 5/28/20.
//  Copyright © 2020 Roger Vogel. All rights reserved. 
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        
        if globalData.flags.loginState == .loggedIn { globalData.resumeWebServices() }
        if globalData.conferenceInProgress { globalData.resumeVideoConference() }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        
        if globalData.flags.loginState == .loggedIn { globalData.pauseWebservices() }
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        
        if globalData.flags.loginState == .loggedIn { globalData.resumeWebServices() }
        if globalData.conferenceInProgress { globalData.resumeVideoConference() }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        
        if globalData.flags.loginState == .loggedIn { globalData.pauseWebservices() }
    }
}
