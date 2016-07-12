//
//  Log+Describable.swift
//  Slacket
//
//  Created by Bartłomiej Nowak on 12/07/16.
//
//

import Foundation
import LoggerAPI

extension Log {
    
    static func debug(_ errorType: Describable) {
        debug(errorType.description)
    }
    
    static func error(_ errorType: Describable) {
        error(errorType.description)
    }
}