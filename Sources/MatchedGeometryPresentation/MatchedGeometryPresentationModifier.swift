//
//  MatchedGeometryPresentationModifier.swift
//  MatchedGeometryPresentation
//
//  Created by Quentin Fasquel on 01/03/2024.
//

import SwiftUI

fileprivate enum DismissProgressEnvironmentKey: EnvironmentKey {
    static var defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    public var dismissProgress: CGFloat {
        get { self[DismissProgressEnvironmentKey.self] }
        set { self[DismissProgressEnvironmentKey.self] = newValue }
    }
}

fileprivate struct MatchedGeometryPresentationModifier<Presented: View>: ViewModifier {
    @Binding var isPresented: Bool
    var presented: Presented
    @StateObject private var state = MatchedGeometryState()
    @Environment(\.dismissProgress) private var dismissProgress

    func body(content: Content) -> some View {
        content
            .environmentObject(state)
            .backgroundPreferenceValue(MatchedGeometrySourcesKey.self) { sources in
                Color.clear.presentViewController(isPresented: $isPresented, makeVC(sources: sources))
            }
            .onChange(of: dismissProgress) { newValue in
                state.dismissProgress = newValue
            }
    }

    private func makeVC(sources: [AnyHashable: (AnyView, CGRect, Double)]) -> () -> UIViewController {
        return { MatchedGeometryViewController(sources: sources, content: presented, state: state) }
    }
}

public extension View {
    func matchedGeometryPresentation<P: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder presenting: () -> P
    ) -> some View {
        modifier(MatchedGeometryPresentationModifier(
            isPresented: isPresented,
            presented: presenting()
        ))
    }
}
