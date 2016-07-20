//
//  SlackAPIConnector.swift
//  Slacket
//
//  Created by Jakub Tomanik on 03/06/16.
//
//

import Foundation
import Kitura
import HeliumLogger
import LoggerAPI
import SimpleHttpClient
import Promissum

protocol SlackConnectorType {
    
    static func send(message: SlackMessageType, inResponse command: SlackCommandType) -> Promise<Bool>
}

struct SlackApiConnector: SlackConnectorType {
    
    static func send(message: SlackMessageType, inResponse command: SlackCommandType) -> Promise<Bool> {
        
        let source = PromiseSource<Bool>(dispatch: .Synchronous)
        let slackEndpoint = SlackAPI.respond(command: command, message: message)

        slackEndpoint.request { error, status, headers, data in
            guard let status = status else {
                let error = ConnectorError.missingStatus(for: .slack)
                Log.error(error.description)
                source.reject(error: error)
                return
            }
            
            if 200...299 ~= status {
                source.resolve(value: true)
                return
            } else {
                //TODO: ConnectorError.statusNotOk
                let error = ConnectorError.statusNotOk(for: .slack)
                Log.error(error.description)
                source.reject(error: error)
                return
            }
        }
        return source.promise
    }
}