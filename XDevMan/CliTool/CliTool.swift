
import Foundation

typealias CliToolError = CliTool.MyError

enum CliTool { }

extension CliTool {
    
    static func exec(_ executable: String, arguments: [String]) async throws -> String {
        let result = Task<Result<String, MyError>, Never>.detached {
            do {
                AppLogger.shared.info("\(executable) \(arguments.filter({ $0.isEmpty == false }).joined(separator: " "))")
                let outputPipe = Pipe()
                let errorPipe = Pipe()
                let task = Process()
                task.executableURL = URL(fileURLWithPath: executable)
                task.arguments = arguments.filter({ $0.isEmpty == false })
                task.standardOutput = outputPipe
                task.standardError = errorPipe
                
                try task.run()
                
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(decoding: outputData, as: UTF8.self)
                let error = String(decoding: errorData, as: UTF8.self)
                if !error.isEmpty,
                   error != "Using Previews Device Set: '/Users/\(NSUserName())/Library/Developer/Xcode/UserData/Previews/Simulator Devices'\n" {
                    return .failure(MyError.exec(error))
                }
                return .success(output)
            } catch {
                return .failure(MyError.run(error))
            }
        }
        
        switch await result.value {
        case .success(let output):
            return output
        case .failure(let error):
            throw error
        }
    }
        
    enum MyError: Error {
        
        case run(Error)
        case exec(String)
        case decode(Error)
        case fs(Error)
    }
}
