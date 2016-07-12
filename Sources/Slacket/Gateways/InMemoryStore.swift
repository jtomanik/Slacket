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
        return self.memoryStore[keyId]
    }

    func set(data: Storable) -> Promise<Bool> {
        self.memoryStore[data.keyId] = data
        return true
    }

    func clear(keyId: Storable.Identifier) -> Promise<Bool> {
        let object = self.memoryStore.removeValue(forKey: keyId)
        return object != nil
    }
}