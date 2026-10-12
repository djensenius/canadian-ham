import SwiftUI

#if os(iOS)
import UIKit
#endif

extension View {
    /// Constrains a scroll container to the area below an opaque iOS navigation bar.
    ///
    /// SwiftUI navigation stacks allow scroll content to move underneath the navigation bar even when
    /// the bar background is opaque. This modifier measures the navigation bar's lower edge in window
    /// coordinates, keeps the scroll view's viewport below that edge, and clips the scroll container
    /// there so descendants do not draw or receive taps under the bar. Non-iOS platforms keep the
    /// original layout.
    @ViewBuilder
    func clippedBelowOpaqueNavigationBar() -> some View {
#if os(iOS)
        modifier(ClippedBelowOpaqueNavigationBarModifier())
#else
        self
#endif
    }
}

#if os(iOS)
private struct ClippedBelowOpaqueNavigationBarModifier: ViewModifier {
    @State private var topClipInset: CGFloat = 0

    func body(content: Content) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: topClipInset)
                        .accessibilityHidden(true)
                    content
                        .frame(width: proxy.size.width, height: max(proxy.size.height - topClipInset, 0), alignment: .top)
                        .clipped()
                }
                NavigationBarClipInsetReader(topClipInset: $topClipInset)
                    .frame(width: 0, height: 0)
                    .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea(.container, edges: .top)
    }
}

private struct NavigationBarClipInsetReader: UIViewRepresentable {
    @Binding var topClipInset: CGFloat

    func makeUIView(context _: Context) -> UIView {
        UIView(frame: .zero)
    }

    func updateUIView(_ view: UIView, context _: Context) {
        DispatchQueue.main.async {
            let inset = measuredTopClipInset(from: view)
            if abs(topClipInset - inset) > 0.5 {
                topClipInset = inset
            }
        }
    }

    private func measuredTopClipInset(from view: UIView) -> CGFloat {
        guard let window = view.window else { return topClipInset }
        let containerMinY = view.convert(view.bounds, to: nil).minY
        let navigationBarMaxY = enclosingNavigationController(for: view)
            .map { $0.navigationBar.convert($0.navigationBar.bounds, to: nil).maxY } ?? 0
        let safeAreaMaxY = window.safeAreaInsets.top
        return max(max(navigationBarMaxY, safeAreaMaxY) - containerMinY, 0)
    }

    private func enclosingNavigationController(for view: UIView) -> UINavigationController? {
        var responder: UIResponder? = view
        while let current = responder {
            if let navigationController = current as? UINavigationController {
                return navigationController
            }
            responder = current.next
        }
        return view.window?.rootViewController?.descendantNavigationController
    }
}

private extension UIViewController {
    var descendantNavigationController: UINavigationController? {
        if let navigationController = self as? UINavigationController {
            return navigationController
        }
        for child in children {
            if let navigationController = child.descendantNavigationController {
                return navigationController
            }
        }
        return presentedViewController?.descendantNavigationController
    }
}
#endif
