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
import Promissum

protocol PocketAuthorizeAPIConnectorType {

    static func requestAuthorization(redirectUrl url: RedirectUrl) -> Promise<(PocketAuthorizationResponseType, RedirectUrl)>
    static func requestAccessToken(data: PocketAuthorizationData) -> Promise<PocketAccessTokenResponseType>
}

struct PocketAuthorizeAPIConnector: PocketAuthorizeAPIConnectorType {

    static func requestAuthorization(redirectUrl url: RedirectUrl) -> Promise<(PocketAuthorizationResponseType, RedirectUrl)> {

        let source = PromiseSource<(PocketAuthorizationResponseType, RedirectUrl)>(dispatch: .Synchronous)
        let requestData = PocketAuthorizationRequest(pocketRedirectUri: url)
        let authorizeEndpoint = PocketAuthorizeAPI.requestAuthorization(requestData)

        authorizeEndpoint.request() { error, status, headers, data in
            guard let status = status else {
                let error = ConnectorError.missingStatus(for: .pocketAuthorizationRequest)
                Log.error(error.description)
                source.reject(error: error)
                return
            }

            Log.debug("pocketEndpoint.request() returned status \(status)")
            Log.debug("pocketEndpoint.request() returned headers\n\(headers)")

            if 200...299 ~= status {
                if let data = data,
                    let parsedBody = ParsedBody.init(data: data, contentType: authorizeEndpoint.acceptContentType),
                    let authorizationResponse = PocketAuthorizationResponseParser.parse(body: parsedBody),
                    let redirectUrl = authorizeEndpoint.redirectUrl(for: authorizationResponse) {
                    source.resolve(value: (authorizationResponse, redirectUrl))
                } else {
                    //TODO: ConnectorError.nilDataReturned
                    let error = ConnectorError.nilDataReturned(for: .pocketAuthorizationRequest)
                    Log.debug(error.description)
                    source.reject(error: error)
                }
            } else {
                //TODO: ConnectorError.statusNotOk
                let error = ConnectorError.statusNotOk(for: .pocketAuthorizationRequest)
                Log.debug(error.description)
                source.reject(error: error)
            }
        }
        return source.promise
    }

    static func requestAccessToken(data: PocketAuthorizationData) -> Promise<PocketAccessTokenResponseType> {

        let source = PromiseSource<PocketAccessTokenResponseType>(dispatch: .Synchronous)
        let requestData = PocketAccessTokenRequest(pocketRequestToken: data.requestToken)
        let accessTokenEndpoint = PocketAuthorizeAPI.requestAccessToken(requestData)

        accessTokenEndpoint.request() { error, status, headers, data in
            guard let status = status else {
                let error = ConnectorError.missingStatus(for: .pocketAccessTokenRequest)
                Log.error(error.description)
                source.reject(error: error)
                return
            }

            Log.debug("pocketEndpoint.request() returned status \(status)")
            Log.debug("pocketEndpoint.request() returned headers\n\(headers)")

            if 200...299 ~= status {
                if let data = data,
                    let parsedBody = ParsedBody.init(data: data, contentType: accessTokenEndpoint.acceptContentType),
                    let accessTokenResponse = PocketAccessTokenResponseParser.parse(body: parsedBody) {
                    let accessTokenResponse = accessTokenResponse as PocketAccessTokenResponseType
                    source.resolve(value: accessTokenResponse)
                } else {
                    //TODO: ConnectorError.nilDataReturned
                    let error = ConnectorError.nilDataReturned(for: .pocketAccessTokenRequest)
                    Log.debug(error.description)
                    source.reject(error: error)
                }
            } else {
                //TODO: ConnectorError.statusNotOk
                let error = ConnectorError.statusNotOk(for: .pocketAccessTokenRequest)
                Log.debug(error.description)
                source.reject(error: error)
            }
        }
        return source.promise
    }
}