//
//  Scrubber+Options.swift
//  ScrubberKit
//
//  Created by John Mai on 2025/3/15.
//

extension Scrubber {
    public struct ScrubberOptions {
        let urlsReranker: URLsReranker?
        
        public init(urlsReranker: URLsReranker? = nil) {
            self.urlsReranker = urlsReranker
        }
    }
}
