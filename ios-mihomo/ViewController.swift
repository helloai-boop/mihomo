//
//  ViewController.swift
//  ios-mihomo
//
//  Created by x on 2026/1/3.
//

import UIKit
import xxpc

class ViewController: UIViewController, UITextViewDelegate {

    private let configTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .systemBackground
        textView.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.1).cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        return textView
    }()

    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Connect", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 22
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        return button
    }()

    private let hideKeyboardButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            let image = UIImage(systemName: "keyboard.chevron.compact.down")
            button.setImage(image, for: .normal)
        } else {
            button.setTitle("Hide", for: .normal)
        }
        button.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.8)
        button.tintColor = .label
        button.layer.cornerRadius = 8
        button.isHidden = true // Only show when keyboard is up
        return button
    }()

    private var bottomConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardNotifications()
        setupVPNStatusObserver()
        WSParserManager.shared().setupVPNManager()
        let path = Bundle.main.path(forResource: "config", ofType: "yaml")
        let str = try! String(contentsOfFile: path!);
        
        // Default example config
        configTextView.text = str
        highlightYAML()
        updateButtonStatus()
    }

    private func setupUI() {
        view.addSubview(configTextView)
        view.addSubview(actionButton)
        view.addSubview(hideKeyboardButton)
        
        configTextView.delegate = self
        
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        hideKeyboardButton.addTarget(self, action: #selector(hideKeyboardTapped), for: .touchUpInside)

        bottomConstraint = actionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)

        NSLayoutConstraint.activate([
            configTextView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            configTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            configTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            configTextView.bottomAnchor.constraint(equalTo: actionButton.topAnchor, constant: -16),

            actionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            actionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bottomConstraint!,
            actionButton.heightAnchor.constraint(equalToConstant: 44),

            hideKeyboardButton.trailingAnchor.constraint(equalTo: configTextView.trailingAnchor, constant: -8),
            hideKeyboardButton.bottomAnchor.constraint(equalTo: configTextView.bottomAnchor, constant: -8),
            hideKeyboardButton.widthAnchor.constraint(equalToConstant: 40),
            hideKeyboardButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    private func setupVPNStatusObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(vpnStatusChanged), name: .init("kApplicationVPNStatusDidChangeNotification"), object: nil)
    }

    @objc private func vpnStatusChanged() {
        updateButtonStatus()
    }

    private func updateButtonStatus() {
        let status = WSParserManager.shared().status
        switch status {
        case YDVPNStatusConnected:
            actionButton.setTitle("Disconnect", for: .normal)
            actionButton.backgroundColor = .systemRed
            actionButton.isEnabled = true
        case YDVPNStatusConnecting:
            actionButton.setTitle("Connecting...", for: .normal)
            actionButton.backgroundColor = .systemGray
            actionButton.isEnabled = false
        case YDVPNStatusDisconnecting:
            actionButton.setTitle("Disconnecting...", for: .normal)
            actionButton.backgroundColor = .systemGray
            actionButton.isEnabled = false
        default:
            actionButton.setTitle("Connect", for: .normal)
            actionButton.backgroundColor = .systemBlue
            actionButton.isEnabled = true
        }
    }

    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardHeight = keyboardFrame.cgRectValue.height
        let bottomInset = keyboardHeight - view.safeAreaInsets.bottom
        
        bottomConstraint?.constant = -bottomInset - 8
        hideKeyboardButton.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        bottomConstraint?.constant = -16
        hideKeyboardButton.isHidden = true
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func hideKeyboardTapped() {
        view.endEditing(true)
    }

    @objc private func actionButtonTapped() {
        let status = WSParserManager.shared().status
        if status == YDVPNStatusDisconnected {
            WSParserManager.shared().connect(configTextView.text)
        } else {
            WSParserManager.shared().disconnect()
        }
    }

    // MARK: - YAML Highlighting
    func textViewDidChange(_ textView: UITextView) {
        highlightYAML()
    }

    private func highlightYAML() {
        let text = configTextView.text ?? ""
        let attributedString = NSMutableAttributedString(string: text)
        let nSRange = NSRange(text.startIndex..., in: text)

        attributedString.addAttribute(.foregroundColor, value: UIColor.label, range: nSRange)
        attributedString.addAttribute(.font, value: UIFont.monospacedSystemFont(ofSize: 14, weight: .regular), range: nSRange)

        // Keys (e.g., proxies:)
        applyRegex(pattern: "^\\s*([\\w-]+):", color: .systemPurple, to: attributedString, text: text)
        
        // Strings in quotes
        applyRegex(pattern: "\"[^\"]*\"|'[^']*'", color: .systemGreen, to: attributedString, text: text)
        
        // Comments
        applyRegex(pattern: "#.*", color: .systemGray, to: attributedString, text: text)
        
        // Values (after colon)
        applyRegex(pattern: ":\\s+([^#\\n]+)", color: .systemBlue, to: attributedString, text: text, captureGroup: 1)

        let selectedRange = configTextView.selectedRange
        configTextView.attributedText = attributedString
        configTextView.selectedRange = selectedRange
    }

    private func applyRegex(pattern: String, color: UIColor, to attributedString: NSMutableAttributedString, text: String, captureGroup: Int = 0) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return }
        let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
        for match in matches {
            let range = match.range(at: captureGroup)
            attributedString.addAttribute(.foregroundColor, value: color, range: range)
        }
    }
}

