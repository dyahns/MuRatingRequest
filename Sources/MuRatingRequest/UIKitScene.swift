#if canImport(UIKit)

import UIKit

@available(iOS 13.0, *)
extension UIApplication {
    var foregroundActiveScene: UIWindowScene? {
        connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
    }
}

#endif
