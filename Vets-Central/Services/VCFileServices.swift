//
//  VCFileServices.swift
//  Vets-Central
//
//  Created by Roger Vogel on 9/2/20.
//  Copyright © 2020 Roger Vogel. All rights reserved.
//

import UIKit

class VCFileServices: NSObject {
    
    // MARK: METHODS
    
    func getDocumentsDirectory() -> URL {  return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] }

    func createFile(theContents: Data, name: String) -> String? {
        
        var writeStatus: Bool?
        let urlPath = getDocumentsDirectory()
        let path = urlPath.path + "/" + name
        
        writeStatus = FileManager().createFile(atPath: path, contents: theContents)
       
        if writeStatus! { return path } else { return nil }
        
    }
    
    func deleteFile (name: String) -> Bool {
        
        let urlPath = getDocumentsDirectory()
        _ = urlPath.appendingPathComponent(name)
        
        do { try FileManager().removeItem(atPath: urlPath.absoluteString) }
        catch { NSLog(error.localizedDescription); return false }

        return true
    }
 
    func createDirectory(name: String) -> String? {
        
        let urlPath = getDocumentsDirectory()
        _ = urlPath.appendingPathComponent(name)
        let path = urlPath.absoluteString
        
        do { try FileManager().createDirectory(atPath: path, withIntermediateDirectories: false) }
        catch { return nil }
       
        return path
    }
    
    func readFile(fullPath: String) -> Data? {
        
        let fileContents: Data?
        let handle = FileHandle(forReadingAtPath: fullPath)
    
        do { try fileContents = handle?.readToEnd() }
        catch { return nil }
        
        return fileContents
    }
    
    func getFileExtension(fileName: String ) -> String? {
        
        let pathComponents = fileName.split(separator: ".")
        return String(pathComponents.last!)
    }
}


