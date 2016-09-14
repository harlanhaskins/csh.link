import Vapor
import Fluent
import Foundation

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
    let schemeRegex = try! NSRegularExpression(pattern: "\\w+://")
    if schemeRegex.numberOfMatches(in: string,
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
  
  init(url: URL, code: String? = nil) throws {
    self.url = url
    self.code = code ?? IDGenerator.encodeID(url.hashValue)
  }
  
  init(node: Node, in context: Context) throws {
    id = try node.extract("id")
    let urlString: String = try node.extract("url")
    url = URL(string: urlString)!
    code = try node.extract("code")
    active = try node.extract("active")
  }
  
  func makeNode() -> Node {
    var data: Node = [
      "url": .string(url.absoluteString),
      "active": .bool(active),
      "code": .string(code)
    ]
    if let id = id {
      data["id"] = id
    }
    return data
  }
  
  func makeJSON() -> JSON {
    return JSON(makeNode())
  }
  
  static func prepare(_ database: Database) throws {
    try database.create("links") { link in
      link.id()
      link.string("url")
      link.string("code", length: 255, optional: true)
      link.bool("active")
    }
  }
  
  static func revert(_ database: Database) throws {
    try database.delete("links")
  }
}
