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
            respond(nil)
            return
        }
        
        let redirectUrl = PocketAuthorizationAction.accessTokenRequest.redirectUrl(user: user)
        PocketAuthorizeAPIConnector.requestAuthorization(redirectUrl: redirectUrl) { response in
            guard let (authorizationResponse, redirectUrl) = response else {
                Log.debug("authorizationResponse or redirectUrl is nil")
                respond(nil)
                return
            }
            let authorizationData = PocketAuthorizationData(id: user.keyId,
                                                            requestToken: authorizationResponse.pocketRequestToken)
            let _ = PocketAuthorizationDataStore.sharedInstance.set(data: authorizationData)
            respond(redirectUrl)
        }
    }
}