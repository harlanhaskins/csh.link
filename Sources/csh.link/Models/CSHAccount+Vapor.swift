import Vapor
import Fluent
import Auth
import TurnstileCSH
import Foundation

enum UserError: Error {
    case registrationNotAllowed
}

extension CSHAccount: User {
    public var id: Node? {
        get {
            return .string(uuid)
        }
        set(newValue) {
            /* do nothing */
        }
    }
    
    public init(node: Node, in context: Context) throws {
        uuid = try node.extract("uuid")
        username = try node.extract("username")
        commonName = try node.extract("commonName")
    }
    
    public static func revert(_ database: Database) throws {
        return
    }
    
    public static func prepare(_ database: Database) throws {
        return
    }
    
    public static func register(credentials: Credentials) throws -> User {
        throw UserError.registrationNotAllowed
    }
    
    public func makeNode(context: Context) throws -> Node {
        return Node([
            "uuid": .string(uuid),
            "username": .string(username),
            "commonName": .string(commonName)
            ])
    }
}
