//
//  ShellCommand.swift
//  JAMF Enrollment Helper
//
//  Created by Mehraz Ahmed on 11/21/25.
//


import Foundation

struct ShellCommand {
    static func runPipedSudo(_ command: String) -> (output: String, exitCode: Int32) {
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", command]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
        } catch {
            return ("Failed to launch process: \(error.localizedDescription)", -1)
        }

        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        return (output, task.terminationStatus)
    }
}
