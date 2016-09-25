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

#if os(macOS)
  typealias RegularExpression = NSRegularExpression
#endif

enum LinkError: Error {
  case noID
}

enum URLError: Error {
  case notAURL
  case noHost
}

extension URL {
  init(validating string: String) throws {
    var string = string
    
    // HACK: Add scheme if none is provided
    let schemeRegex = try! RegularExpression(pattern: "\\w+://", options: [])
    if schemeRegex.numberOfMatches(in: string,
                                   options: [],
                                   range: NSRange(location: 0, length: string.characters.count)) == 0 {
      string = "http://\(string)"
    }
    
    guard let url = URL(string: string) else {
      throw URLError.notAURL
    }
    guard url.host != nil else {
      throw URLError.noHost
    }
    self = url
  }
}

final class Link: Model {
  var id: Node?
  var url: URL
  var code: String
  var active: Bool = true
  var creator: String? = nil
  
  init(url: URL, code: String? = nil, creator: String? = nil) throws {
    self.url = url
    self.code = code ?? IDGenerator.encodeID(url.hashValue)
    self.creator = creator
  }
  
  init(node: Node, in context: Context) throws {
    id = try node.extract("id")
    let urlString: String = try node.extract("url")
    url = URL(string: urlString)!
    code = try node.extract("code")
    creator = try node.extract("creator")
    active = try node.extract("active")
  }
  
  func makeNode(context: Context) -> Node {
    var data: Node = [
      "url": .string(url.absoluteString),
      "active": .bool(active),
      "code": .string(code)
    ]
    if let id = id {
      data["id"] = id
    }
    if let creator = creator {
      data["creator"] = .string(creator)
    }
    return data
  }
  
  func makeJSON() -> JSON {
    return JSON(makeNode(context: EmptyNode))
  }
  
  static func prepare(_ database: Database) throws {
    try database.create("links") { link in
      link.id()
      link.string("url")
      link.string("code", length: 255, optional: true)
      link.string("creator", length: 24, optional: true)
      link.bool("active")
    }
  }
  
  static func revert(_ database: Database) throws {
    try database.delete("links")
  }
}
