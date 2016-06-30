//
//  SlackHandler.swift
//  Slacket
//
//  Created by Jakub Tomanik on 01/06/16.
//
//

import Foundation

import Kitura
import HeliumLogger
import LoggerAPI

enum SlacketAction: HandlerAction {
    
    case addCommand
    case authorizePocket
    case test
    
    static func from(route: String?) -> SlacketAction? {
        guard let route = route else {
            return nil
        }
        switch route {
        case let r where r.startsWith(prefix: SlacketAction.addCommand.route):
            return SlacketAction.addCommand
        case let r where r.startsWith(prefix: SlacketAction.authorizePocket.route):
            return SlacketAction.authorizePocket
        case let r where r.startsWith(prefix: SlacketAction.test.route):
            return SlacketAction.test
        default:
            return nil
        }
    }

    var path: String {
        switch self {
        case .addCommand:
            return "api/v1/slack"
        case .authorizePocket:
            return "api/v1/authorize"
        case .test:
            return "api/v1/test"
        }
    }
    
    var route: String {
        return "/" + self.path
    }
    
    var method: RouterMethod {
        switch self {
        case .addCommand:
            return .post
        case .authorizePocket:
            return .get
        case .test:
            return .get
        }
    }
    
    var requiredBodyType: ParsedBody? {
        switch self {
        case .addCommand:
            return ParsedBody.urlEncoded([:])
        case .authorizePocket:
            return nil
        case .test:
            return nil
        }
    }
}

struct SlacketHandler: Handler, RouterMiddleware, ErrorType {
    
    static let errorDomain = "SlacketUserService"
    
    func handle(request: RouterRequest, response: RouterResponse, next: () -> Void) {
        Log.debug("\(self.dynamicType.errorDomain) handler")
        
        guard let action = SlacketAction(request: request) else {
                let errorMessage = "Preconditions not met"
                Log.error(errorMessage)
                response.error = self.getError(message: errorMessage)
                next()
                return
        }
        
        switch action {
        case .addCommand:
            let view = SlacketView(response: response)
            if let slackCommand: SlackCommandType = SlackCommandParser.parse(body: request.body) {
                SlacketService.process(request: slackCommand) { slackMessage in
                    view.show(message: slackMessage)
                }
            }
            
        case .authorizePocket:
            PocketAuthorizationHandler().handle(request: request, response: response, next: next)

        case .test:
            request.replaceParsedUrl(url: "/index.html", matchedPath: "/")
            let staticServer = StaticFileServer(path: repoDirectory+"public/")
            staticServer.handle(request: request, response: response, next: next)
        }
    }
}