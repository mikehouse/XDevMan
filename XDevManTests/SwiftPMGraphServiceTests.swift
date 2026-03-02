import Foundation
import Testing

@testable import XDevMan

@MainActor
struct SwiftPMGraphServiceTests {

    private let service = SwiftPMGraphService()

    @Test
    func normalizeRepositoryURL_gitSSH() async throws {
        let result = await service.normalizeRepositoryURL("git@github.com:apple/swift.git")
        #expect(result?.absoluteString == "https://github.com/apple/swift")
    }

    @Test
    func normalizeRepositoryURL_sshScheme() async throws {
        let result = await service.normalizeRepositoryURL("ssh://git@gitlab.com/group/repo.git")
        #expect(result?.absoluteString == "https://gitlab.com/group/repo")
    }

    @Test
    func normalizeRepositoryURL_https() async throws {
        let result = await service.normalizeRepositoryURL("https://github.com/apple/swift.git")
        #expect(result?.absoluteString == "https://github.com/apple/swift")
    }

    @Test
    func normalizeRepositoryURL_invalid() async throws {
        let result = await service.normalizeRepositoryURL("::::")
        #expect(result == nil)
    }

    @Test
    func normalizeRepositoryURL_noHost() async throws {
        let result = await service.normalizeRepositoryURL("/tmp/repo.git")
        #expect(result == nil)
    }

    @Test
    func normalizeHTTPSURL_trimsSlashAndGitSuffix() async throws {
        let result = await service.normalizeHTTPSURL(host: "github.com", path: "/apple/swift.git")
        #expect(result?.absoluteString == "https://github.com/apple/swift")
    }

    @Test
    func normalizeHTTPSURL_keepsPathWithoutGitSuffix() async throws {
        let result = await service.normalizeHTTPSURL(host: "github.com", path: "apple/swift")
        #expect(result?.absoluteString == "https://github.com/apple/swift")
    }

    @Test
    func normalizeHTTPSURL_emptyHost() async throws {
        let result = await service.normalizeHTTPSURL(host: "", path: "/apple/swift.git")
        #expect(result == nil)
    }
}
