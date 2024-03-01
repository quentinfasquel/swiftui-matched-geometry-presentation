//
//  ViewControllerPresenter.swift
//  MatchedGeometryPresentation
//
//  Created by Quentin Fasquel on 01/03/2024.
//

import SwiftUI

fileprivate struct ViewControllerPresenter: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var makeViewController: () -> UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        return UIViewController()
    }

    func updateUIViewController(_ viewController: UIViewController, context: Context) {
        if isPresented {
            if viewController.presentedViewController == nil {
                let presented = makeViewController()
                viewController.present(presented, animated: true)
                presented.presentationController?.delegate = context.coordinator
                context.coordinator.didPresent = true
            }
        } else if context.coordinator.didPresent {
            if let presented = viewController.presentedViewController, !presented.isBeingDismissed {
                viewController.dismiss(animated: true)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(isPresented: $isPresented)
    }

    final class Coordinator: NSObject, UIAdaptivePresentationControllerDelegate {
        @Binding var isPresented: Bool
        var didPresent = false

        init(isPresented: Binding<Bool>) {
            _isPresented = isPresented
        }

        func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
//            isPresented = false
//            didPresent = false
        }
    }
}

extension View {
    func presentViewController(isPresented: Binding<Bool>, _ viewControllerBuilder: @escaping () -> UIViewController) -> some View {
        background(ViewControllerPresenter(isPresented: isPresented, makeViewController: viewControllerBuilder))
    }
}

