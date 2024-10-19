//
//  AppLogger.swift
//  XDevMan
//
//  Created by Mikhail Demidov on 08.10.2024.
//

import SwiftUI
import os

final class AppLogger: Sendable {
    
    private let logger = Logger()
    
    static let shared = AppLogger()
    
    func info(_ log: String, fileID: String = #fileID, line: Int = #line) {
        logger.info("\(self.prefix(fileID: fileID, line: line)) => \(log)")
    }
    
    func debug(_ log: String, fileID: String = #fileID, line: Int = #line) {
        logger.debug("\(self.prefix(fileID: fileID, line: line)) => \(log)")
    }
    
    func warning(_ log: String, fileID: String = #fileID, line: Int = #line) {
        logger.warning("\(self.prefix(fileID: fileID, line: line)) => \(log)")
    }
    
    func error(_ log: String, fileID: String = #fileID, line: Int = #line) {
        logger.error("\(self.prefix(fileID: fileID, line: line)) => \(log)")
    }
    
    func error(_ log: Error, fileID: String = #fileID, line: Int = #line) {
        logger.error("\(self.prefix(fileID: fileID, line: line)) => \(log)")
    }
    
    private func prefix(fileID: String, line: Int) -> String {
        let url = URL(fileURLWithPath: fileID, isDirectory: false)
        return "\(url.lastPathComponent):\(#line)"
    }
}

extension EnvironmentValues {
    
    @Entry var appLogger: AppLogger = AppLogger.shared
}

extension View {
    
    func withAppLogger(_ appLogger: AppLogger) -> some View {
        environment(\.appLogger, appLogger)
    }
}
