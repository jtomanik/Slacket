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

        let promise = Promise<PocketItemType>()
        guard let pocketAccessToken = user.pocketAccessToken else {
            let error = ConnectorError.missingAccessToken
            Log.error(error.description)
            promise.reject(error: error)
            return promise
        }

        let pocketAddRequest = PocketAddRequest(url: url,
                                                accessToken: pocketAccessToken,
                                                title: nil,
                                                tags: tags,
                                                tweetId: nil)
        let pocketEndpoint = PocketAPI.add(pocketAddRequest)

        pocketEndpoint.request() { error, status, headers, data in
            guard let status = status else {
                let error = ConnectorError.missingStatus(for: .Pocket)
                Log.error(error.description)
                promise.reject(error: error)
                return
            }

            Log.debug("pocketEndpoint.request() returned status \(status)")
            Log.debug("pocketEndpoint.request() returned headers\n\(headers)")

            if 200...299 ~= status {
                if let data = data,
                    let pocketAddResponseBody = ParsedBody.init(data: data, contentType: pocketEndpoint.acceptContentType),
                    let pocketAddResponse = PocketAddResponseParser.parse(body: pocketAddResponseBody) where pocketAddResponse.status == 1 {
                    promise.resolve(value: pocketAddResponse.item)
                } else {
                    //TODO: ConnectorError.nilDataReturned
                    let error = ConnectorError.nilDataReturned(for: .Pocket)
                    Log.debug(error.description)
                    promise.reject(error: error)
                }
            } else {
                //TODO: ConnectorError.statusNotOk
                let error = ConnectorError.statusNotOk(for: .Pocket)
                Log.debug(error.description)
                promise.reject(error: error)
            }
        }
        return promise
    }
}