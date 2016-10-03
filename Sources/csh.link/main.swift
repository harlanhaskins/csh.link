import Vapor
import HTTP
import TurnstileCSH
import Foundation
import VaporSQLite
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
    let renderer = LeafRenderer(viewsDir: "Resources/Views")
    renderer.stem.register(FormatDate())
    renderer.stem.register(Empty())
    
    let drop = Droplet(view: renderer,
                       preparations: [Link.self, Visit.self],
                       providers: [VaporSQLite.Provider.self])

    let linkController = LinkController(droplet: drop)
    drop.resource("links", linkController)
    
    let cshMiddleware = try CSHMiddleware(droplet: drop)
    
    drop.get(String.self) { request, code in
        guard let link = try Link.forCode(code) else {
            return try Response(status: .notFound, json: JSON([
                "reason": .string("Could not find a link for \(code). " +
                    "Check the code and try again.")
            ]))
        }
        return try linkController.show(request: request, item: link)
    }
    
    drop.get(String.self, "q") { request, code in
        guard let link = try Link.forCode(code) else {
            return try Response(status: .notFound, json: JSON([
                "reason": .string("Could not find a link for \(code). " +
                    "Check the code and try again.")
            ]))
        }
        return try drop.view.make("query", [
            "link": link.makeNode()
        ])
    }
    
    drop.group(cshMiddleware.authMiddleware, cshMiddleware) { group in
        group.delete(String.self) { request, code in
            guard let link = try Link.forCode(code) else {
                return badRequest(reason: "no url found for '\(code)'")
            }
            return try linkController.destroy(request: request, item: link)
        }
        
        group.post(String.self) { request, code in
            guard let link = try Link.forCode(code) else {
                return badRequest(reason: "no url found for '\(code)'")
            }
            return try linkController.update(request: request, item: link)
        }
        
        group.post { request in
            do {
                guard let json = request.json else {
                    throw RequestError.noData
                }
                
                let user = try request.auth.user() as! CSHAccount
                let urlString: String = try json.extract("url")
                let code: String? = try json.extract("code")
                let url = try URL(validating: urlString)
                return try linkController.create(url: url, creator: user, code: code)
            } catch {
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
