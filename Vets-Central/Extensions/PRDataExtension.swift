//
//  PRDataExtension.swift
//  Starfish Constellation
//
//  Created by Roger Vogel on 2/25/22.
//

import Foundation
import UIKit

extension Data {
    
    var uiImage: UIImage? { UIImage(data: self) }
    
    var bytesAsArray: [UInt8] { return [UInt8](self) }
   
    var hexString: String {
        
        var hexString = ""
        let byteArray = bytesAsArray
        
        for b in byteArray { hexString += String(format: "%02x", b) }
    
        return hexString
    }
    
    var asPrettyJSON: String? {
        
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = String(data: data, encoding: .utf8) else { return nil }

        return prettyPrintedString
    }
    
    func urlSafeBase64EncodedString() -> String {
          
        return   base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
    }
}
