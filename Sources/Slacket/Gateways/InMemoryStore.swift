//
//  InMemoryStore.swift
//  Slacket
//
//  Created by Jakub Tomanik on 07/07/16.
//
//

import Foundation
import Promissum
import Dispatch

protocol InMemoryStoreProvider: class, DataStoreProvider {

    var memoryStore: [Storable.Identifier: Storable] { get set }
}

extension InMemoryStoreProvider {

    func get(keyId: Storable.Identifier) -> Promise<Storable> {
        let source = PromiseSource<Storable>(dispatch: .Synchronous)
        if let value = memoryStore[keyId] {
            source.resolve(value: value)
        } else {
            source.reject(error: DataStoreError.notFound(key: String(keyId)))
        }
        return source.promise
    }

    func set(data: Storable) -> Promise<Bool> {
        let source = PromiseSource<Bool>(dispatch: .Synchronous)
        memoryStore[data.keyId] = data
        source.resolve(value: true)
        return source.promise
    }

    func clear(keyId: Storable.Identifier) -> Promise<Bool> {
        let source = PromiseSource<Bool>(dispatch: .Synchronous)
        if memoryStore.removeValue(forKey: keyId) != nil {
            source.resolve(value: true)
        } else {
            source.reject(error: DataStoreError.notFound(key: String(keyId)))
        }
        return source.promise
    }
}