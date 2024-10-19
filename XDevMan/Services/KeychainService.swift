//
//  KeychainService.swift
//  XDevMan
//
//  Created by Mikhail Demidov on 14.10.2024.
//

import SwiftUI

protocol KeychainServiceInterface where Self: Actor {
    
    func hasCertificate(sha1: String) async -> Bool?
}

final actor KeychainService: KeychainServiceInterface {
    
    private var sha1List: [String]?
    private var task: Task<[String]?, Never>?
    private lazy var logger = AppLogger.shared
    
    func hasCertificate(sha1: String) async -> Bool? {
        if let sha1List {
            return sha1List.contains(sha1)
        }
        if let task {
            return await task.value?.contains(sha1)
        }
        let task = Task<[String]?, Never> {
            do {
                let string = try await CliTool.exec("/usr/bin/security", arguments: ["find-certificate", "-Z", "-p", "-a"])
                let list = string.components(separatedBy: .newlines)
                    .filter({ $0.hasPrefix("SHA-1") })
                    .compactMap({ $0.components(separatedBy: " ").last })
                sha1List = list
                return list
            } catch {
                logger.error(error)
                return nil
            }
        }
        self.task = task
        return await task.value?.contains(sha1)
    }
}

actor KeychainServiceMock: KeychainServiceInterface {
    static let shared = KeychainServiceMock()
    func hasCertificate(sha1: String) async -> Bool? { nil }
}

extension EnvironmentValues {
    
    @Entry var keychainService: KeychainServiceInterface = KeychainServiceMock.shared
}

extension View {
    
    func withKeychainService(_ keychainService: KeychainServiceInterface) -> some View {
        environment(\.keychainService, keychainService)
    }
}
