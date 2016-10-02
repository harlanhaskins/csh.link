import Leaf
import Foundation

enum EmptyTagError: Error {
    case invalidArguments(got: [Argument])
    case notAList
}

struct Empty: BasicTag {
    public let name = "empty"
    
    func run(arguments: [Argument]) throws -> Node? {
        return nil
    }
    
    func shouldRender(stem: Stem, context: Context, tagTemplate: TagTemplate, arguments: [Argument], value: Node?) -> Bool {
        guard arguments.count == 1 else {
            return false
        }
        guard let arg = arguments[0].value else {
            return false
        }
        switch arg {
        case .array(let nodes):
            return nodes.isEmpty
        case .string(let str):
            return str.isEmpty
        case .bytes(let bytes):
            return bytes.isEmpty
        case .null:
            return true
        case .object(let obj):
            return obj.isEmpty
        default:
            return false
        }
    }
}
