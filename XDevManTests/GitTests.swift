
@testable import XDevMan
import Testing

struct GitTests {

    @Test
    func gitParseCommits() async throws {
        let raw = """
commit ad962cb7f28da7b9fde839b69824beb87c563c95 (HEAD -> main, tag: 1.2024011601.1)
Merge: 3929950 9e46eea
Author: alex da franca <kiki@farbflash.de>
Date:   Thu Jul 4 00:21:46 2024 +0200

    Merge pull request #38 from a7ex/feature/add-additional-attributes-to-junit-output
    
    Changed the Junit xml slightly in order to be compatible with Jenkins…

commit 9e46eea76ae99f2c11d248a7bfc03b7adfd84b93
Author: Alex da Franca <alex@farbflash.de>
Date:   Thu Jul 4 00:19:39 2024 +0200

    Changed the Junit xml slightly in order to be compatible with Jenkins plugin
    
    It looks like the Jenkins plugin (https://plugins.jenkins.io/xunit/) expects:
    only 3 decimal places after the . in the time attribute
    an errors attribute, even if errors=0 on the testsuite

commit 3929950c8f3ec93b57b7ac5d2362fc0c7d78c85f (tag: 1.2022062300.1)
Author: Alex da Franca <alex@farbflash.de>
Date:   Sun Jun 16 13:35:05 2024 +0200

    removed swiftlint plugin from Package.swift file, as it seems to not work with commandline tools?
"""
        let expected: [Commit] = [
            .init(
                commit: "commit ad962cb7f28da7b9fde839b69824beb87c563c95 (HEAD -> main, tag: 1.2024011601.1)",
                hash: "ad962cb7f28da7b9fde839b69824beb87c563c95",
                tag: "1.2024011601.1",
                author: "Author: alex da franca <kiki@farbflash.de>",
                date: "Date:   Thu Jul 4 00:21:46 2024 +0200",
                message: """
    Merge pull request #38 from a7ex/feature/add-additional-attributes-to-junit-output
    
    Changed the Junit xml slightly in order to be compatible with Jenkins…

"""),
            .init(
                commit: "commit 9e46eea76ae99f2c11d248a7bfc03b7adfd84b93",
                hash: "9e46eea76ae99f2c11d248a7bfc03b7adfd84b93",
                tag: "",
                author: "Author: Alex da Franca <alex@farbflash.de>",
                date: "Date:   Thu Jul 4 00:19:39 2024 +0200",
                message: """
    Changed the Junit xml slightly in order to be compatible with Jenkins plugin
    
    It looks like the Jenkins plugin (https://plugins.jenkins.io/xunit/) expects:
    only 3 decimal places after the . in the time attribute
    an errors attribute, even if errors=0 on the testsuite

"""),
            .init(
                commit: "commit 3929950c8f3ec93b57b7ac5d2362fc0c7d78c85f (tag: 1.2022062300.1)",
                hash: "3929950c8f3ec93b57b7ac5d2362fc0c7d78c85f",
                tag: "1.2022062300.1",
                author: "Author: Alex da Franca <alex@farbflash.de>",
                date: "Date:   Sun Jun 16 13:35:05 2024 +0200",
                message: "    removed swiftlint plugin from Package.swift file, as it seems to not work with commandline tools?\n"
            )
        ]
        
        let commits = CliTool.Git.parse(log: raw)
        try #require(expected.count == commits.count)
        for (exp, commit) in zip(expected, commits) {
            #expect(exp.commit == commit.commit)
            #expect(exp.hash == commit.hash)
            #expect(exp.tag == commit.tag)
            #expect(exp.author == commit.author)
            #expect(exp.date == commit.date)
            #expect(exp.message == commit.message)
        }
    }
}
