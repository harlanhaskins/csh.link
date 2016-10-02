import Vapor
import Fluent
import Foundation

struct Link: Model {
    var id: Node?
    var url: URL
    var code: String
    var created: Date
    var exists: Bool = false
    var active: Bool = true
    var creator: String? = nil
    
    init(url: URL, code: String? = nil, creator: String? = nil, created: Date? = nil) throws {
        self.url = url
        self.code = code ?? IDGenerator.encodeID(url.hashValue ^ Date().hashValue)
        self.creator = creator
        self.created = created ?? Date()
    }
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        let urlString: String = try node.extract("url")
        url = URL(string: urlString)!
        code = try node.extract("code")
        creator = try node.extract("creator")
        active = try node.extract("active")
        created = try node.extract("created_at") { (timestamp: TimeInterval) -> Date in
            return Date(timeIntervalSince1970: timestamp)
        }
    }
    
    func makeNode(context: Context) -> Node {
        var data: Node = [
            "url": .string(url.absoluteString),
            "active": .bool(active),
            "code": .string(code),
            "created_at": .number(Node.Number(created.timeIntervalSince1970))
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
    
    static func forCode(_ code: String) throws -> Link? {
        return try Link.query()
                       .filter("code", code)
                       .filter("active", true)
                       .first()
    }
    
    static func prepare(_ database: Database) throws {
        try database.create("links") { link in
            link.id()
            link.string("url")
            link.string("code")
            link.string("creator", length: 24, optional: false)
            link.bool("active")
            link.double("created_at")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete("links")
    }
    
    func visits() -> Children<Visit> {
        return children()
    }
}
