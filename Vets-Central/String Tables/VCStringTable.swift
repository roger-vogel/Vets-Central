//
//  VCStringTable.swift
//  Vets-Central
//
//  Created by Roger Vogel on 12/21/20.
//  Copyright © 2020 Roger Vogel. All rights reserved.
//

import UIKit

class VCStringTable: NSObject {
    
    var stringTable = [String: VCLanguage]()
    
    override init() { super.init()
        
        stringTable["logout"] = VCLanguage(en: "LOGGING OUT", ch: "", he: "")
        
        
        
    }

}
