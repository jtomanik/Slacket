//
//  SlacketError.swift
//  Slacket
//
//  Created by Bartłomiej Nowak on 11/07/16.
//
//

import Foundation

enum SlacketError: ErrorProtocol, Describable {
    case pocketAuthorization
    case pocketUnknown
    case pocketMissingConsumerKey
    case slackMissingToken
    case slacketHandlerCouldntHandleCommand
    case slacketHandlerCouldntParseCommand
    case slacketHandlerActionCouldntInit
    case slacketServiceNilPocketItem
    case handlerActionCouldntInit
    case slacketUserDeserialization
    case slacketUserSerialization
    
    var description: String {
        switch self {
            case .pocketAuthorization:
                return "Your Pocket account could not be linked because the Pocket server denied authorization"
            case .pocketUnknown:
                return "Something went wrong...</br>and we don't know what :("
            case .pocketMissingConsumerKey:
                return "Cannot find POCKET_CONSUMER_KEY environmental variable"
            case .slackMissingToken:
                return "Cannot find SLACK_TOKEN environmental variable"
            case .slacketHandlerCouldntHandleCommand:
                return "SlacketHandler SlackCommand couldn't be handled"
            case .slacketHandlerCouldntParseCommand:
                return "SlacketHandler SlackCommand couldn't be parsed"
            case .slacketHandlerActionCouldntInit:
                return "SlackedHandler SlacketAction init failed"
            case slacketServiceNilPocketItem:
                return "SlacketService PocketItem is nil"
            case .handlerActionCouldntInit:
                return "HandlerAction init failed"
            case .slacketUserDeserialization:
                return "SlacketUser deserialization error"
            case .slacketUserSerialization:
                return "SlacketUser serialization error"
        }
    }
}