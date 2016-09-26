import Vapor
import HTTP
import TurnstileCSH
import Foundation

final class LinkController: ResourceRepresentable {
  typealias Item = Link
  
  let drop: Droplet
  init(droplet: Droplet) {
    drop = droplet
  }
  
  func index(request: Request) throws -> ResponseRepresentable {
    return try JSON(node: [
      "controller": "LinkController.index"
      ])
  }
  
  func store(request: Request) throws -> ResponseRepresentable {
    let link = try Link(node: request.json)
    return try link.makeResponse()
  }
  
  func show(request: Request, item link: Link) throws -> ResponseRepresentable {
    return Response(redirect: link.url.absoluteString)
  }
  
  func update(request: Request, item link: Link) throws -> ResponseRepresentable {
    return link.makeJSON()
  }
  
  func destroy(request: Request, item link: Link) throws -> ResponseRepresentable {
    return link
  }

  func create(url: URL, creator: CSHAccount, code: String? = nil) throws -> ResponseRepresentable {
    // If there is a duplicate code, then give an error if the submitted URL is different.
    if let code = code,
      let link = try Link.query()
        .filter("code", .equals, code)
        .filter("active", .equals, true).first() {
      if url == link.url {
        return try link.makeResponse()
      } else {
        return try Response(status: .badRequest, json: JSON([
          "reason": .string("a link already exists for \(code)")
          ]))
      }
    }
    
    var link = try Link(url: url, code: code, creator: creator.uuid)
    try link.save()
    
    return try link.makeResponse()
  }
  
  func makeResource() -> Resource<Link> {
    return Resource(
      index: index,
      store: store,
      show: show,
      replace: update,
      destroy: destroy
    )
  }
}
