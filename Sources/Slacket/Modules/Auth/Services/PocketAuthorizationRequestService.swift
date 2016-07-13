//
//  PocketAuthorizationRequestService.swift
//  Slacket
//
//  Created by Jakub Tomanik on 24/05/16.
//
//

import Foundation
import LoggerAPI
import When

typealias RedirectUrl = String

protocol PocketAuthorizationRequestServiceProvider {

    static func process(user: SlacketUserType) -> Promise<RedirectUrl>
}

struct PocketAuthorizationRequestService: PocketAuthorizationRequestServiceProvider {

    static let errorDomain = "PocketAuthorizationRequestService"

    static func process(user: SlacketUserType) -> Promise<RedirectUrl> {
        guard let user = user as? SlacketUser else {
            let promise = Promise<RedirectUrl>()
            let error = SlacketError.preconditionsNotMet
            Log.error(error.description)
            promise.reject(error: error)
            return promise
        }

        let redirectUrl: RedirectUrl = PocketAuthorizationAction.accessTokenRequest.redirectUrl(user: user)
        let promise = PocketAuthorizeAPIConnector.requestAuthorization(redirectUrl: redirectUrl)
        return promise.then({ response -> Promise<Bool> in
            let (authorizationResponse, _) = response
            let authorizationData = PocketAuthorizationData(id: user.keyId,
                                                            requestToken: authorizationResponse.pocketRequestToken)
            return PocketAuthorizationDataStore.sharedInstance.set(data: authorizationData)
        }).then({ _ -> RedirectUrl in
            return redirectUrl
        })
    }
}