//
//  PocketAuthorizationHandler.swift
//  Slacket
//
//  Created by Jakub Tomanik on 03/06/16.
//
//

import Foundation

import Kitura
import HeliumLogger
import LoggerAPI
import Promissum

enum PocketAuthorizationAction: HandlerAction {

    case authorizationRequest
    case accessTokenRequest
    case authorizationTest

    static func from(route: String?) -> PocketAuthorizationAction? {
        guard let route = route else {
            Log.error(ConnectorError.pocketAuthorizationActionNilRoute)
            return nil
        }
        switch route {
        case let r where r.startsWith(prefix: PocketAuthorizationAction.authorizationRequest.route):
            return PocketAuthorizationAction.authorizationRequest
        case let r where r.startsWith(prefix: PocketAuthorizationAction.accessTokenRequest.route):
            return PocketAuthorizationAction.accessTokenRequest
        case let r where r.startsWith(prefix: PocketAuthorizationAction.authorizationTest.route):
            return PocketAuthorizationAction.authorizationTest
        default:
            Log.debug(ConnectorError.pocketAuthorizationActionUnsupportedRoute)
            return nil
        }
    }

    var path: String {
        switch self {
        case .authorizationRequest:
            return SlacketAction.authorizePocket.path + "/request"
        case .accessTokenRequest:
            return SlacketAction.authorizePocket.path + "/respond"
        case .authorizationTest:
            return SlacketAction.authorizePocket.path + "/test"
        }
    }

    var route: String {
        return "/" + self.path
    }

    var method: RouterMethod {
        return .get
    }

    var requiredQueryParameters: [String]? {
        switch self {
        case .authorizationRequest:
            return ["user", "team"]
        case .accessTokenRequest:
            return ["user", "team"]
        case .authorizationTest:
            return nil
        }
    }

    func redirectUrl(user: SlacketUserType) -> String {
        return "\(ExternalServerConfig().baseURL+self.path)?user=\(user.slackId)&team=\(user.slackTeamId)"
    }
}

struct PocketAuthorizationHandler: Handler, ErrorType {

    static let errorDomain = "PocketAuthorizationHandler"

    func handle(request: RouterRequest, response: RouterResponse, next: () -> Void) {
        Log.debug("\(self.dynamicType.errorDomain) handler")

        guard let action = PocketAuthorizationAction(request: request) else {
            let error = ConnectorError.pocketAuthorizationHandlerActionCouldntInit
            Log.error(error)
            response.error = self.getError(message: error.description)
            next()
            return
        }

        let errorView = ErrorView(response: response)
        let redirectView = RedirectView(response: response)
        let messageView = AuthorizeView(response: response)

        let parsedBody = request.queryParameters

        switch action {
        case .authorizationRequest:
            if let slacketUser = SlacketUserParser.parse(body: ParsedBody.urlEncoded(parsedBody)) where slacketUser.pocketAccessToken == nil {
                PocketAuthorizationRequestService.process(user: slacketUser)
                    .then(handler: { redirectUrl in
                        redirectView.redirect(to: redirectUrl)
                    }).trap(handler: { error in
                        let error = ConnectorError.pocketAuthorizationHandlerRedirectUrl
                        Log.error(error)
                        errorView.error(message: error.description)
                        next()
                        return
                    })
            } else {
                let error = ConnectorError.pocketAuthorizationHandlerSlacketUser
                Log.error(error)
                errorView.error(message: error.description)
                next()
                return
            }

        case .accessTokenRequest:
            if let slacketUser = SlacketUserParser.parse(body: ParsedBody.urlEncoded(parsedBody)) where slacketUser.pocketAccessToken == nil,
                let user = slacketUser as? SlacketUser{
                PocketAccessTokenRequestService.process(user: slacketUser)
                    .map(transform: { accessTokenResponse -> Promise<Bool> in
                        let fullSlacketUser = SlacketUser(slackId: user.slackId,
                                                          slackTeamId:  user.slackTeamId,
                                                          pocketAccessToken: accessTokenResponse.pocketAccessToken,
                                                          pocketUsername: accessTokenResponse.pocketUsername)
                        return SlacketUserDataStore.sharedInstance.set(data: fullSlacketUser)
                    }).map(transform: { _ in
                        messageView.show(message: .authorized)
                    }).trap(handler: { error in
                        let error = error as! Describable
                        Log.error(error)
                        errorView.error(message: error.description)
                        next()
                })
            }
        case .authorizationTest:
            messageView.show(message: .authorized)
        }
        next()
    }
}