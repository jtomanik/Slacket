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
import When

protocol SlackConnectorType {
    
    static func send(message: SlackMessageType, inResponse command: SlackCommandType) -> Promise<Bool>
}

struct SlackApiConnector: SlackConnectorType {
    
    static func send(message: SlackMessageType, inResponse command: SlackCommandType) -> Promise<Bool> {
        
        let promise = Promise<Bool>()
        let slackEndpoint = SlackAPI.respond(command: command, message: message)

        slackEndpoint.request { error, status, headers, data in
            guard let status = status else {
                let error = ConnectorError.missingStatus(for: .slack)
                Log.error(error.description)
                promise.reject(error: error)
                return
            }
            
            if 200...299 ~= status {
                promise.resolve(value: true)
                return
            } else {
                //TODO: ConnectorError.statusNotOk
                let error = ConnectorError.statusNotOk(for: .slack)
                Log.error(error.description)
                promise.reject(error: error)
                return
            }
        }
        return promise
    }
}