//
//  AppLogger.swift
//  XDevMan
//
//  Created by Mikhail Demidov on 08.10.2024.
//

import SwiftUI
import os

final class AppLoggerEvent: @MainActor HashableIdentifiable {

    enum EventType {
        case info
        case debug
        case warning
        case error
    }

    let log: String
    let eventType: EventType
    let id = UUID()

    init(log: String, eventType: EventType) {
        self.log = log
        self.eventType = eventType
    }
}

protocol AppLoggerDelegate {

    var events: [AppLoggerEvent] { get }

    func logEvent(_ event: AppLoggerEvent)
}

nonisolated private protocol AppLoggerCollector {

    func info(_ log: String)
    func debug(_ log: String)
    func warning(_ log: String)
    func error(_ log: String)
}

final class AppLoggerRuntimeCollector: AppLoggerCollector {

    private let lock = NSLock()
    private var logEvents: [AppLoggerEvent] = []

    var delegate: AppLoggerDelegate? {
        didSet {
            lock.lock()
            defer { lock.unlock() }
            logEvents.forEach { delegate?.logEvent($0) }
        }
    }

    func info(_ log: String) {
        lock.lock()
        defer { lock.unlock() }

        logEvents.append(AppLoggerEvent(log: log, eventType: .info))
        logUpdate()
    }

    func debug(_ log: String) {
        lock.lock()
        defer { lock.unlock() }

        logEvents.append(AppLoggerEvent(log: log, eventType: .debug))
        logUpdate()
    }

    func warning(_ log: String) {
        lock.lock()
        defer { lock.unlock() }

        logEvents.append(AppLoggerEvent(log: log, eventType: .warning))
        logUpdate()
    }

    func error(_ log: String) {
        lock.lock()
        defer { lock.unlock() }

        logEvents.append(AppLoggerEvent(log: log, eventType: .error))
        logUpdate()
    }

    private func logUpdate() {
        guard let last = logEvents.last else { return }
        delegate?.logEvent(last)
    }
}

final class AppLogger: Sendable {

    static func runtimeLogger(_ delegate: AppLoggerDelegate) -> AppLogger {
        let logger = AppLogger()
        let collector = AppLoggerRuntimeCollector()
        collector.delegate = delegate
        logger.logCollector = collector
        AppLogger.current = logger
        return logger
    }
    
    private let logger = Logger()
    nonisolated(unsafe) private var logCollector: AppLoggerCollector?

    nonisolated(unsafe) fileprivate(set) static var current: AppLogger?
    
    nonisolated func info(_ log: String, fileID: String = #fileID, line: Int = #line) {
        logger.info("\(self.prefix(fileID: fileID, line: line)) => \(log)")
        logCollector?.info(log)
    }
    
    nonisolated func debug(_ log: String, fileID: String = #fileID, line: Int = #line) {
        logger.debug("\(self.prefix(fileID: fileID, line: line)) => \(log)")
        logCollector?.debug(log)
    }
    
    nonisolated func warning(_ log: String, fileID: String = #fileID, line: Int = #line) {
        logger.warning("\(self.prefix(fileID: fileID, line: line)) => \(log)")
        logCollector?.warning(log)
    }
    
    nonisolated func error(_ log: String, fileID: String = #fileID, line: Int = #line) {
        logger.error("\(self.prefix(fileID: fileID, line: line)) => \(log)")
        logCollector?.error(log)
    }
    
    nonisolated func error(_ log: Error, fileID: String = #fileID, line: Int = #line) {
        logger.error("\(self.prefix(fileID: fileID, line: line)) => \(log)")
    }

    nonisolated private func prefix(fileID: String, line: Int) -> String {
        let url = URL(fileURLWithPath: fileID, isDirectory: false)
        return "\(url.lastPathComponent):\(line)"
    }
}

extension EnvironmentValues {
    
    @Entry var appLogger: AppLogger = AppLogger()
}

extension View {
    
    func withAppLogger(_ appLogger: AppLogger) -> some View {
        environment(\.appLogger, appLogger)
    }
}
