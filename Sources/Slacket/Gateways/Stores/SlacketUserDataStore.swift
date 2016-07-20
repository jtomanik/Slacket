//
//  SlacketUserDataStore.swift
//  Slacket
//
//  Created by Jakub Tomanik on 25/05/16.
//
//

import Foundation
import Redbird
import Kitura
import LoggerAPI
import Promissum

extension SlacketUser: StorableType {

    var keyId: String {
        return self.slackId
    }
}

extension SlacketUser: RedisStorableType {

    static func deserialize(redisObject: RespObject) -> SlacketUser? {
        Log.debug("SlacketUser deserialize")
        guard let serialized = try? redisObject.toString(),
            let data = serialized.data(using: NSUTF8StringEncoding),
            let urlEncoded = ParsedBody.init(data: data, contentType: "application/x-www-form-urlencoded") else {
                Log.debug(SlacketError.slacketUserDeserialization)
                return nil
        }
        Log.debug("deserialize ok")
        return SlacketUserParser.parse(body: urlEncoded) as? SlacketUser
    }

    func serialize() -> String? {
        Log.debug("SlacketUser serialize")
        guard let dictonary = SlacketUserParser.encode(model: self) else {
            Log.debug(SlacketError.slacketUserSerialization)
            return nil
        }
        let urlEncoded = ParsedBody.urlEncoded(dictonary as DictionaryType)
        if let data = urlEncoded.data,
        let string = String.init(data: data, encoding: NSUTF8StringEncoding) {
            Log.debug("deserialize ok")
            return string
        } else {
            Log.debug(SlacketError.slacketUserSerialization)
            return nil
        }
    }
}

class SlacketUserDataStore: DataStoreProvider {

    typealias Storable = SlacketUser

    static let sharedInstance = SlacketUserDataStore()

    func get(keyId id: Storable.Identifier) -> Promise<Storable> {
        if LaunchArgumentsProcessor.onLocalHost {
            return SlacketUserLocalDataStore.sharedInstance.get(keyId: id)
        } else {
            return SlacketUserRedisDataStore.sharedInstance.get(keyId: id)
        }
    }

    func set(data: Storable) -> Promise<Bool> {
        if LaunchArgumentsProcessor.onLocalHost {
            return SlacketUserLocalDataStore.sharedInstance.set(data: data)
        } else {
            return SlacketUserRedisDataStore.sharedInstance.set(data: data)
        }
    }

    func clear(keyId id: Storable.Identifier) -> Promise<Bool> {
        if LaunchArgumentsProcessor.onLocalHost {
            return SlacketUserLocalDataStore.sharedInstance.clear(keyId: id)
        } else {
            return SlacketUserRedisDataStore.sharedInstance.clear(keyId: id)
        }
    }
}

class SlacketUserRedisDataStore: RedisStoreProvider {

    typealias Storable = SlacketUser

    static let sharedInstance = SlacketUserRedisDataStore()
}

class SlacketUserLocalDataStore: InMemoryStoreProvider {

    typealias Storable = SlacketUser

    static let sharedInstance = SlacketUserLocalDataStore()

    var memoryStore: [Storable.Identifier: Storable] = [:]
}