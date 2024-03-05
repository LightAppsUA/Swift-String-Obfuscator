//
//  StringObfuscator.swift
//
//
//  Created by Lukas Gergel on 02.01.2021.
//

import Foundation
import SwiftParser
import SwiftSyntax

public class StringObfuscator {
    public static func getObfuscatedContent(for sourceFile: URL) throws -> String {
        let fileContents = try String(contentsOf: sourceFile)
        let sourceFile = Parser.parse(source: fileContents)
        var output = ""
        let obfuscated = ObfuscateStringsRewritter().visit(sourceFile)
        obfuscated.write(to: &output)
        return output
    }

    public static func obfuscateContent(sourceFile: URL, targetFile: URL) throws {
        let fileContents = try String(contentsOf: sourceFile)
        let sourceFile = Parser.parse(source: fileContents)
        let fileHandle = try FileHandle(forWritingTo: targetFile)
        var output = FileHandlerOutputStream(fileHandle)
        let obfuscated = ObfuscateStringsRewritter().visit(sourceFile)
        obfuscated.write(to: &output)
    }
}
