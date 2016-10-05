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
    
    func extractAddress(request: Request) -> String? {
        guard let peer =  request.peerAddress?.address() else {
            return nil
        }
        let components = peer.components(separatedBy: ":")
        if components.count > 1 {
            return components[0]
        }
        return peer
    }
    
    func show(request: Request, item link: Link) throws -> ResponseRepresentable {
        do {
            var visit = try Visit(parent: link, visitorAddress: extractAddress(request: request))
            try visit.save()
        } catch {
            drop.log.error("failed to register visit: \(error)")
        }
        return Response(redirect: link.url.absoluteString)
    }
    
    func update(request: Request, item link: Link) throws -> ResponseRepresentable {
        guard let json = request.json else {
            throw RequestError.noData
        }
        
        let user = try request.auth.user() as! CSHAccount
        
        guard link.creator == user.uuid else {
            return try Response(status: .unauthorized, json: JSON([
                "reason": .string("You are not authorized to update \(link.code)")
            ]))
        }
        var link = link
        let urlString: String = try json.extract("url")
        let url = try URL(validating: urlString)
        link.url = url
        try link.save()
        return link.makeJSON()
    }
    
    func destroy(request: Request, item link: Link) throws -> ResponseRepresentable {
        let user = try request.auth.user() as! CSHAccount
        guard link.creator == user.uuid else {
            return try Response(status: .unauthorized, json: JSON([
                "reason": .string("You are not authorized to delete \(link.code)")
            ]))
        }
        var link = link
        link.active = false
        try link.save()
        return link
    }
    
    func create(url: URL, creator: CSHAccount, code: String? = nil) throws -> ResponseRepresentable {
        // If there is a duplicate code, then give an error if the submitted URL is different.
        if let code = code,
           let link = try Link.forCode(code) {
            if url == link.url {
                return try link.makeResponse()
            } else {
                return try Response(status: .badRequest, json: JSON([
                    "reason": .string("a link already exists for \(code)")
                ]))
            }
        }
        
        if let code = code {
            guard code.isValidShortCode else {
                throw LinkError.invalidShortCode
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

extension String {
    var isValidShortCode: Bool {
        guard self.count <= 128 else { return false }
        var validChars = CharacterSet.alphanumerics
        validChars.insert(charactersIn: "_-")
        for char in unicodeScalars where !validChars.contains(char) {
            return false
        }
        return true
    }
}
