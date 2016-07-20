//
//  RedisStore.swift
//  Slacket
//
//  Created by Jakub Tomanik on 07/07/16.
//
//

import Foundation
import Environment
import Redbird
import LoggerAPI
import Promissum

protocol RedisClientType {

    var host: String { get }
    var port: UInt16 { get }
}

extension RedisClientType {

    var host: String {
        guard let host = Environment().getVar("REDIS_HOST") else {
            Log.error(DataStoreError.missingRedisHostEnvVariable)
            fatalError()
        }
        return host
    }

    var port: UInt16 {
        return 6379
    }
}

protocol RedisStorableType: StorableType {

    static func deserialize(redisObject: RespObject) -> Self?
    func serialize() -> String?
}

protocol RedisStoreProvider: class, DataStoreProvider {

    var redisStore: RedisStore { get }
}

extension RedisStoreProvider where Storable: RedisStorableType, Storable.Identifier == String {

    var redisStore: RedisStore {
        return RedisStore.sharedInstance
    }

    func get(keyId: Storable.Identifier) -> Promise<Storable> {
        let source = PromiseSource<Storable>(dispatch: .Synchronous)
        guard let client = redisStore.client else {
            source.reject(error: DataStoreError.clientNotFound)
            return source.promise
        }
        
        if let object = try? client.command("GET", params: [keyId]),
            storable = Storable.deserialize(redisObject: object) {
                Log.debug("Redis GET for key: \(keyId)")
                source.resolve(value: storable)
        } else {
            let error = DataStoreError.failure(for: .get)
            Log.error(error)
            source.reject(error: error)
        }
        return source.promise
    }

    func set(data: Storable) -> Promise<Bool> {
        let source = PromiseSource<Bool>(dispatch: .Synchronous)
        guard let client = redisStore.client else {
            source.reject(error: DataStoreError.clientNotFound)
            return source.promise
        }
        
        if let serialized = data.serialize(),
            _ = try? client.command("SET", params: [data.keyId, serialized]).toString() {
                Log.debug("Redis SET for key: \(data.keyId)")
                source.resolve(value: true)
        } else {
            let error = DataStoreError.failure(for: .set)
            Log.error(error)
            source.reject(error: error)
        }
        return source.promise
    }

    func clear(keyId: Storable.Identifier) -> Promise<Bool> {
        let source = PromiseSource<Bool>(dispatch: .Synchronous)
        guard let client = redisStore.client else {
            source.reject(error: DataStoreError.clientNotFound)
            return source.promise
        }
        
        if let result = try? client.command("DEL", params: [keyId]).toInt() {
            Log.debug("Redis DEL for key: \(keyId)")
            source.resolve(value: result > 0)
        } else {
            let error = DataStoreError.failure(for: .del)
            Log.error(error)
            source.reject(error: error)
        }
        return source.promise
    }
}

class RedisStore: RedisClientType {

    static let sharedInstance = RedisStore()

    lazy var client: Redbird? = {
        let config = RedbirdConfig(address: self.host, port: self.port)
        let client = try? Redbird(config: config)
        let logmessage = client != nil ? "OK" : "Error"
        Log.debug("Redis connection: \(logmessage)")
        return client
    }()
}