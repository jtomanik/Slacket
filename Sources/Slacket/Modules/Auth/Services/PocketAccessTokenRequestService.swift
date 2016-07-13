//
//  PPocketAuthorizationResponseService.swift
//  Slacket
//
//  Created by Jakub Tomanik on 24/05/16.
//
//

import Foundation
import LoggerAPI
import When

protocol PocketAccessTokenRequestServiceProvider {

    static func process(user: SlacketUserType) -> Promise<PocketAccessTokenResponseType>
}

struct PocketAccessTokenRequestService: PocketAccessTokenRequestServiceProvider {

    static let errorDomain = "PocketAccessTokenRequestService"

    static func process(user: SlacketUserType) -> Promise<PocketAccessTokenResponseType> {
        guard let user = user as? SlacketUser else {
            let promise = Promise<PocketAccessTokenResponseType>()
            let error = SlacketError.preconditionsNotMet
            Log.error(error.description)
            promise.reject(error: error)
            return promise
        }

        let promise = PocketAuthorizationDataStore.sharedInstance.get(keyId: user.keyId)
        return promise.then({ authData -> Promise<PocketAccessTokenResponseType> in
            return PocketAuthorizeAPIConnector.requestAccessToken(data: authData)
        })
    }
}