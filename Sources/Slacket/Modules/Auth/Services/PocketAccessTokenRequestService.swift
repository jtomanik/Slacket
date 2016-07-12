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
            Log.debug("user is nil")
            respond(nil)
            return
        }
        
        if let authData = PocketAuthorizationDataStore.sharedInstance.get(keyId: user.keyId) {
            PocketAuthorizeAPIConnector.requestAccessToken(data: authData) { accessTokenResponse in
                respond(accessTokenResponse)
            }
        } else {
            Log.debug("authData is nil")
        }
    }
}