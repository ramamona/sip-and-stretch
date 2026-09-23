import SwiftUI

/// Drop-in replacement for `@State`.
///
/// Starting with the macOS 27 SDK, `@State` is a Swift macro whose compiler plugin ships with Xcode
/// but not with the Command Line Tools. This wrapper stores a plain `State<Value>` (which SwiftUI
/// discovers like any other dynamic property), so the app builds with either toolchain.
/// Once the Command Line Tools include `SwiftUIMacros`, this can go back to `@State`.
@propertyWrapper
struct ViewState<Value>: DynamicProperty {
    private let storage: State<Value>

    init(wrappedValue: Value) {
        storage = State(initialValue: wrappedValue)
    }

    var wrappedValue: Value {
        get { storage.wrappedValue }
        nonmutating set { storage.wrappedValue = newValue }
    }

    var projectedValue: Binding<Value> { storage.projectedValue }
}
