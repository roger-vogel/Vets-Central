//
//  PRPickerViewExtension.swift
//  Starfish Constellation
//
//  Created by Roger Vogel on 2/25/22.
//

import Foundation
import UIKit

extension UIPickerView {
    
    func setRow(forKey: String, inData: [String], forComponent: Int? = 0) -> Bool {
        
        guard !forKey.isEmpty && !inData.isEmpty else { return false }
   
        for (index,value) in inData.enumerated() {
            
            if forKey == value {
                
                self.selectRow(index, inComponent: forComponent!, animated: false)
                return true
            }
        }
        
        return false
    }
}
