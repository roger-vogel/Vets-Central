//
//  PRExtensions.swift
//  PRP Resiliency Center
//
//  Created by Roger Vogel on 10/9/20.
//

import Foundation
import UIKit

extension Int {
    
    var doubleValue: Double { return Double(self) }
    var boolValue: Bool { if self == 0 { return false } else { return true } }
}

extension Double {
    
    var intValue: Int { return Int(self) }
    var uint64Value: UInt64 { return UInt64(self) }
}

extension Float {
    
    var intValue: Int { return Int(self) }
    var uint64Value: UInt64 { return UInt64(self) }
}

extension CGFloat {
    
    var intValue: Int { return Int(self) }
    var uint64Value: UInt64 { return UInt64(self) }
}

extension Bool { var intValue: Int { return self ? 1 : 0 } }

extension Array {
    
    mutating func removeIndices (indices: [Int]){
        
        var sortedIndices = indices.sorted()
        
        for i in 0..<sortedIndices.count {
            
            self.remove(at: sortedIndices[i])
            if i != sortedIndices.count - 1 { for r in (i + 1)..<sortedIndices.count { sortedIndices[r] -= 1 } }
        }
    }
}


