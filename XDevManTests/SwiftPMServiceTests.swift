//
//  SwiftPMServiceTests.swift
//  XDevManTests
//
//  Created by Mikhail Demidov on 27.02.2026.
//

import Foundation
import Testing

@testable import XDevMan

@MainActor
struct SwiftPMServiceTests {

    private let packages: [SwiftPMService.Package] = [
        .init(
            name: "acknowlist", dependencies: []),
        .init(
            name: "swift-docc-plugin", dependencies: []),
        .init(
            name: "swift-argument-parser", dependencies: []),
        .init(
            name: "swift-nio", dependencies: []),
        .init(
            name: "opencombine", dependencies: []),
        .init(
            name: "swift-collections", dependencies: []),
        .init(
            name: "swift-system", dependencies: []),
        .init(
            name: "lrucache", dependencies: []),
        .init(
            name: "swiftsoup", dependencies: []),
        .init(
            name: "swift-atomics", dependencies: []),
        .init(
            name: "swift-concurrency-extras",
            dependencies: [
                .init(sourceControl: [
                    .init(identity: "swift-docc-plugin", location: .init(remote: [.init(urlString: "https://github.com/apple/swift-docc-plugin")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ])
            ]),
        .init(
            name: "swift-log",
            dependencies: [
                .init(sourceControl: [
                    .init(identity: "swift-docc-plugin", location: .init(remote: [.init(urlString: "https://github.com/apple/swift-docc-plugin")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ])
            ]),
        .init(
            name: "wasmtransformer",
            dependencies: [
                .init(sourceControl: [
                    .init(identity: "swift-argument-parser", location: .init(remote: [.init(urlString: "https://github.com/apple/swift-argument-parser")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ])
            ]),
        .init(
            name: "composable-core-location",
            dependencies: [
                .init(sourceControl: [
                    .init(identity: "swift-composable-architecture", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/swift-composable-architecture")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ])
            ]),
        .init(
            name: "swift-benchmark",
            dependencies: [
                .init(sourceControl: [
                    .init(identity: "swift-argument-parser", location: .init(remote: [.init(urlString: "https://github.com/apple/swift-argument-parser")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ])
            ]),
        .init(
            name: "swift-custom-dump",
            dependencies: [
                .init(sourceControl: [
                    .init(identity: "xctest-dynamic-overlay", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/xctest-dynamic-overlay")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ])
            ]),
        .init(
            name: "swift-async-algorithms",
            dependencies: [
                .init(sourceControl: [
                    .init(identity: "swift-collections", location: .init(remote: [.init(urlString: "https://github.com/apple/swift-collections.git")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ])
            ]),
        .init(
            name: "mastodonkit",
            dependencies: [
                .init(sourceControl: [
                    .init(identity: "swiftsoup", location: .init(remote: [.init(urlString: "https://github.com/scinfu/SwiftSoup.git")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ])
            ]),
        .init(
            name: "swift-syntax",
            dependencies: [
                .init(sourceControl: [
                    .init(identity: "swift-argument-parser", location: .init(remote: [.init(urlString: "https://github.com/apple/swift-argument-parser.git")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ])
            ]),
        .init(
            name: "swift-snapshot-testing",
            dependencies: [
                .init(sourceControl: [
                    .init(identity: "swift-syntax", location: .init(remote: [.init(urlString: "https://github.com/apple/swift-syntax.git")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ])
            ]),
        .init(
            name: "xctest-dynamic-overlay",
            dependencies: [
                .init(sourceControl: [
                    .init(identity: "swift-docc-plugin", location: .init(remote: [.init(urlString: "https://github.com/apple/swift-docc-plugin")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "carton", location: .init(remote: [.init(urlString: "https://github.com/swiftwasm/carton")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
            ]),
        .init(
            name: "swift-collections-benchmark",
            dependencies: [
                .init(sourceControl: [
                    .init(identity: "swift-argument-parser", location: .init(remote: [.init(urlString: "https://github.com/apple/swift-argument-parser")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-system", location: .init(remote: [.init(urlString: "https://github.com/apple/swift-system")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
            ]),
        .init(
            name: "swift-macro-testing",
            dependencies: [
                .init(sourceControl: [
                    .init(identity: "swift-syntax", location: .init(remote: [.init(urlString: "https://github.com/apple/swift-syntax.git")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-snapshot-testing", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/swift-snapshot-testing")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
            ]),
        .init(
            name: "combine-schedulers",
            dependencies: [
                .init(sourceControl: [
                    .init(identity: "swift-concurrency-extras", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/swift-concurrency-extras")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "xctest-dynamic-overlay", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/xctest-dynamic-overlay")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "opencombine", location: .init(remote: [.init(urlString: "https://github.com/OpenCombine/OpenCombine.git")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
            ]),
        .init(
            name: "swift-case-paths",
            dependencies: [
                .init(sourceControl: [
                    .init(identity: "swift-benchmark", location: .init(remote: [.init(urlString: "https://github.com/google/swift-benchmark")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "xctest-dynamic-overlay", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/xctest-dynamic-overlay")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-docc-plugin", location: .init(remote: [.init(urlString: "https://github.com/apple/swift-docc-plugin")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
            ]),
        .init(
            name: "swift-identified-collections",
            dependencies: [
                .init(sourceControl: [
                    .init(identity: "swift-collections", location: .init(remote: [.init(urlString: "https://github.com/apple/swift-collections")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-collections-benchmark", location: .init(remote: [.init(urlString: "https://github.com/apple/swift-collections-benchmark")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-docc-plugin", location: .init(remote: [.init(urlString: "https://github.com/apple/swift-docc-plugin")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
            ]),
        .init(
            name: "swift-perception",
            dependencies: [
                .init(sourceControl: [
                    .init(identity: "swift-macro-testing", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/swift-macro-testing")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-syntax", location: .init(remote: [.init(urlString: "https://github.com/swiftlang/swift-syntax")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "xctest-dynamic-overlay", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/xctest-dynamic-overlay")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
            ]),
        .init(
            name: "carton",
            dependencies: [
                .init(sourceControl: [
                    .init(identity: "swift-log", location: .init(remote: [.init(urlString: "https://github.com/apple/swift-log.git")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-argument-parser", location: .init(remote: [.init(urlString: "https://github.com/apple/swift-argument-parser.git")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-nio", location: .init(remote: [.init(urlString: "https://github.com/apple/swift-nio.git")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "wasmtransformer", location: .init(remote: [.init(urlString: "https://github.com/swiftwasm/WasmTransformer")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
            ]),
        .init(
            name: "swift-clocks",
            dependencies: [
                .init(sourceControl: [
                    .init(identity: "swift-async-algorithms", location: .init(remote: [.init(urlString: "https://github.com/apple/swift-async-algorithms")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-docc-plugin", location: .init(remote: [.init(urlString: "https://github.com/apple/swift-docc-plugin")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-concurrency-extras", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/swift-concurrency-extras")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "xctest-dynamic-overlay", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/xctest-dynamic-overlay")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
            ]),
        .init(
            name: "swiftui-navigation",
            dependencies: [
                .init(sourceControl: [
                    .init(identity: "swift-docc-plugin", location: .init(remote: [.init(urlString: "https://github.com/apple/swift-docc-plugin")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-case-paths", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/swift-case-paths")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-custom-dump", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/swift-custom-dump")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "xctest-dynamic-overlay", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/xctest-dynamic-overlay")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
            ]),
        .init(
            name: "swift-dependencies",
            dependencies: [
                .init(sourceControl: [
                    .init(identity: "swift-benchmark", location: .init(remote: [.init(urlString: "https://github.com/google/swift-benchmark")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "combine-schedulers", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/combine-schedulers")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-clocks", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/swift-clocks")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-concurrency-extras", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/swift-concurrency-extras")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "xctest-dynamic-overlay", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/xctest-dynamic-overlay")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-docc-plugin", location: .init(remote: [.init(urlString: "https://github.com/apple/swift-docc-plugin")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
            ]),
        .init(
            name: "swift-navigation",
            dependencies: [
                .init(sourceControl: [
                    .init(identity: "swift-collections", location: .init(remote: [.init(urlString: "https://github.com/apple/swift-collections")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-docc-plugin", location: .init(remote: [.init(urlString: "https://github.com/swiftlang/swift-docc-plugin")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-case-paths", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/swift-case-paths")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-concurrency-extras", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/swift-concurrency-extras")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-custom-dump", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/swift-custom-dump")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-perception", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/swift-perception")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "xctest-dynamic-overlay", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/xctest-dynamic-overlay")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
            ]),
        .init(
            name: "swift-sharing",
            dependencies: [
                .init(sourceControl: [
                    .init(identity: "combine-schedulers", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/combine-schedulers")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-concurrency-extras", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/swift-concurrency-extras")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-custom-dump", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/swift-custom-dump")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-dependencies", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/swift-dependencies")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-identified-collections", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/swift-identified-collections")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-perception", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/swift-perception")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "xctest-dynamic-overlay", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/xctest-dynamic-overlay")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-docc-plugin", location: .init(remote: [.init(urlString: "https://github.com/swiftlang/swift-docc-plugin")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
            ]),
        .init(
            name: "swift-composable-architecture",
            dependencies: [
                .init(sourceControl: [
                    .init(identity: "swift-collections", location: .init(remote: [.init(urlString: "https://github.com/apple/swift-collections")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-docc-plugin", location: .init(remote: [.init(urlString: "https://github.com/apple/swift-docc-plugin")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-benchmark", location: .init(remote: [.init(urlString: "https://github.com/google/swift-benchmark")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "combine-schedulers", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/combine-schedulers")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-case-paths", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/swift-case-paths")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-concurrency-extras", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/swift-concurrency-extras")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-custom-dump", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/swift-custom-dump")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-dependencies", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/swift-dependencies")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swift-identified-collections", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/swift-identified-collections")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "swiftui-navigation", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/swiftui-navigation")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
                .init(sourceControl: [
                    .init(identity: "xctest-dynamic-overlay", location: .init(remote: [.init(urlString: "https://github.com/pointfreeco/xctest-dynamic-overlay")]), requirement: .init(range: nil, revision: nil, exact: nil))
                ]),
            ]),
    ]

    @Test func makeGraph() async throws {
        let graphs = await SwiftPMService(bashService: BashProviderMock.self).graphs(packages)

        let expected: [String] = [
            "acknowlist",
            "lrucache",
            "swift-atomics",
            """
            composable-core-location
              swift-composable-architecture
                swift-collections
                swift-docc-plugin
                swift-benchmark
                  swift-argument-parser
                combine-schedulers
                  swift-concurrency-extras
                    swift-docc-plugin
                  xctest-dynamic-overlay
                    swift-docc-plugin
                    carton
                      swift-log
                        swift-docc-plugin
                      swift-argument-parser
                      swift-nio
                      wasmtransformer
                        swift-argument-parser
                  opencombine
                swift-case-paths
                  swift-benchmark
                    swift-argument-parser
                  xctest-dynamic-overlay
                    swift-docc-plugin
                    carton
                      swift-log
                        swift-docc-plugin
                      swift-argument-parser
                      swift-nio
                      wasmtransformer
                        swift-argument-parser
                  swift-docc-plugin
                swift-concurrency-extras
                  swift-docc-plugin
                swift-custom-dump
                  xctest-dynamic-overlay
                    swift-docc-plugin
                    carton
                      swift-log
                        swift-docc-plugin
                      swift-argument-parser
                      swift-nio
                      wasmtransformer
                        swift-argument-parser
                swift-dependencies
                  swift-benchmark
                    swift-argument-parser
                  combine-schedulers
                    swift-concurrency-extras
                      swift-docc-plugin
                    xctest-dynamic-overlay
                      swift-docc-plugin
                      carton
                        swift-log
                          swift-docc-plugin
                        swift-argument-parser
                        swift-nio
                        wasmtransformer
                          swift-argument-parser
                    opencombine
                  swift-clocks
                    swift-async-algorithms
                      swift-collections
                    swift-docc-plugin
                    swift-concurrency-extras
                      swift-docc-plugin
                    xctest-dynamic-overlay
                      swift-docc-plugin
                      carton
                        swift-log
                          swift-docc-plugin
                        swift-argument-parser
                        swift-nio
                        wasmtransformer
                          swift-argument-parser
                  swift-concurrency-extras
                    swift-docc-plugin
                  xctest-dynamic-overlay
                    swift-docc-plugin
                    carton
                      swift-log
                        swift-docc-plugin
                      swift-argument-parser
                      swift-nio
                      wasmtransformer
                        swift-argument-parser
                  swift-docc-plugin
                swift-identified-collections
                  swift-collections
                  swift-collections-benchmark
                    swift-argument-parser
                    swift-system
                  swift-docc-plugin
                swiftui-navigation
                  swift-docc-plugin
                  swift-case-paths
                    swift-benchmark
                      swift-argument-parser
                    xctest-dynamic-overlay
                      swift-docc-plugin
                      carton
                        swift-log
                          swift-docc-plugin
                        swift-argument-parser
                        swift-nio
                        wasmtransformer
                          swift-argument-parser
                    swift-docc-plugin
                  swift-custom-dump
                    xctest-dynamic-overlay
                      swift-docc-plugin
                      carton
                        swift-log
                          swift-docc-plugin
                        swift-argument-parser
                        swift-nio
                        wasmtransformer
                          swift-argument-parser
                  xctest-dynamic-overlay
                    swift-docc-plugin
                    carton
                      swift-log
                        swift-docc-plugin
                      swift-argument-parser
                      swift-nio
                      wasmtransformer
                        swift-argument-parser
                xctest-dynamic-overlay
                  swift-docc-plugin
                  carton
                    swift-log
                      swift-docc-plugin
                    swift-argument-parser
                    swift-nio
                    wasmtransformer
                      swift-argument-parser
            """,
            """
            mastodonkit
              swiftsoup
            """,
            """
            swift-navigation
              swift-collections
              swift-docc-plugin
              swift-case-paths
                swift-benchmark
                  swift-argument-parser
                xctest-dynamic-overlay
                  swift-docc-plugin
                  carton
                    swift-log
                      swift-docc-plugin
                    swift-argument-parser
                    swift-nio
                    wasmtransformer
                      swift-argument-parser
                swift-docc-plugin
              swift-concurrency-extras
                swift-docc-plugin
              swift-custom-dump
                xctest-dynamic-overlay
                  swift-docc-plugin
                  carton
                    swift-log
                      swift-docc-plugin
                    swift-argument-parser
                    swift-nio
                    wasmtransformer
                      swift-argument-parser
              swift-perception
                swift-macro-testing
                  swift-syntax
                    swift-argument-parser
                  swift-snapshot-testing
                    swift-syntax
                      swift-argument-parser
                swift-syntax
                  swift-argument-parser
                xctest-dynamic-overlay
                  swift-docc-plugin
                  carton
                    swift-log
                      swift-docc-plugin
                    swift-argument-parser
                    swift-nio
                    wasmtransformer
                      swift-argument-parser
              xctest-dynamic-overlay
                swift-docc-plugin
                carton
                  swift-log
                    swift-docc-plugin
                  swift-argument-parser
                  swift-nio
                  wasmtransformer
                    swift-argument-parser
            """,
            """
            swift-sharing
              combine-schedulers
                swift-concurrency-extras
                  swift-docc-plugin
                xctest-dynamic-overlay
                  swift-docc-plugin
                  carton
                    swift-log
                      swift-docc-plugin
                    swift-argument-parser
                    swift-nio
                    wasmtransformer
                      swift-argument-parser
                opencombine
              swift-concurrency-extras
                swift-docc-plugin
              swift-custom-dump
                xctest-dynamic-overlay
                  swift-docc-plugin
                  carton
                    swift-log
                      swift-docc-plugin
                    swift-argument-parser
                    swift-nio
                    wasmtransformer
                      swift-argument-parser
              swift-dependencies
                swift-benchmark
                  swift-argument-parser
                combine-schedulers
                  swift-concurrency-extras
                    swift-docc-plugin
                  xctest-dynamic-overlay
                    swift-docc-plugin
                    carton
                      swift-log
                        swift-docc-plugin
                      swift-argument-parser
                      swift-nio
                      wasmtransformer
                        swift-argument-parser
                  opencombine
                swift-clocks
                  swift-async-algorithms
                    swift-collections
                  swift-docc-plugin
                  swift-concurrency-extras
                    swift-docc-plugin
                  xctest-dynamic-overlay
                    swift-docc-plugin
                    carton
                      swift-log
                        swift-docc-plugin
                      swift-argument-parser
                      swift-nio
                      wasmtransformer
                        swift-argument-parser
                swift-concurrency-extras
                  swift-docc-plugin
                xctest-dynamic-overlay
                  swift-docc-plugin
                  carton
                    swift-log
                      swift-docc-plugin
                    swift-argument-parser
                    swift-nio
                    wasmtransformer
                      swift-argument-parser
                swift-docc-plugin
              swift-identified-collections
                swift-collections
                swift-collections-benchmark
                  swift-argument-parser
                  swift-system
                swift-docc-plugin
              swift-perception
                swift-macro-testing
                  swift-syntax
                    swift-argument-parser
                  swift-snapshot-testing
                    swift-syntax
                      swift-argument-parser
                swift-syntax
                  swift-argument-parser
                xctest-dynamic-overlay
                  swift-docc-plugin
                  carton
                    swift-log
                      swift-docc-plugin
                    swift-argument-parser
                    swift-nio
                    wasmtransformer
                      swift-argument-parser
              xctest-dynamic-overlay
                swift-docc-plugin
                carton
                  swift-log
                    swift-docc-plugin
                  swift-argument-parser
                  swift-nio
                  wasmtransformer
                    swift-argument-parser
              swift-docc-plugin
            """,
        ]

        #expect(graphs.map({ $0.description }) == expected)
    }
}
