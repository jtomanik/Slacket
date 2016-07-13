//
//  SlacketUserService.swift
//  Slacket
//
//  Created by Jakub Tomanik on 25/05/16.
//
//

import Foundation
import When
import LoggerAPI

protocol SlacketServiceProvider {

    static func process(request: SlackCommandType) -> Promise<SlackMessageType>
}

struct SlacketService: SlacketServiceProvider {

    static let errorDomain = "SlacketUserService"

    static func process(request: SlackCommandType) -> Promise<SlackMessageType> {

        let promise = Promise<SlackMessageType>()

        let dataRequest = SlacketUserDataStore.sharedInstance.get(keyId: request.userId)
        dataRequest.then({ slacketUser -> Promise<PocketItemType> in
            guard slacketUser.pocketAccessToken != nil else {
                throw SlacketError.userNotAuthorized
            }
            
            var url = request.text.trimWhitespace()
            if !url.hasPrefix("http") {
                url = "http://" + url
            }
            return PocketApiConnector.addLink(url: url,
                                              tags: [request.teamDomain, request.channelName],
                                              user: slacketUser)
        }).then({ pocketItem -> Promise<Bool> in

            let slackMessage = SlackMessage(responseVisibility: .ephemeral, text: "successfully added link")
            return SlackApiConnector.send(message: slackMessage, inResponse: request)
        }).fail(handler: { error in
            // TODO: check error type for DB connection error
            // promise.reject(error: dbError)
            // return

            let nonCriticalError = true
            if nonCriticalError {
                let newUser = SlacketUser(slackId: request.userId,
                                          slackTeamId: request.teamId,
                                          pocketAccessToken: nil,
                                          pocketUsername: nil)
                let savingResult = SlacketUserDataStore.sharedInstance.set(data: newUser)
                savingResult.done(handler: { _ in
                    let message = self.startAuthorizationFlow(user: newUser)
                    promise.resolve(value: message)
                }).fail(handler: { error in
                    promise.reject(error: error)
                })
            } else {
                promise.reject(error: error)
            }
        })
        return promise
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