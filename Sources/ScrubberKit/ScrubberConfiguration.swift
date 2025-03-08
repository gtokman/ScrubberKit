//
//  ScrubberConfiguration.swift
//  ScrubberKit
//
//  Created by 秋星桥 on 2/22/25.
//

import Foundation
import WebKit

public enum ScrubberConfiguration {
    public static var disabledEngines: Set<ScrubEngine> = []

    public static func setup() {
        ScrubWorker.compileAccessRules()
    }
}
