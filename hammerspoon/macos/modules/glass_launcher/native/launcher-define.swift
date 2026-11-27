import CoreServices
import Foundation

func definitionSummary(_ text: String) -> String {
    var summary = text.split(whereSeparator: \.isWhitespace).joined(separator: " ")

    // This dictionary concatenates its headword, pronunciation and study labels.
    let labels = #"(?:(?:Oxford\s*(?:3000|5000)|Collins\s*[1-5]\s*★)\s*)*"#
    let head = #"^[^/]+/[^/]+/\s*"# + labels + #"(?=[a-z]{1,8}\.\s*\[?\p{Han})"#
    if let range = summary.range(of: head, options: .regularExpression) {
        summary.removeSubrange(range)
    }

    let frequency = #"\s*(?:BNC|COCA)\s*#\s*\d[\d,]*(?:\s*·\s*(?:BNC|COCA)\s*#\s*\d[\d,]*)*\s*$"#
    summary = summary.replacingOccurrences(of: frequency, with: "", options: .regularExpression)
    let exams = #"(?:中考|高考|考研|专四|专八|CET[- ]?[46]|IELTS|TOEFL|GRE|SAT|TEM[- ]?[48])"#
    let study = #"\s*考试[：:]\s*"# + exams + #"(?:\s*·\s*"# + exams + #")*\s*$"#
    return summary.replacingOccurrences(of: study, with: "", options: .regularExpression)
}

guard CommandLine.arguments.count == 2 else { exit(1) }
let term = CommandLine.arguments[1] as CFString
let range = CFRange(location: 0, length: CFStringGetLength(term))
guard range.length > 0, let definition = DCSCopyTextDefinition(nil, term, range) else { exit(1) }
let text = definition.takeRetainedValue() as String
print(definitionSummary(text).prefix(700))
