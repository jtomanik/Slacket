//
//  PocketAuthorizeAPIConnector.swift
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

protocol PocketAuthorizeAPIConnectorType {

    static func requestAuthorization(redirectUrl url: RedirectUrl) -> Promise<(PocketAuthorizationResponseType, RedirectUrl)>
    static func requestAccessToken(data: PocketAuthorizationData) -> Promise<PocketAccessTokenResponseType>
}

struct PocketAuthorizeAPIConnector: PocketAuthorizeAPIConnectorType {

    static func requestAuthorization(redirectUrl url: RedirectUrl) -> Promise<(PocketAuthorizationResponseType, RedirectUrl)> {

        let promise = Promise<(PocketAuthorizationResponseType, RedirectUrl)>()
        let requestData = PocketAuthorizationRequest(pocketRedirectUri: url)
        let authorizeEndpoint = PocketAuthorizeAPI.requestAuthorization(requestData)

        authorizeEndpoint.request() { error, status, headers, data in
            guard let status = status else {
                let error = ConnectorError.missingStatus(for: .PocketAuthorizationRequest)
                Log.error(error.description)
                promise.reject(error: error)
                return
            }

            Log.debug("pocketEndpoint.request() returned status \(status)")
            Log.debug("pocketEndpoint.request() returned headers\n\(headers)")

            if 200...299 ~= status {
                if let data = data,
                    let parsedBody = ParsedBody.init(data: data, contentType: authorizeEndpoint.acceptContentType),
                    let authorizationResponse = PocketAuthorizationResponseParser.parse(body: parsedBody),
                    let redirectUrl = authorizeEndpoint.redirectUrl(for: authorizationResponse) {
                    promise.resolve(value: (authorizationResponse, redirectUrl))
                } else {
                    //TODO: ConnectorError.nilDataReturned
                    let error = ConnectorError.nilDataReturned(for: .PocketAuthorizationRequest)
                    Log.debug(error.description)
                    promise.reject(error: error)
                }
            } else {
                //TODO: ConnectorError.statusNotOk
                let error = ConnectorError.statusNotOk(for: .PocketAuthorizationRequest)
                Log.debug(error.description)
                promise.reject(error: error)
            }
        }
        return promise
    }

    static func requestAccessToken(data: PocketAuthorizationData) -> Promise<PocketAccessTokenResponseType> {

        let promise = Promise<PocketAccessTokenResponseType>()
        let requestData = PocketAccessTokenRequest(pocketRequestToken: data.requestToken)
        let accessTokenEndpoint = PocketAuthorizeAPI.requestAccessToken(requestData)

        accessTokenEndpoint.request() { error, status, headers, data in
            guard let status = status else {
                let error = ConnectorError.missingStatus(for: .PocketAccessTokenRequest)
                Log.error(error.description)
                promise.reject(error: error)
                return
            }

            Log.debug("pocketEndpoint.request() returned status \(status)")
            Log.debug("pocketEndpoint.request() returned headers\n\(headers)")

            if 200...299 ~= status {
                if let data = data,
                    let parsedBody = ParsedBody.init(data: data, contentType: accessTokenEndpoint.acceptContentType),
                    let accessTokenResponse = PocketAccessTokenResponseParser.parse(body: parsedBody) {
                    let accessTokenResponse = accessTokenResponse as PocketAccessTokenResponseType
                    completion(accessTokenResponse)
                } else {
                    //TODO: ConnectorError.nilDataReturned
                    let error = ConnectorError.nilDataReturned(for: .PocketAccessTokenRequest)
                    Log.debug(error.description)
                    promise.reject(error: error)
                }
            } else {
                //TODO: ConnectorError.statusNotOk
                let error = ConnectorError.statusNotOk(for: .PocketAccessTokenRequest)
                Log.debug(error.description)
                promise.reject(error: error)
            }
        }
        return promise
    }
}