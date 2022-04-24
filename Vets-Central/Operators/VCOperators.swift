//
//  VCOperators.swift
//  Vets-Central
//
//  Created by Roger Vogel on 3/16/22.
//  Copyright © 2022 Roger Vogel. All rights reserved.
//

import Foundation

// MARK: VCDate TIME

infix operator |-|; func |-| (lhs: VCDate, rhs: VCDate) -> UInt64 {
    
    return lhs.dateNumeric - rhs.dateNumeric
}

infix operator |<|; func |<| (lhs: VCDate, rhs: VCDate) -> Bool {
    
    if lhs.dateNumeric < rhs.dateNumeric { return true }
    else { return false }
}

infix operator |>|; func |>| (lhs: VCDate, rhs: VCDate) -> Bool {
    
    if lhs.dateNumeric > rhs.dateNumeric { return true }
    else { return false }
}

infix operator |<=|; func |<=| (lhs: VCDate, rhs: VCDate) -> Bool {
    
    if lhs.dateNumeric <= rhs.dateNumeric { return true }
    else { return false }
}

infix operator |>=|; func |>=| (lhs: VCDate, rhs: VCDate) -> Bool {
  
    if lhs.dateNumeric >= rhs.dateNumeric { return true }
    else { return false }
}

infix operator |=|; func |=| (lhs: VCDate, rhs: VCDate) -> Bool {
    
    if lhs.dateNumeric == rhs.dateNumeric { return true }
    else { return false }
}

infix operator |!=|; func |!=| (lhs: VCDate, rhs: VCDate) -> Bool {
    
    if lhs.dateNumeric != rhs.dateNumeric { return true }
    else { return false }
}

