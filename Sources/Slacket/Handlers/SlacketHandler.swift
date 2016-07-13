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
import When

enum SlacketAction: HandlerAction {

    case addCommand
    case authorizePocket

    static func from(route: String?) -> SlacketAction? {
        guard let route = route else {
            return nil
        }
        switch route {
        case let r where r.startsWith(prefix: SlacketAction.addCommand.route):
            return SlacketAction.addCommand
        case let r where r.startsWith(prefix: SlacketAction.authorizePocket.route):
            return SlacketAction.authorizePocket
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
        }
    }

    var requiredBodyType: ParsedBody? {
        switch self {
        case .addCommand:
            return ParsedBody.urlEncoded([:])
        case .authorizePocket:
            return nil
        }
    }
}

struct SlacketHandler: Handler, RouterMiddleware, ErrorType {

    static let errorDomain = "SlacketUserService"

    func handle(request: RouterRequest, response: RouterResponse, next: () -> Void) {
        Log.debug("\(self.dynamicType.errorDomain) handler")

        guard let action = SlacketAction(request: request) else {
            let error = SlacketError.slacketHandlerActionCouldntInit
            Log.error(error)
            response.error = self.getError(message: error.description)
            next()
            return
        }

        let errorView = ErrorView(response: response)
        let view = SlacketView(response: response)

        switch action {
        case .addCommand:
            if let slackCommand: SlackCommandType = SlackCommandParser.parse(body: request.body) {
                SlacketService.process(request: slackCommand)
                    .done(handler: { slackMessage in
                        view.show(message: slackMessage)
                    }).fail(handler: { error in
                        if let error = error as? Describable {
                            Log.error(error)
                            errorView.error(message: error.description)
                        }
                    })
            } else {
                let error = SlacketError.slacketHandlerCouldntParseCommand
                Log.error(error)
                errorView.error(message: error.description)
                return
            }
        case .authorizePocket:
            PocketAuthorizationHandler().handle(request: request, response: response, next: next)
        }
    }
}