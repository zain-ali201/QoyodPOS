import UIKit

// MARK: - State

/// Barcode scanner state.
enum State {
  case scanning
  case processing
  case unauthorized
  case notFound
}

/// State message provider.
public struct StateMessageProvider
{
    
  public var scanningText = localizedString("INFO_DESCRIPTION_TEXT")
  public var processingText = localizedString("INFO_LOADING_TITLE")
  public var unathorizedText = localizedString("ASK_FOR_PERMISSION_TEXT")
  public var notFoundText = localizedString("NO_PRODUCT_ERROR_TITLE")

    mutating func makeText(for state: State) -> String
    {
    
        var languageCode = Locale.current.languageCode
        
        if UserDefaults.standard.value(forKey: "language") != nil
        {
            languageCode = UserDefaults.standard.value(forKey: "language") as! String
        }
        
        if languageCode == "ar"
        {
            scanningText = "ضع الباركود داخل الإطار للمسح"
        }
        else
        {
            scanningText = "Place the barcode within the window to Scan."
        }
        
        switch state
        {
            case .scanning:
              return scanningText
            case .processing:
              return processingText
            case .unauthorized:
              return unathorizedText
            case .notFound:
              return notFoundText
        }
    }
}

// MARK: - Status

/// Status is a holder of the current state with a few additional configuration properties.
struct Status {
  /// The current state.
  let state: State
  /// Flag to enable/disable animation.
  let animated: Bool
  /// Text that overrides a text from the state.
  let text: String?

  /**
   Creates a new instance of `Status`.
   - Parameter state: State value.
   - Parameter animated: Flag to enable/disable animation.
   - Parameter text: Text that overrides a text from the state.
   */
  init(state: State, animated: Bool = true, text: String? = nil) {
    self.state = state
    self.animated = animated
    self.text = text
  }
}
