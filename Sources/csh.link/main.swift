import Vapor
import HTTP
import TurnstileCSH
import Foundation
import PostgreSQL
import VaporPostgreSQL
import Leaf

enum RequestError: Error {
    case noData
    case csrfViolation
}

func badRequest(reason: String) -> Response {
    return try! Response(status: .badRequest, json: JSON([
        "reason": .string(reason)
    ]))
}



func runServer() throws {
    let drop = Droplet()
    try drop.addProvider(VaporPostgreSQL.Provider.self)
    drop.preparations.append(Link.self)
    drop.preparations.append(Visit.self)

    let linkController = LinkController(droplet: drop)
    let cshMiddleware = try CSHMiddleware(droplet: drop)
    
    drop.get(String.self) { request, code in
        guard let link = try Link.forCode(code) else {
            throw Abort.notFound
        }
        return try linkController.show(request: request, item: link)
    }
    
    drop.get(String.self, "q") { request, code in
        guard let link = try Link.forCode(code) else {
            throw Abort.notFound
        }
        return try drop.view.make("query", [
            "link": link.makeNode()
        ])
    }
    
    drop.get(String.self, "visits") { request, code in
        guard let link = try Link.forCode(code) else {
            throw Abort.notFound
        }
        let visits: [Node] = try link.visits().all().map { visit in
            return [
                "timestamp": .number(Node.Number(visit.timestamp.timeIntervalSince1970)),
            ]
        }
        return try JSON([
            "visits": visits.makeNode()
        ]).makeResponse()
    }
    
    drop.group(cshMiddleware.authMiddleware, cshMiddleware) { group in
        group.delete(String.self) { request, code in
            guard let link = try Link.forCode(code) else {
                throw Abort.notFound
            }
            return try linkController.destroy(request: request, item: link)
        }
        
        group.post(String.self) { request, code in
            do {
                guard let link = try Link.forCode(code) else {
                    throw Abort.notFound
                }
                return try linkController.update(request: request, item: link)
            } catch URLError.cannotLinkToMe {
                return badRequest(reason: "You cannot link to a csh.link URL.")
            }
        }
        
        group.post { request in
            do {
                guard let json = request.json else {
                    throw Abort.badRequest
                }
                
                let user = try request.auth.user() as! CSHAccount
                let urlString: String = try json.extract("url")
                let code: String? = try json.extract("code")
                let url = try URL(validating: urlString)
                return try linkController.create(url: url, creator: user, code: code)
            } catch LinkError.invalidShortCode {
                return badRequest(reason: "Custom short codes can only contain up to 128 alphanumeric characters, underscores, or dashes.")
            } catch URLError.cannotLinkToMe {
                return badRequest(reason: "You cannot link to a csh.link URL.")
            } catch is LinkError {
                return badRequest(reason: "You must provide a valid URL and, optionally, a code.")
            } catch is URLError {
                return badRequest(reason: "You must provide a valid URL and, optionally, a code.")
            }
        }
        
        group.get { request in
            let user = try request.auth.user() as! CSHAccount
            let links = try Link.query()
                .filter("creator", .equals, user.uuid)
                .filter("active", true)
                .all()
            var linkNodes = [Node]()
            for link in links {
                var node = try link.makeNode()
                let visits = try link.visits().all()
                node["visits"] = .number(Node.Number.int(visits.count))
                linkNodes.append(node)
            }
            let linkJSON = try JSON(linkNodes.makeNode()).serialize(prettyPrint: false)
            return try drop.view.make("home", [
                "user": user.makeNode(),
                "linkJSON": .bytes(linkJSON)
            ])
        }
    }
    
    _ = drop.config["servers", "default", "port"]?.int ?? 80
    drop.run()
}

func main() {
    do {
        try runServer()
    } catch {
        print("Error: \(error)")
    }
}

main()
