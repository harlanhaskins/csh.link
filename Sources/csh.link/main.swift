import Vapor
import Auth
import HTTP
import VaporSQLite
import TurnstileCSH
import TurnstileCrypto
import Foundation

enum RequestError: Error {
    case noData
    case csrfViolation
}

let drop = Droplet(preparations: [Link.self],
                   providers: [VaporSQLite.Provider.self])

let clientID = drop.config["app", "csh", "client-id"]?.string ?? ""
let clientSecret = drop.config["app", "csh", "client-secret"]?.string ?? ""
let cshRealm = CSH(clientID: clientID, clientSecret: clientSecret)

let linkController = LinkController(droplet: drop)
drop.resource("links", linkController)

let authMiddleware = AuthMiddleware(user: CSHAccount.self, realm: cshRealm)

drop.get(String.self) { request, code in
  guard let link = try Link.query().filter("code", code).first() else {
    return try Response(status: .notFound, json: JSON([
        "reason": .string("Could not find a link for \(code). " +
                          "Check the code and try again.")
    ]))
  }
  return try linkController.show(request: request, item: link)
}

drop.get("login") { request in
    let state = URandom().secureToken
    let url = cshRealm.getLoginLink(redirectURL: "http://localhost:8080/csh/consumer", state: state)
    let response = Response(redirect: url.absoluteString)
    response.cookies["csh-link-auth-state"] = state
    return response
}

func requireAuthorization(request: Request, handler: (Request, CSHAccount) throws -> ResponseRepresentable) rethrows -> ResponseRepresentable {
    let user: CSHAccount
    do {
        user = try request.auth.user() as! CSHAccount
    } catch {
        return Response(redirect: "http://localhost:8080/login")
    }
    return try handler(request, user)
}

drop.group(authMiddleware) { group in
    
    group.get("csh", "consumer") { request in
        let url = request.uri.description
        guard let state = request.cookies["csh-link-auth-state"] else {
            throw RequestError.csrfViolation
        }
        let cshAccount =
            try cshRealm.authenticate(authorizationCodeCallbackURL: url,
                                      state: state) as! CSHAccount
        
        try request.auth.login(cshAccount)
        
        return Response(redirect: "http://localhost:8080")
    }
    
    group.post { request in
        do {
            return try requireAuthorization(request: request) { request, user  in
                guard let json = request.json else {
                    throw RequestError.noData
                }
                let urlString: String = try json.extract("url")
                let code: String? = try json.extract("code")
                let url = try URL(validating: urlString)
                return try linkController.create(url: url, creator: user, code: code)
            }
        } catch {
            return try Response(status: .badRequest, json: JSON([
                "reason": .string("Invalid request parameters: \(error).")
            ]))
        }
    }
    
    group.get { request in
        return requireAuthorization(request: request) { request, user in
            return Response(body: "logged in as \(user.commonName)")
        }
    }
}

let port = drop.config["servers", "default", "port"]?.int ?? 80

drop.run()
