//
//  ObfuscateStringsRewritter.swift
//  string_obfuscator
//
//  Created by Lukas Gergel on 01.01.2021.
//

import Foundation
import SwiftSyntax

enum State {
    case reading
    case command
}

class ObfuscateStringsRewritter: SyntaxRewriter {
    var state: State = .reading
    
    func integerLiteralElement(_ int: Int, addComma: Bool = true) -> ArrayElementSyntax {
        let literal = TokenSyntax.integerLiteral("\(int)")
        
        return ArrayElementSyntax(expression: ExprSyntax(IntegerLiteralExprSyntax(digits: literal)), trailingComma: addComma ? TokenSyntax.commaToken().withTrailingTrivia(.space) : nil)
    }

    override open func visit(_ node: StringLiteralExprSyntax) -> ExprSyntax {
        defer {
            state = .reading
        }
        guard case .command = state else { return super.visit(node) }
        let origValue = "\(node.segments)"
        let bytes = origValue.bytes.enumerated().map { (i, element) -> ArrayElementSyntax in
            integerLiteralElement(Int(element), addComma: i < origValue.bytes.count - 1)
        }
        
        let arrayElementList = ArrayElementListSyntax(bytes)

        let bytesArg = TupleExprElementSyntax(
            label: TokenSyntax.identifier("bytes"),
            colon: TokenSyntax.colonToken(trailingTrivia: .space),
            expression: ArrayExprSyntax(
                leftSquare: TokenSyntax.leftSquareBracketToken(),
                elements: arrayElementList,
                rightSquare: TokenSyntax.rightSquareBracketToken()),
            trailingComma: TokenSyntax.commaToken()
        )

        let encodingArg = TupleExprElementSyntax(
            label: TokenSyntax.identifier("encoding"),
            colon: TokenSyntax.colonToken(trailingTrivia: .space),
            expression: ExprSyntax(IdentifierExprSyntax(identifier: TokenSyntax.identifier(".utf8"),
                                                                    declNameArguments: nil))
        ).withLeadingTrivia(.space)

        var newCall =
            ForcedValueExprSyntax(expression: FunctionCallExprSyntax(
                calledExpression: ExprSyntax(
                    IdentifierExprSyntax(
                        identifier: TokenSyntax.identifier("String"),
                        declNameArguments: nil
                    )
                ),
                leftParen: TokenSyntax.leftParenToken(),
                argumentList: TupleExprElementListSyntax([bytesArg, encodingArg]),
                rightParen: TokenSyntax.rightParenToken()
            ))
        
        if let originalLeadingTrivia = node.leadingTrivia {
            newCall = newCall.withLeadingTrivia(originalLeadingTrivia)
        }
        
        if let originalTrailingTrivia = node.trailingTrivia {
            newCall = newCall.withTrailingTrivia(originalTrailingTrivia)
        }
        
        return super.visit(newCall)
    }

    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        let withoutSpaces = token.leadingTrivia.filter { if case .spaces = $0 { return false }; return true }
        guard withoutSpaces.count > 1 else { return super.visit(token) }
        let lastNewLine = withoutSpaces.last
        let commandLine = withoutSpaces[withoutSpaces.count-2]

        if state == .reading, case .newlines(1) = lastNewLine, case .lineComment("//:obfuscate") = commandLine {
            state = .command
        }
        return super.visit(token)
    }
}

struct FileHandlerOutputStream: TextOutputStream {
    private let fileHandle: FileHandle
    let encoding: String.Encoding

    init(_ fileHandle: FileHandle, encoding: String.Encoding = .utf8) {
        self.fileHandle = fileHandle
        self.encoding = encoding
    }

    mutating func write(_ string: String) {
        try? fileHandle.truncate(atOffset: 0) // Test solution for bad output file
        
        if let data = string.data(using: encoding) {
            fileHandle.write(data)
        }
    }
}
