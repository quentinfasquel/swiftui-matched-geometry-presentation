//
//  MatchedGeometrySourceModifier.swift
//  MatchedGeometryPresentation
//
//  Created by Quentin Fasquel on 01/03/2024.
//

import SwiftUI

struct MatchedGeometrySourcesKey: PreferenceKey {
    typealias Value = [AnyHashable: (AnyView, CGRect, Double)]
    static let defaultValue: Value = [:]
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

fileprivate struct MatchedGeometrySourceModifier<Matched: View>: ViewModifier {
    @EnvironmentObject private var state: MatchedGeometryState

    var id: AnyHashable
    var matched: Matched
    var zIndex: Double

    func body(content: Content) -> some View {
        content.background(GeometryReader { proxy in
            Color.clear
                .preference(
                    key: MatchedGeometrySourcesKey.self,
                    value: [id: (AnyView(matched), proxy.frame(in: .global), zIndex)]
                )
        })
        .opacity(state.animating ? 0 : 1)
    }
}


public extension View {
    func matchedGeometrySource<ID: Hashable>(id: ID, zIndex: Double = 0) -> some View {
        self.modifier(MatchedGeometrySourceModifier(
            id: AnyHashable(id),
            matched: self,
            zIndex: zIndex
        ))
    }
}


