//
//  InMemoryStore.swift
//  Slacket
//
//  Created by Jakub Tomanik on 07/07/16.
//
//

import Foundation
import When

protocol InMemoryStoreProvider: class, DataStoreProvider {

    var memoryStore: [Storable.Identifier: Storable] { get set }
}

extension InMemoryStoreProvider {

    func get(keyId: Storable.Identifier) -> Promise<Storable> {
        let promise = Promise<Storable>()
        if let value = memoryStore[keyId] {
            promise.resolve(value: value)
        } else {
            promise.reject(error: DataStoreError.notFound(key: String(keyId)))
        }
        return promise
    }

    func set(data: Storable) -> Promise<Bool> {
        let promise = Promise<Bool>()
        memoryStore[data.keyId] = data
        promise.resolve(value: true)
        return promise
    }

    func clear(keyId: Storable.Identifier) -> Promise<Bool> {
        let promise = Promise<Bool>()
        if memoryStore.removeValue(forKey: keyId) != nil {
            promise.resolve(value: true)
        } else {
            promise.reject(error: DataStoreError.notFound(key: String(keyId)))
        }
        return promise
    }
}