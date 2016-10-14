import Foundation
import Darwin

enum URLError: Error {
    case notAURL
    case noHost
    case cannotLinkToMe
}

extension URL {
    init(validating string: String) throws {
        var string = string
        
        // HACK: Add scheme if none is provided
        let schemeRegex = try! NSRegularExpression(pattern: "\\w+://", options: [])
        if schemeRegex.numberOfMatches(in: string,
                                       options: [],
                                       range: NSRange(location: 0, length: string.characters.count)) == 0 {
            string = "http://\(string)"
        }
        
        guard let url = URL(string: string) else {
            throw URLError.notAURL
        }
        guard url.host != nil else {
            throw URLError.noHost
        }
        guard url.host != "csh.link" else {
            throw URLError.cannotLinkToMe
        }
        self = url
    }
}
