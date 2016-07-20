//
//  DataStore.swift
//  Slacket
//
//  Created by Jakub Tomanik on 27/05/16.
//
//

import Foundation
import Promissum

protocol StoreType { }

protocol StorableType {
    
    associatedtype Identifier : Hashable
    
    var keyId: Identifier { get }
}

protocol DataStoreProvider: StoreType {
    
    associatedtype Storable: StorableType

    func get(keyId: Storable.Identifier) -> Promise<Storable>
    func set(data: Storable) -> Promise<Bool>
    func clear(keyId: Storable.Identifier) -> Promise<Bool>
}