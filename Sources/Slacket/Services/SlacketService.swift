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

        dataRequest.then({ slacketUser in

            if slacketUser.pocketAccessToken == nil {
                let message = startAuthorizationFlow()
                promise.resolve(value: message)
                throw SlacketServiceError.userNotAuthorized
            } else {
                return slacketUser
            }
        }).then({ slacketUser in

            var url = request.text.trimWhitespace()
            if !url.hasPrefix("http") {
                url = "http://" + url
            }
            return PocketApiConnector.addLink(url: url,
                                              tags: [request.teamDomain, request.channelName],
                                              user: slacketUser)
        }).then({ pocketItem in

            let slackMessage = SlackMessage(responseVisibility: .ephemeral, text: "successfully added link")
            return SlackApiConnector.send(message: slackMessage, inResponse: request)
        }).fail({ error in
            promise.reject(error: error)
        })

        dataRequest.fail({ error in
            // TODO: check error type for DB connection error
            // promise.reject(error: dbError)
            // return

            let message = startAuthorizationFlow()
            promise.resolve(value: message)
        })
        return promise
    }

    private func startAuthorizationFlow() -> SlackMessageType {
        let newUser = SlacketUser(slackId: request.userId,
                                  slackTeamId: request.teamId,
                                  pocketAccessToken: nil,
                                  pocketUsername: nil)
        let result = SlacketUserDataStore.sharedInstance.set(data: newUser)
        let userMessage = result ? "Please go to \(PocketAuthorizationAction.authorizationRequest.redirectUrl(user: newUser))" : "Ooops... there was an internal error"
        let message = SlackMessage(responseVisibility: .ephemeral, text: userMessage)
        return message
    }

    private func generateEcho(for request: SlackCommandType) -> SlackMessageType {
        let command = request.command.withoutPercentEncoding() ?? "Could not parse"
        let text = request.text.withoutPercentEncoding() ?? ""
        let message = SlackMessage(responseVisibility: .ephemeral,
                                   text: "\(command) \(text)")
        return message
    }
}