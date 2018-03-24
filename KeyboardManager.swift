//
//  KeyboardManager.swift
//
//  Created by Roman Madyanov on 19/01/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit

class KeyboardManager: NSObject {
    var spacing: CGFloat = 8

    private weak var view: UIView?

    private lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTap))
        tapGestureRecognizer.cancelsTouchesInView = false
        tapGestureRecognizer.delegate = self
        return tapGestureRecognizer
    }()

    func start() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: .UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldDidBeginEditing), name: .UITextFieldTextDidBeginEditing, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldDidEndEditing), name: .UITextFieldTextDidEndEditing, object: nil)
    }

    func stop() {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UITextFieldTextDidBeginEditing, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UITextFieldTextDidEndEditing, object: nil)
    }
}

extension KeyboardManager {
    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let view = view,
            let window = UIApplication.shared.windows.first,
            let rootView = view.viewController?.view,
            let userInfo = notification.userInfo,
            let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let animationDuration: TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue,
            let animationCurve = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue else {
            return
        }

        let viewFrameInWindow = window.convert(view.frame, from: view.superview)
        let viewYOffsetFromBottom = rootView.frame.minY + window.bounds.height - viewFrameInWindow.maxY
        let keyboardHeight = window.bounds.height - keyboardFrame.minY
        let offset = min(0, viewYOffsetFromBottom - keyboardHeight - spacing)

        // workaround
        // search for UIView-Encapsulated-Layout-Top autoresizing mask constraint
        // constraint.firstAttribute.rawValue == 33
        let constraint = rootView.constraints.first { $0.firstItem === rootView && $0.identifier == "UIView-Encapsulated-Layout-Top" }
        constraint?.constant = offset

        UIView.animate(withDuration: max(0.2, animationDuration), delay: 0, options: [.beginFromCurrentState, UIViewAnimationOptions(rawValue: animationCurve)], animations: {
            if constraint != nil {
                rootView.layoutIfNeeded()
            } else {
                rootView.frame.origin.y = offset
            }
        }, completion: nil)
    }

    @objc private func textFieldDidBeginEditing(_ notification: Notification) {
        view = notification.object as? UIView
        view?.window?.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc private func textFieldDidEndEditing() {
        view?.window?.removeGestureRecognizer(tapGestureRecognizer)
        view = nil
    }

    @objc private func didTap(_ recognizer: UIGestureRecognizer) {
        view?.resignFirstResponder()
    }
}

extension KeyboardManager: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        for type in [UIControl.self, UINavigationBar.self] {
            if touch.view?.isKind(of: type) ?? false {
                return false
            }
        }

        return true
    }
}

private extension UIView {
    var viewController: UIViewController? {
        var parentResponder: UIResponder? = self

        while parentResponder != nil {
            parentResponder = parentResponder?.next

            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }

        return nil
    }
}
