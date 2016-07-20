//
//  SlacketUserService.swift
//  Slacket
//
//  Created by Jakub Tomanik on 25/05/16.
//
//

import Foundation
import Promissum
import LoggerAPI

protocol SlacketServiceProvider {

    static func process(request: SlackCommandType) -> Promise<SlackMessageType>
}

struct SlacketService: SlacketServiceProvider {

    static let errorDomain = "SlacketUserService"

    static func process(request: SlackCommandType) -> Promise<SlackMessageType> {

        let source = PromiseSource<SlackMessageType>(dispatch: .Synchronous)

        let existingUserPromise = SlacketUserDataStore.sharedInstance.get(keyId: request.userId)
            .map(transform: { slacketUser throws -> SlacketUserType in
                guard slacketUser.pocketAccessToken != nil else {
                    throw SlacketError.userNotAuthorized
                }
                return slacketUser
            })
            .flatMap(transform: { slacketUser -> Promise<PocketItemType> in
                var url = request.text.trimWhitespace()
                if !url.hasPrefix("http") {
                    url = "http://" + url
                }
                return PocketApiConnector.addLink(url: url,
                                                  tags: [request.teamDomain, request.channelName],
                                                  user: slacketUser)
            })
            .map(transform: { pocketItem -> SlackMessageType in

                let slackMessage = SlackMessage(responseVisibility: .ephemeral, text: "successfully added link")
                //return SlackApiConnector.send(message: slackMessage, inResponse: request)
                return slackMessage
            }).then(handler: { message in
                source.resolve(value: message)
            })

        let newUser = SlacketUser(slackId: request.userId,
                                  slackTeamId: request.teamId,
                                  pocketAccessToken: nil,
                                  pocketUsername: nil)
        let _ = existingUserPromise.mapVoid()
            .mapError(transform: { error -> ErrorProtocol in
                guard let dbError = error as? DataStoreError where dbError == .notFound(key: request.userId) else {
                    return error
                }
                return SlacketError.userNotAuthorized
            })
            .flatMapError(transform: { error throws -> Promise<Void> in
                guard let slacketError =  error as? SlacketError where slacketError == .userNotAuthorized else {
                    throw error
                }
                return SlacketUserDataStore.sharedInstance.set(data: newUser).mapVoid()
            }).map(transform: { _ -> SlackMessageType in
                let message = self.startAuthorizationFlow(user: newUser)
                return message
            }).then(handler: { message in
                source.resolve(value: message)
            }).trap(handler: { error in
                source.reject(error: error)
            })

        return source.promise
    }

    private static func startAuthorizationFlow(user: SlacketUser) -> SlackMessageType {
        let userMessage = "Please go to \(PocketAuthorizationAction.authorizationRequest.redirectUrl(user: user))"
        let message = SlackMessage(responseVisibility: .ephemeral, text: userMessage)
        return message
    }

    private static func generateEcho(for request: SlackCommandType) -> SlackMessageType {
        let command = request.command.withoutPercentEncoding() ?? "Could not parse"
        let text = request.text.withoutPercentEncoding() ?? ""
        let message = SlackMessage(responseVisibility: .ephemeral,
                                   text: "\(command) \(text)")
        return message
    }
}