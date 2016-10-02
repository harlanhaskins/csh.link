import Leaf
import Foundation

struct FormatDate: BasicTag {
    enum FormatDateError: Error {
        case noArg
        case notANumber
    }
    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()
    public let name = "date"
    func run(arguments: [Argument]) throws -> Node? {
        guard let arg = arguments.first?.value else {
            throw FormatDateError.noArg
        }
        guard let timeVal = arg.double else {
            throw FormatDateError.notANumber
        }
        let date = Date(timeIntervalSince1970: timeVal)
        return .string(FormatDate.formatter.string(from: date))
    }
}
