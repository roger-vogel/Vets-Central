//
//  PRNavigationControlExtension.swift
//  Starfish Constellation
//
//  Created by Roger Vogel on 2/25/22.
//

import Foundation
import UIKit

extension UINavigationController {
    
    func addCustomBackButton(title: String = "Back") {
        
        let backButton = UIBarButtonItem()
        backButton.title = title
        navigationBar.topItem!.backBarButtonItem = backButton
    }
}
