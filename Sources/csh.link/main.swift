import Vapor
import HTTP
import TurnstileCSH
import Foundation
import VaporSQLite

enum RequestError: Error {
    case noData
    case csrfViolation
}

func badRequest(reason: String) -> Response {
    return try! Response(status: .badRequest, json: JSON([
        "reason": .string(reason)
    ]))
}

func runServer() {
    
    let drop = Droplet(preparations: [Link.self],
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
        return Response(body: link.url.absoluteString)
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
        
        group.get("links") { request in
            let user = try request.auth.user() as! CSHAccount
            let links = try Link.query()
                .filter("creator", .equals, user.uuid)
                .filter("active", true)
                .all()
            return try drop.view.make("links", Node([
                "user": user.makeNode(),
                "links": links.makeNode()
                ]))
        }
        
        group.get { request in
            let user = try request.auth.user() as! CSHAccount
            return try drop.view.make("home", Node([
                "user": user.makeNode()
                ]))
        }
    }
    
    let port = drop.config["servers", "default", "port"]?.int ?? 80
    drop.run()
}

func main() {
    do {
        try runServer()
    } catch {
        print("Error: \(error)")
    }
}
