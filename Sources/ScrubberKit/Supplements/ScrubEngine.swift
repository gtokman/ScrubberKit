//
//  ScrubEngine.swift
//  Dealer
//
//  Created by 秋星桥 on 2/9/25.
//

import Foundation
import SwiftSoup

public enum ScrubEngine: String, CaseIterable, Codable {
    case google
    case duckduckgo
    case yahoo
    case bing

    var template: String {
        switch self {
        case .google:
            "https://www.google.com/search?q=%@"
        case .bing:
            "https://www.bing.com/search?q=%@"
        case .duckduckgo:
            "https://www.duckduckgo.com/?q=%@"
        case .yahoo:
            "https://search.yahoo.com/search?q=%@"
        }
    }

    func makeSearchQueryRequest(_ keyword: String) -> URL? {
        let encoder = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let text = String(format: template, encoder ?? "")
        guard let url = URL(string: text) else {
            return nil
        }
        return url
    }

    private func parse(body: Element) -> [String] {
        assert(!Thread.isMainThread)

        var ans: [String] = []
        switch self {
        case .google:
            try? body.select("#rso").forEach { object in
                for objectDiv in object.children() {
                    let linkText = try? objectDiv.select("[href]").array().first?.attr("href")
                    if let link = linkText, !link.isEmpty {
                        ans.append(link)
                    }
                }
            }
            return ans
        case .duckduckgo:
            try? body.select(".react-results--main").forEach { object in
                for listElement in object.children() {
                    let linkText = try? listElement
                        .select("[data-testid=result-title-a]")
                        .array()
                        .first?
                        .attr("href")
                    if let link = linkText, !link.isEmpty {
                        ans.append(link)
                    }
                }
            }
            return ans
        case .yahoo:
            try? body.select("#main-algo").forEach { object in
                try? object.select(".title").forEach { element in
                    let linkText = try? element.select("[href]").array().first?.attr("href")
                    if let link = linkText, !link.isEmpty {
                        ans.append(link)
                    }
                }
            }
            return ans
        case .bing:
            try? body.select("ol#b_results li.b_algo").forEach { algo in
                if let firstLink = try? algo.select("div.b_tpcn a[href]").first() {
                    if let linkElement = try? algo.select("div.b_algoheader a[href]").first() {
                        if let link = try? linkElement.attr("href"), !link.isEmpty {
                            ans.append(link)
                        }
                    } else if let link = try? firstLink.attr("href"), !link.isEmpty {
                        ans.append(link)
                    }
                }
            }
            return ans
        }
    }

    func parseSearchResult(_ html: String) -> [URL] {
        assert(!Thread.isMainThread)

        guard let soup = try? SwiftSoup.parse(html) else { return [] }
        guard let body = soup.body() else { return [] }

        var preflightAnwser: [String] = parse(body: body)
        if preflightAnwser.isEmpty {
            let fallback = try? body
                .select("a[href]")
                .array()
                .compactMap { try? $0.attr("href") }
            preflightAnwser = fallback ?? []
        }

        var possibleLinks: [String] = preflightAnwser
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { !$0.starts(with: "/") }
            .filter { !$0.starts(with: "#") }

        let searchContent = possibleLinks
        possibleLinks = possibleLinks
            .filter { candidate in
                // remove url that contains another url linking to it
                // https://translate.google.com/translate?u= (that link)
                !searchContent.contains { matchShorter in
                    candidate.contains(matchShorter) && candidate != matchShorter
                }
            }
            .filter { candidate in
                // remove url that lowercase is already in the list
                !possibleLinks.contains { matchLower in
                    candidate.lowercased() == matchLower.lowercased() && candidate != matchLower
                }
            }

        possibleLinks = .init(Set(possibleLinks)).sorted()

        let possibleURLs = possibleLinks
            .compactMap { URL(string: $0) }
            .filter { $0.scheme == "http" || $0.scheme == "https" }
            .filter { !($0.host?.isEmpty ?? true) }

        return possibleURLs
    }
}
