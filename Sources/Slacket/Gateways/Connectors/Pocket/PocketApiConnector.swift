//
//  PocketAddService.swift
//  Slacket
//
//  Created by Jakub Tomanik on 24/05/16.
//
//

import Foundation
import Kitura
import HeliumLogger
import LoggerAPI
import SimpleHttpClient
import When

protocol PocketConnectorType {
    
    static func addLink(url: String, tags: [String]?, user: SlacketUserType) -> Promise<PocketItemType>
}

struct PocketApiConnector: PocketConnectorType {
    
    static func addLink(url: String, tags: [String]?, user: SlacketUserType) -> Promise<PocketItemType> {
        guard let pocketAccessToken = user.pocketAccessToken else {
            Log.error(ConnectorError.missingAccessToken.description)
            return completion(nil)
        }
        
        let pocketAddRequest = PocketAddRequest(url: url,
                                                accessToken: pocketAccessToken,
                                                title: nil,
                                                tags: tags,
                                                tweetId: nil)
        let pocketEndpoint = PocketAPI.add(pocketAddRequest)
        pocketEndpoint.request() { error, status, headers, data in
            guard let status = status else {
                Log.error(ConnectorError.missingStatus(for: .Pocket).description)
                fatalError()
            }
            Log.debug("pocketEndpoint.request() returned status \(status)")
            Log.debug("pocketEndpoint.request() returned headers\n\(headers)")
            
            if let data = data where 200...299 ~= status,
                let pocketAddResponseBody = ParsedBody.init(data: data, contentType: pocketEndpoint.acceptContentType) {
                if let pocketAddResponse = PocketAddResponseParser.parse(body: pocketAddResponseBody)
                    where pocketAddResponse.status == 1 {
                    completion(pocketAddResponse.item)
                } else {
                    Log.debug(ConnectorError.missingStatus(for: .Pocket).description)
                    completion(nil)
                }
            } else {
                Log.debug(ConnectorError.nilDataParsedBodyOrAccessTokenResponse.description)
                completion(nil)
            }
        }
    }
}