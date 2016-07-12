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
            // TODO: create DataStoreError.keyNotFound
            promise.reject(error: DataStoreError.keyNotFound)
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
        if let value = memoryStore.removeValue(forKey: keyId) {
            promise.resolve(value: true)
        } else {
            // TODO: create DataStoreError.keyNotFound
            promise.reject(error: DataStoreError.keyNotFound)
        }
        return promise
    }
}