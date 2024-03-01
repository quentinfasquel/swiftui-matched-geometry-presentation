//
//  MatchedGeometryState.swift
//  MatchedGeometryPresentation
//
//  Created by Quentin Fasquel on 01/03/2024.
//

import Foundation
import SwiftUI

public final class MatchedGeometryState: ObservableObject {
    @Published var destinations: [AnyHashable: (AnyView, CGRect)] = [:]
    @Published var animating: Bool = false
    @Published var currentFrames: [AnyHashable: CGRect] = [:]
    @Published var mode: Mode = .presenting

    @Published public var isBeingPresented: Bool = false
    @Published public var isDismissInteractive: Bool = false
    @Published public var dismissProgress: CGFloat = 0
    @Published public var dismissEnded: Bool = false
    var dismissCompletion: (() -> Void)?

    enum Mode {
        case presenting, dismissing
    }

    public init() {}
}
