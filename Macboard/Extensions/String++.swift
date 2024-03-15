import Foundation

extension String {
    var isValidURL: Bool {
        if self.hasPrefix("file://") || self.hasPrefix("/") {
            return false
        }
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
            return match.range.length == self.utf16.count
        } else {
            return false
        }
    }
}

extension String  {
    var isNum: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
}

extension String {
    var isValidColor: Bool {
        guard let regex = try? NSRegularExpression(pattern: "^#(?:[0-9a-fA-F]{2}){3,4}$") else { return false }
        let range = NSRange(location: 0, length: self.utf16.count)
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }
}
