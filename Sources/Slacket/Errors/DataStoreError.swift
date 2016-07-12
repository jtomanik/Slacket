//
//  DataStoreError.swift
//  Slacket
//
//  Created by Bartłomiej Nowak on 12/07/16.
//
//

import Foundation

enum MethodType: String {
    case get
    case set
    case del
}

enum DataStoreError: ErrorProtocol, DescribableError {
    case missingRedisHostEnvVariable
    case notFound(key: String)
    case clientNotFound
    case failure(for: MethodType)
    
    var description: String {
        switch self {
            case .missingRedisHostEnvVariable:
                return "Cannot find REDIS_HOST environmental variable"
            case .notFound(let key):
                return "\(key) not found"
            case .clientNotFound:
                return "Client not found"
            case .failure(let methodType):
                return "\(methodType.rawValue) error"
        }
    }
}