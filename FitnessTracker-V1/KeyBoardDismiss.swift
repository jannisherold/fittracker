import SwiftUI
import UIKit

extension View {
    /// Blendet die iOS-Tastatur aus (resigns first responder)
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
