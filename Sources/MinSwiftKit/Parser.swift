import Foundation
import SwiftSyntax

class Parser: SyntaxVisitor {
    private(set) var tokens: [TokenSyntax] = []
    private var index = 0
    private(set) var currentToken: TokenSyntax!

    // MARK: Practice 1

    override func visit(_ token: TokenSyntax) {
        print("Parsing \(token.tokenKind)")
        tokens.append(token)
    }

    @discardableResult
    func read() -> TokenSyntax {
        currentToken = tokens[index]
        index += 1
        return currentToken
    }

    func peek(_ n: Int = 0) -> TokenSyntax {
        return tokens[index+n]
    }

    // MARK: Practice 2

    private func extractNumberLiteral(from token: TokenSyntax) -> Double? {
        switch token.tokenKind {
        case .integerLiteral(let value):
            return Double(value)
        case .floatingLiteral(let value):
            return Double(value)
        default:
            return 0
        }
    }

    func parseNumber() -> Node {
        guard let value = extractNumberLiteral(from: currentToken) else {
            fatalError("any number is expected")
        }
        read() // eat literal
        return NumberNode(value: value)
    }

    func parseIdentifierExpression() -> Node {
        guard let identifier_string = extractIdentifierVariable(from: currentToken) else {
            fatalError("Not Implemented")
        }
        read()
        if currentToken.tokenKind == TokenKind.leftParen {
            var call_argments:[CallExpressionNode.Argument] = []
            read()
            while true {
                if currentToken.tokenKind == TokenKind.rightParen {
                    break
                } else if currentToken.tokenKind == TokenKind.comma {
                    read()
                } else {
                    guard  let argment_label = extractIdentifierVariable(from: currentToken) else {
                        fatalError()
                    }
                    read()
                    guard case .colon = currentToken.tokenKind else {
                        fatalError()
                    }
                    read()
                    guard let argment_value = parseExpression() else {
                        fatalError()
                    }
                    print("---------")
                    print(currentToken.tokenKind)
                    print(currentToken.tokenKind)
                    let argment = CallExpressionNode.Argument(label: argment_label, value: argment_value)
                    call_argments.append(argment)
                }
            }
            read()
            return CallExpressionNode(callee: identifier_string, arguments: call_argments)
        } else {
            return VariableNode(identifier: identifier_string)
        }
    }
        
    func extractIdentifierVariable(from token: TokenSyntax) -> String? {
        switch token.tokenKind {
        case .identifier(let variable):
            return variable
        default:
            return nil
        }
    }

    // MARK: Practice 3

    func extractBinaryOperator(from token: TokenSyntax) -> BinaryExpressionNode.Operator? {
        switch token.tokenKind {
            case .spacedBinaryOperator(let op):
                return BinaryExpressionNode.Operator(rawValue: op)
            default:
                return nil
        }
    }

    private func parseBinaryOperatorRHS(expressionPrecedence: Int, lhs: Node?) -> Node? {
        var currentLHS: Node? = lhs
        while true {
            let binaryOperator = extractBinaryOperator(from: currentToken!)
            let operatorPrecedence = binaryOperator?.precedence ?? -1
            
            // Compare between nextOperator's precedences and current one
            if operatorPrecedence < expressionPrecedence {
                return currentLHS
            }
            
            read() // eat binary operator
            var rhs = parsePrimary()
            if rhs == nil {
                return nil
            }
            
            // If binOperator binds less tightly with RHS than the operator after RHS, let
            // the pending operator take RHS as its LHS.
            let nextPrecedence = extractBinaryOperator(from: currentToken)?.precedence ?? -1
            if (operatorPrecedence < nextPrecedence) {
                // Search next RHS from currentRHS
                // next precedence will be `operatorPrecedence + 1`
                rhs = parseBinaryOperatorRHS(expressionPrecedence: operatorPrecedence + 1, lhs: rhs)
                if rhs == nil {
                    return nil
                }
            }
            
            guard let nonOptionalRHS = rhs else {
                fatalError("rhs must be nonnull")
            }
            
            currentLHS = BinaryExpressionNode(binaryOperator!,
                                              lhs: currentLHS!,
                                              rhs: nonOptionalRHS)
        }
    }

    // MARK: Practice 4

    func parseFunctionDefinitionArgument() -> FunctionNode.Argument {
        let id = extractArgment(from: currentToken)
        read()
        read()
        read()
        return FunctionNode.Argument(label: id, variableName: id)
    }
    
    func extractArgment(from token: TokenSyntax) -> String {
        switch currentToken.tokenKind {
        case .identifier(let id):
            return id
        default:
            fatalError("Not Implemented")
        }
    }
    
    func parseFunctionDefinition() -> Node {
        read()
        let func_name = exractFunctionName(from: currentToken)
        read()
        read()
        let arguments = extractFuncArgments()
        read()
        read()
        read()
        read()
        let func_body = extractFuncBody()
        read()
        return FunctionNode(name: func_name, arguments: arguments, returnType: .double, body: func_body)
    }
    
    func exractFunctionName (from token: TokenSyntax) -> String {
        switch token.tokenKind {
        case .identifier(let func_name):
            return func_name
        default:
            fatalError("Not Implemented")
        }
    }
    
    func extractFuncArgments () -> [FunctionNode.Argument] {
        var argments: [FunctionNode.Argument] = []
        while true {
            if case .rightParen = currentToken.tokenKind {
                break
            }
            if case .comma = currentToken.tokenKind {
                read()
            }
            argments.append(parseFunctionDefinitionArgument())
        }
        return argments
    }
    
    func extractFuncBody () -> Node {
        guard let body = parseExpression() else {
            fatalError("Could not parse expression")
        }
        return body
    }
 
    // MARK: Practice 7

    func parseIfElse() -> Node {
        fatalError("Not Implemented")
    }

    // PROBABLY WORKS WELL, TRUST ME

    func parse() -> [Node] {
        var nodes: [Node] = []
        read()
        while true {
            switch currentToken.tokenKind {
            case .eof:
                return nodes
            case .funcKeyword:
                let node = parseFunctionDefinition()
                nodes.append(node)
            default:
                if let node = parseTopLevelExpression() {
                    nodes.append(node)
                    break
                } else {
                    read()
                }
            }
        }
        return nodes
    }

    private func parsePrimary() -> Node? {
        switch currentToken.tokenKind {
        case .identifier:
            return parseIdentifierExpression()
        case .integerLiteral, .floatingLiteral:
            return parseNumber()
        case .leftParen:
            return parseParen()
        case .funcKeyword:
            return parseFunctionDefinition()
        case .returnKeyword:
            return parseReturn()
        case .ifKeyword:
            return parseIfElse()
        case .eof:
            return nil
        default:
            fatalError("Unexpected token \(currentToken.tokenKind) \(currentToken.text)")
        }
        return nil
    }

    func parseExpression() -> Node? {
        guard let lhs = parsePrimary() else {
            return nil
        }
        return parseBinaryOperatorRHS(expressionPrecedence: 0, lhs: lhs)
    }

    private func parseReturn() -> Node {
        guard case .returnKeyword = currentToken.tokenKind else {
            fatalError("returnKeyword is expected but received \(currentToken.tokenKind)")
        }
        read() // eat return
        if let expression = parseExpression() {
            return ReturnNode(body: expression)
        } else {
            // return nothing
            return ReturnNode(body: nil)
        }
    }

    private func parseParen() -> Node? {
        read() // eat (
        guard let v = parseExpression() else {
            return nil
        }

        guard case .rightParen = currentToken.tokenKind else {
                fatalError("expected ')'")
        }
        read() // eat )

        return v
    }

    private func parseTopLevelExpression() -> Node? {
        if let expression = parseExpression() {
            // we treat top level expressions as anonymous functions
            let anonymousPrototype = FunctionNode(name: "main", arguments: [], returnType: .int, body: expression)
            return anonymousPrototype
        }
        return nil
    }
}

private extension BinaryExpressionNode.Operator {
    var precedence: Int {
        switch self {
        case .addition, .subtraction: return 20
        case .multication, .division: return 40
        case .lessThan:
            fatalError("Not Implemented")
        }
    }
}
