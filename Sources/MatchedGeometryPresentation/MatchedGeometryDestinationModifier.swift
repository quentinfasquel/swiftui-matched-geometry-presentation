//
//  MatchedGeometryDestinationModifier.swift
//  MatchedGeometryPresentation
//
//  Created by Quentin Fasquel on 01/03/2024.
//

import SwiftUI

struct MatchedGeometryDestinationFrameKey: PreferenceKey {
    static let defaultValue: CGRect? = nil
    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = nextValue()
    }
}

fileprivate struct MatchedGeometryDestinationModifier<Matched: View>: ViewModifier {
    @EnvironmentObject private var state: MatchedGeometryState

    var id: AnyHashable
    var matched: Matched

    func body(content: Content) -> some View {
        content.background(GeometryReader { proxy in
            Color.clear
                .preference(
                    key: MatchedGeometryDestinationFrameKey.self,
                    value: proxy.frame(in: .global)
                )
                .onPreferenceChange(MatchedGeometryDestinationFrameKey.self) { newValue in
                    if let newValue {
                        state.destinations[id] = (AnyView(matched), newValue)
                    }
                }
        })
        .opacity(state.animating ? 0 : 1)
    }
}

extension View {
    public func matchedGeometryDestination<ID: Hashable>(id: ID) -> some View {
        self.modifier(MatchedGeometryDestinationModifier(
            id: AnyHashable(id),
            matched: self
        ))
    }
}
