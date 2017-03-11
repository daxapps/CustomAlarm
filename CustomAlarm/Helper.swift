//
//  Helper.swift
//  CustomAlarm
//
//  Created by Jason Crawford on 3/11/17.
//  Copyright © 2017 Jason Crawford. All rights reserved.
//

import Foundation

struct Helper {
    
    static func getDocumentsDirectory() -> URL {
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        let documentsDirectory = paths[0]
        
        return documentsDirectory
        
    }
}
