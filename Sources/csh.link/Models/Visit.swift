import Vapor
import Fluent
import Foundation

enum VisitError: Error {
    case noParentId
}

struct Visit: Model {

    var id: Node? = nil
    var exists: Bool = false
    var linkId: Node?
    var timestamp: Date
    var visitorAddress: String?
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        linkId = try node.extract("link_id")
        timestamp = try node.extract("visited_at") {
            Date(timeIntervalSince1970: $0)
        }
        visitorAddress = try node.extract("ip_address")
    }
    
    init(parent: Link, visitorAddress: String?) throws {
        guard let parentId = parent.id else { throw VisitError.noParentId }
        linkId = parentId
        timestamp = Date()
        self.visitorAddress = visitorAddress
    }
    
    func makeNode(context: Context) throws -> Node {
        var data: Node = [
            "id": id ?? .null,
            "visited_at": .number(Node.Number(timestamp.timeIntervalSince1970))
        ]
        if let linkId = linkId {
            data["link_id"] = linkId
        }
        if let visitorAddress = visitorAddress {
            data["ip_address"] = .string(visitorAddress)
        }
        return data
    }
    
    public static func prepare(_ database: Database) throws {
        try database.create("visits") { visit in
            visit.id()
            visit.parent(Link.self, optional: false)
            visit.double("visited_at")
            visit.string("ip_address", optional: true)
        }
    }
    
    public static func revert(_ database: Database) throws {
        try database.delete("visits")
    }
    
    func link() throws -> Parent<Link> {
        return try parent(linkId)
    }
}
