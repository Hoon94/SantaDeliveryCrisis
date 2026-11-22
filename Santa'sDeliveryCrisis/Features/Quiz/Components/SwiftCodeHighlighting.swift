import Foundation
import SwiftUI

/// 코드 내용을 바꾸지 않고 Swift의 주요 문법에 표시용 색상을 입힌다.
enum SwiftCodeHighlighting {
    /// 문자열과 주석을 먼저 묶어 그 안의 예약어나 숫자를 별도로 칠하지 않는다.
    private static let tokens = try? NSRegularExpression(pattern: #"""
        (?<comment> //[^\r\n]* | /\*[\s\S]*?\*/ )
        | (?<string> """[\s\S]*?""" | "(?:\\[\s\S]|[^"\\])*" )
        | (?<keyword> @[A-Za-z_]\w* | \b(?:actor|any|as|associatedtype|async|await|break|case|catch|class|continue|convenience|default|defer|deinit|didSet|do|else|enum|extension|false|fileprivate|final|for|func|get|guard|if|import|in|indirect|init|inout|internal|is|isolated|lazy|let|mutating|nil|nonisolated|nonmutating|open|operator|optional|override|private|protocol|public|repeat|required|rethrows|return|self|Self|set|some|static|struct|subscript|super|switch|throw|throws|true|try|typealias|unowned|var|weak|where|while|willSet)\b )
        | (?<number> \b(?:0[xX][\da-fA-F_]+|0[bB][01_]+|0[oO][0-7_]+|\d[\d_]*(?:\.\d[\d_]*)?(?:[eE][+-]?\d[\d_]*)?)\b )
        | (?<type> \b[A-Z][A-Za-z0-9_]*\b )
        """#, options: .allowCommentsAndWhitespace)

    /// 원문의 공백·개행·이모지를 유지하고 찾아낸 문법에만 색상을 적용한다.
    static func text(_ code: String) -> AttributedString {
        guard let tokens else { return AttributedString(code) }
        var result = AttributedString()
        var cursor = code.startIndex
        let range = NSRange(code.startIndex..<code.endIndex, in: code)

        for match in tokens.matches(in: code, range: range) {
            guard let tokenRange = Range(match.range, in: code) else { continue }
            result.append(AttributedString(String(code[cursor..<tokenRange.lowerBound])))
            var token = AttributedString(String(code[tokenRange]))
            if match.range(withName: "comment").location != NSNotFound {
                token.foregroundColor = .nightSecondaryText
            } else if match.range(withName: "string").location != NSNotFound {
                token.foregroundColor = .codeString
            } else if match.range(withName: "keyword").location != NSNotFound {
                token.foregroundColor = .codeKeyword
            } else if match.range(withName: "number").location != NSNotFound {
                token.foregroundColor = .codeNumber
            } else {
                token.foregroundColor = .codeType
            }
            result.append(token)
            cursor = tokenRange.upperBound
        }
        result.append(AttributedString(String(code[cursor...])))
        return result
    }
}
