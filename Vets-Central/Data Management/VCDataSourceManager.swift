//
//  VCDataSourceManager.swift
//  Vets-Central
//
//  Created by Roger Vogel on 2/26/22.
//  Copyright © 2022 Roger Vogel. All rights reserved.
//

import UIKit

class VCDataSourceMapper: NSObject {
    
    // MARK: PROPERTIES
    
    var offset: Int?
    var offsetTitles: [String]?
    var titleCache: [String]?
    var showTitles: Bool?
    var titlesAreCached: Bool = false
       
    // MARK: INITIALIZATION
    
    init (theOffsetTitles: [String], showOffsetTitles: Bool? = true) { super.init()
        
        offset = theOffsetTitles.count
        titleCache = theOffsetTitles
        showTitles = showOffsetTitles
    }
    
    // MARK: METHODS
    
    func count(forRootSource: [Any]) -> Int { return (forRootSource.count + offset!) }
    
    func title(forIndex: Int) -> String { if titlesAreCached { return titleCache![forIndex] } else { return "" } }
            
    func getRootIndex(forDataSourceIndex: Int) -> Int? {
        
        guard forDataSourceIndex >= offset! else { return nil }
        return forDataSourceIndex - offset!
    }
    
    func getDataSourceIndex(forRootIndex: Int) -> Int { return forRootIndex + offset! }
     
    func cacheTitles (forIndex: Int, title: String) {  titleCache!.insert(title, at: forIndex + offset!); titlesAreCached = true }
}
