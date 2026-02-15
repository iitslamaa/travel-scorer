//
//  CountryTextHelpers.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/15/26.
//

import Foundation

enum CountryTextHelpers {

    static func cleanAdvisory(_ text: String) -> String {
        var s = text

        s = s.replacingOccurrences(of: "\u{00A0}", with: " ")
        s = s.replacingOccurrences(of: "\u{200B}", with: "")
        s = s.replacingOccurrences(of: "\u{FEFF}", with: "")

        s = s.replacingOccurrences(of: "â€™", with: "’")
        s = s.replacingOccurrences(of: "â€œ", with: "“")
        s = s.replacingOccurrences(of: "â€", with: "”")
        s = s.replacingOccurrences(of: "â€“", with: "–")
        s = s.replacingOccurrences(of: "â€”", with: "—")
        s = s.replacingOccurrences(of: "â€¦", with: "…")
        s = s.replacingOccurrences(of: "Â", with: "")

        s = s.replacingOccurrences(of: "&amp;", with: "&")
        s = s.replacingOccurrences(of: "&quot;", with: "\"")
        s = s.replacingOccurrences(of: "&apos;", with: "'")
        s = s.replacingOccurrences(of: "&#39;", with: "'")
        s = s.replacingOccurrences(of: "&rsquo;", with: "’")
        s = s.replacingOccurrences(of: "&lsquo;", with: "‘")
        s = s.replacingOccurrences(of: "&rdquo;", with: "”")
        s = s.replacingOccurrences(of: "&ldquo;", with: "“")
        s = s.replacingOccurrences(of: "&hellip;", with: "…")
        s = s.replacingOccurrences(of: "&mdash;", with: "—")
        s = s.replacingOccurrences(of: "&ndash;", with: "–")

        s = s.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        while s.contains("  ") {
            s = s.replacingOccurrences(of: "  ", with: " ")
        }

        return s
    }
}
