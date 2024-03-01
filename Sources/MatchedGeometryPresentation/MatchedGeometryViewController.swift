//
//  MatchedGeometryViewController.swift
//  MatchedGeometryPresentation
//
//  Created by Quentin Fasquel on 01/03/2024.
//

import Combine
import SwiftUI

fileprivate let springAnimation = Animation.interpolatingSpring(mass: 1, stiffness: 150, damping: 15, initialVelocity: 0)
fileprivate let springTimingParameters = UISpringTimingParameters(mass: 1, stiffness: 150, damping: 15, initialVelocity: .zero)

final class MatchedGeometryViewController<Content: View>: UIViewController, UIViewControllerTransitioningDelegate {

    let sources: [AnyHashable: (AnyView, CGRect, Double)]
    let content: Content
    let state: MatchedGeometryState

    var contentHost: UIHostingController<ContentContainerView<Content>>!
    var matchedHost: UIHostingController<MatchedContainerView>!

    required init(
        sources: [AnyHashable: (AnyView, CGRect, Double)],
        content: Content,
        state: MatchedGeometryState
    ) {
        self.sources = sources
        self.content = content
        self.state = state
        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .overFullScreen
        transitioningDelegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let sources = sources.map {
            (id: $0.key, view: $0.value.0, frame: $0.value.1, zIndex: $0.value.2)
        }

        let matchedContainer = MatchedContainerView(
            sources: sources,
            state: state
        )

        matchedHost = UIHostingController(rootView: matchedContainer)
        matchedHost.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        matchedHost.view.frame = view.bounds
        matchedHost.view.backgroundColor = .clear
        matchedHost.view.layer.zPosition = 100
        addChild(matchedHost)
        view.addSubview(matchedHost.view)
        matchedHost.didMove(toParent: self)

        let contentContainer = ContentContainerView(content: content, state: state)
        contentHost = UIHostingController(rootView: contentContainer)
        contentHost.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentHost.view.frame = view.bounds
        contentHost.view.backgroundColor = .clear
        addChild(contentHost)
        view.addSubview(contentHost.view)
        contentHost.didMove(toParent: self)
    }

    // MARK: - Transitioning Delegate

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        MatchedGeometryPresentationAnimationController<Content>()
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        MatchedGeometryDismissalAnimationController<Content>()
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        state.isDismissInteractive ? MatchedGeometryDismissInteraction<Content>(state: state) : nil
    }
}

// MARK: - Presentation Animation Controller

fileprivate class MatchedGeometryPresentationAnimationController<Content: View>: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 1
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let presented = transitionContext.viewController(forKey: .to) as! MatchedGeometryViewController<Content>
        let container = transitionContext.containerView
        container.backgroundColor = .clear
        container.addSubview(presented.view!)
        presented.contentHost?.view.layer.opacity = 0

        let cancellable = presented.state.$destinations
            .filter { destinations in
                presented.sources.allSatisfy { source in
                    destinations.keys.contains(source.key)
                }
            }
            .first()
            .sink { _ in
                // presented.addMatchedHostingController()
                presented.state.dismissEnded = false
                presented.state.dismissProgress = 0
                presented.state.mode = .presenting
                presented.state.currentFrames = presented.sources.mapValues(\.1)
                DispatchQueue.main.async {
                    presented.state.animating = true
                    presented.state.currentFrames = presented.state.destinations.mapValues(\.1)
                }
            }

        let animator = UIViewPropertyAnimator(
            duration: transitionDuration(using: transitionContext),
            timingParameters: springTimingParameters
        )

        animator.addAnimations {
            presented.contentHost?.view.layer.opacity = 1
        }

        animator.addCompletion { _ in
            transitionContext.completeTransition(true)
            presented.state.isBeingPresented = false
            presented.state.animating = false
            cancellable.cancel()
            presented.matchedHost?.view.isHidden = true
        }

        presented.state.animating = true
        animator.startAnimation()
    }
}

// MARK: - Dismissal Animation Controller

fileprivate class MatchedGeometryDismissalAnimationController<Content: View>: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 1
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let presented = transitionContext.viewController(forKey: .from) as! MatchedGeometryViewController<Content>

        let container = transitionContext.containerView
        container.addSubview(presented.view)

        presented.matchedHost?.view.isHidden = false
        presented.state.mode = .dismissing
        presented.state.currentFrames = presented.state.destinations.mapValues(\.1)
        DispatchQueue.main.async {
            presented.state.animating = true
            presented.state.currentFrames = presented.sources.mapValues(\.1)
        }

        let animator = UIViewPropertyAnimator(
            duration: transitionDuration(using: transitionContext),
            timingParameters: springTimingParameters)

        animator.addAnimations {
            presented.contentHost?.view.layer.opacity = 0
        }

        animator.addCompletion { _ in
            transitionContext.completeTransition(true)
            presented.state.animating = false
        }

        presented.state.animating = true
        animator.startAnimation()
    }
}

// MARK: - MatchedGeometryInteractiveDismissTransition

class MatchedGeometryDismissInteraction<Content: View>: NSObject, UIViewControllerInteractiveTransitioning {

    private unowned let state: MatchedGeometryState
    private var cancellables = Set<AnyCancellable>()
    private var isInteractive: Bool = true
    private var isStarted: Bool = false

    init(state: MatchedGeometryState) {
        self.state = state
    }

    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        guard !isStarted else { return }

        isStarted = true

        let presented = transitionContext.viewController(forKey: .from) as! MatchedGeometryViewController<Content>
        presented.state.animating = true
        presented.state.mode = .dismissing

        presented.matchedHost?.view.isHidden = false

        state.$dismissProgress.sink { progress in
            presented.contentHost?.view.alpha = 1 - progress
            transitionContext.updateInteractiveTransition(progress)
        }.store(in: &cancellables)

        state.$dismissEnded.sink { ended in
            transitionContext.finishInteractiveTransition()
        }
        .store(in: &cancellables)

        state.dismissCompletion = {
            // TODO: According to velocity and progress, possibly cancel transition
            transitionContext.completeTransition(true)
            presented.state.animating = false
            presented.state.isDismissInteractive = false
            presented.state.dismissCompletion = nil
        }
    }
}

// MARK: - Content Container View

struct ContentContainerView<Content: View>: View {
    var content: Content
    var state: MatchedGeometryState

    var body: some View {
        content.environmentObject(state)
    }
}

// MARK: - Matched Container View

struct MatchedContainerView: View {
    let sources: [(id: AnyHashable, view: AnyView, frame: CGRect, zIndex: Double)]
    @ObservedObject var state: MatchedGeometryState

    var body: some View {
        ZStack {
            ForEach(sources, id: \.id) { (id, view, frame, zIndex) in
                matchedView(id: id, sourceView: view, sourceFrame: frame)
                    .zIndex(zIndex)
            }
        }
        .onChange(of: state.dismissEnded) { newValue in
            if newValue {
                var transaction = Transaction(animation: .interpolatingSpring)
                if #available(iOS 17, *) {
                    transaction.addAnimationCompletion {
                        state.dismissCompletion?()
                    }
                }
                withTransaction(transaction) {
                    state.dismissProgress = 1
                }
            }
        }
    }

    var progress: CGFloat {
        state.dismissProgress
    }

    @ViewBuilder func matchedView(id: AnyHashable, sourceView: AnyView, sourceFrame: CGRect) -> some View {
        if let frame = state.currentFrames[id], let destinationView = state.destinations[id]?.0 {
            let destinationOpacity: Double = switch state.mode {
            case .presenting: state.animating ? 1 : 0
            default: state.animating ? 0 : 1
            }

            ZStack {
                sourceView
                destinationView.opacity(destinationOpacity)
            }
            .frame(
                width: frame.width + (sourceFrame.width - frame.width) * progress,
                height: frame.height + (sourceFrame.height - frame.height) * progress
            )
            .position(
                x: frame.midX + (sourceFrame.midX - frame.midX) * progress,
                y: frame.midY + (sourceFrame.midY - frame.midY) * progress)
            .ignoresSafeArea()
            .animation(springAnimation, value: frame)
        } else {
            EmptyView()
        }
    }
}
