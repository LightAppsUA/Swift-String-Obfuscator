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

    func base64Encode(_ input: String) -> String? {
        if let data = input.data(using: .utf8) {
            return data.base64EncodedString()
        }
        
        return nil
    }
    
    override open func visit(_ node: StringLiteralExprSyntax) -> ExprSyntax {
        defer {
            state = .reading
        }
        guard case .command = state else { return super.visit(node) }
        let origValue = "\(node.segments)"
        
        if origValue.contains("\\(") {
            return super.visit(node)
        }
        
        guard let base64Encoded = base64Encode(origValue) else { return super.visit(node) }
        
        let bytes = base64Encoded.bytes.enumerated().map { (i, element) -> ArrayElementSyntax in
            integerLiteralElement(Int(element), addComma: i < base64Encoded.bytes.count - 1)
        }
        
        let arrayElementList = ArrayElementListSyntax(bytes)

        let stringBytesArg = TupleExprElementSyntax(
            label: TokenSyntax.identifier("bytes"),
            colon: TokenSyntax.colonToken(trailingTrivia: .space),
            expression: ArrayExprSyntax(
                leftSquare: TokenSyntax.leftSquareBracketToken(),
                elements: arrayElementList,
                rightSquare: TokenSyntax.rightSquareBracketToken()),
            trailingComma: TokenSyntax.commaToken()
        )

        let stringEncodingArg = TupleExprElementSyntax(
            label: TokenSyntax.identifier("encoding"),
            colon: TokenSyntax.colonToken(trailingTrivia: .space),
            expression: ExprSyntax(IdentifierExprSyntax(identifier: TokenSyntax.identifier(".utf8"),
                                                                    declNameArguments: nil))
        ).withLeadingTrivia(.space)

        var stringBytesEncodingSyntax =
            ForcedValueExprSyntax(expression: FunctionCallExprSyntax(
                calledExpression: ExprSyntax(
                    IdentifierExprSyntax(
                        identifier: TokenSyntax.identifier("String"),
                        declNameArguments: nil
                    )
                ),
                leftParen: TokenSyntax.leftParenToken(),
                argumentList: TupleExprElementListSyntax([stringBytesArg, stringEncodingArg]),
                rightParen: TokenSyntax.rightParenToken()
            ))
        
        let dataBase64EncodedArg = TupleExprElementSyntax(
            label: TokenSyntax.identifier("base64Encoded"),
            colon: TokenSyntax.colonToken(trailingTrivia: .space),
            expression: stringBytesEncodingSyntax
        )
        
        let dataBase64EncodedEncodingSyntax = ForcedValueExprSyntax(expression: FunctionCallExprSyntax(
            calledExpression: ExprSyntax(
                IdentifierExprSyntax(
                    identifier: TokenSyntax.identifier("Data"),
                    declNameArguments: nil
                )
            ),
            leftParen: TokenSyntax.leftParenToken(),
            argumentList: TupleExprElementListSyntax([dataBase64EncodedArg]),
            rightParen: TokenSyntax.rightParenToken()
        ))
        
        let stringDataArg = TupleExprElementSyntax(
            label: TokenSyntax.identifier("data"),
            colon: TokenSyntax.colonToken(trailingTrivia: .space),
            expression: dataBase64EncodedEncodingSyntax,
            trailingComma: TokenSyntax.commaToken()
        )
        
        var stringDataEncodingSyntax = ForcedValueExprSyntax(expression: FunctionCallExprSyntax(
            calledExpression: ExprSyntax(
                IdentifierExprSyntax(
                    identifier: TokenSyntax.identifier("String"),
                    declNameArguments: nil
                )
            ),
            leftParen: TokenSyntax.leftParenToken(),
            argumentList: TupleExprElementListSyntax([stringDataArg, stringEncodingArg]),
            rightParen: TokenSyntax.rightParenToken()
        ))
        
        if let originalLeadingTrivia = node.leadingTrivia {
            stringDataEncodingSyntax = stringDataEncodingSyntax.withLeadingTrivia(originalLeadingTrivia)
        }
        
        if let originalTrailingTrivia = node.trailingTrivia {
            stringDataEncodingSyntax = stringDataEncodingSyntax.withTrailingTrivia(originalTrailingTrivia)
        }
        
        return super.visit(stringDataEncodingSyntax)
    }

    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        if state == .reading {
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
        if let data = string.data(using: encoding) {
            fileHandle.write(data)
        }
    }
}
