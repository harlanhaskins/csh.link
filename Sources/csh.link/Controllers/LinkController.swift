import Vapor
import HTTP
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
