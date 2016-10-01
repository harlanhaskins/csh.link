import Vapor
import TurnstileCSH
import TurnstileCrypto
import Auth
import HTTP
import URI
import Foundation

struct CSHMiddleware: Middleware {
    let authMiddleware: AuthMiddleware<CSHAccount>
    init(droplet: Droplet, clientID: String, clientSecret: String) {
        let cshRealm = CSH(clientID: clientID, clientSecret: clientSecret)
        droplet.get("csh", "login") { request in
            let state = URandom().secureToken
            let redirect = request.uri
                .deletingLastPathComponent()
                .appendingPathComponent("consumer")
                .description
            
            let url = cshRealm.getLoginLink(redirectURL: redirect,
                                            state: state)
            let response = Response(redirect: url.absoluteString)
            response.cookies["csh-link-auth-state"] = state
            return response
        }
        authMiddleware = AuthMiddleware(user: CSHAccount.self, realm: cshRealm)
        droplet.group(authMiddleware) { group in
            group.get("csh", "consumer") { request in
                guard let state = request.cookies["csh-link-auth-state"] else {
                    throw RequestError.csrfViolation
                }
                let cshAccount =
                    try cshRealm.authenticate(authorizationCodeCallbackURL: request.uri.description,
                                              state: state) as! CSHAccount
                
                try request.auth.login(cshAccount)
                var redirected = request.uri
                                        .removingPath()
                redirected.query = nil
                if let next = try request.query?.extract("next") as String? {
                    redirected = redirected.with(path: next)
                }
                return Response(redirect: redirected.description)
            }
        }
    }
    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        do {
            let _ = try request.auth.user() as! CSHAccount
        } catch {
            let newURI = request.uri
                                .removingPath()
                                .appendingPathComponent("csh")
                                .appendingPathComponent("login")
            // FIXME: Figure out a way to get this to remain percent escaped
            //        throughout the redirection.
//            newURI.append(query: [
//                "next": path.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
//            ])
            return Response(redirect: newURI.description)
        }
        return try next.respond(to: request)
    }
}

extension URI {
    func with(scheme: String? = nil,
              userInfo: UserInfo? = nil,
              host: String? = nil,
              port: Int? = nil,
              path: String? = nil,
              query: String? = nil,
              fragment: String? = nil) -> URI {
        return URI(scheme: scheme ?? self.scheme,
                   userInfo: userInfo ?? self.userInfo,
                   host: host ?? self.host,
                   port: port ?? self.port,
                   path: path ?? self.path,
                   query: query ?? self.query,
                   fragment: fragment ?? self.fragment)
    }
}
