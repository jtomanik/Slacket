//
//  PPocketAuthorizationResponseService.swift
//  Slacket
//
//  Created by Jakub Tomanik on 24/05/16.
//
//

import Foundation
import LoggerAPI
import Promissum

protocol PocketAccessTokenRequestServiceProvider {

    static func process(user: SlacketUserType) -> Promise<PocketAccessTokenResponseType>
}

struct PocketAccessTokenRequestService: PocketAccessTokenRequestServiceProvider {

    static let errorDomain = "PocketAccessTokenRequestService"

    static func process(user: SlacketUserType) -> Promise<PocketAccessTokenResponseType> {
        guard let user = user as? SlacketUser else {
            let source = PromiseSource<PocketAccessTokenResponseType>(dispatch: .Synchronous)
            let error = SlacketError.preconditionsNotMet
            Log.error(error.description)
            source.reject(error: error)
            return source.promise
        }

        let promise = PocketAuthorizationDataStore.sharedInstance.get(keyId: user.keyId)
        return promise.flatMap(transform: { authData in
            return PocketAuthorizeAPIConnector.requestAccessToken(data: authData)
        })
    }
}