//
//  VCDataValidator.swift
//  Vets-Central
//
//  Created by Roger Vogel on 2/26/22.
//  Copyright © 2022 Roger Vogel. All rights reserved.
//

import UIKit

class VCDataValidator: NSObject {
    
    // MARK: METHODS
    
    func isValidEmail (emailToTest: String) -> Bool {
        
        guard emailToTest != "" else { return false }
        
        let regEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let pred = NSPredicate(format:"SELF MATCHES %@", regEx)
        
        return pred.evaluate(with: emailToTest)
    }
    
    func isValidPassword (passwordToTest: String) -> Bool {
        
        guard passwordToTest != "" else { return true }
        
        let regEx = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[d$@$!%*?&#()])[A-Za-z\\dd$@$!%*?&#]{8,}"
        let pred = NSPredicate(format:"SELF MATCHES %@", regEx)
        
        return pred.evaluate(with: passwordToTest)
    }

}
