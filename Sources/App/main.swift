import Vapor
import HTTP
import VaporSQLite
import Foundation

let drop = Droplet(preparations: [Link.self], providers: [VaporSQLite.Provider.self])

let _ = drop.config["app", "key"]?.string ?? ""

let linkController = LinkController(droplet: drop)
drop.resource("links", linkController)

drop.get(String.self) { request, code in
  guard let link = try Link.query().filter("code", code).first() else {
    return try Response(status: .notFound, json: JSON([
        "reason": .string("no link for \(code)")
    ]))
  }
  return try linkController.show(request: request, item: link)
}

drop.post { request in
  guard
    let json = request.json,
    let urlString: String = try json.extract("url") else {
      return try Response(status: .badRequest, json: JSON([
        "reason": "a url is required"
      ]))
  }
  let code: String? = try json.extract("code")
  let url = try URL(validating: urlString)
  // Possible states:
  //   - Duplicate code
  //     - Error if URL is different
  //   - Duplicate URL
  //     - If code is not provided, just use that.
  //     - Otherwise, fall through make a new one.
  if
    let code = code,
    let link = try Link.query()
                       .filter("code", code)
                       .filter("active", true).first() {
    if url == link.url {
      return try link.makeResponse()
    } else {
      return try Response(status: .badRequest, json: JSON([
        "reason": .string("a link already exists for \(code)")
      ]))
    }
  } else if let link = try Link.query()
                               .filter("url", url.absoluteString)
                               .filter("active", true).first() {
    if code == nil {
      return try link.makeResponse()
    }
  }
  
  var link = try Link(url: url, code: code)
  try link.save()
  
  return try link.makeResponse()
}

let port = drop.config["app", "port"]?.int ?? 80

drop.serve()
