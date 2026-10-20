import UIKit

// A UIKit dialog in a dedicated window, without a React Native root view.
final class NativeDialogViewController: UIViewController, UITextViewDelegate {
  var onAction: ((String, [String: String]) -> Void)?
  var onDismiss: ((String) -> Void)?

  private let options: NativeDialogOptions
  private let backdrop = UIControl()
  private let card = UIView()
  private let content = UIStackView()
  private let errorLabel = UILabel()
  private var centerConstraint: NSLayoutConstraint?
  private var inputs: [String: UIView] = [:]
  private var didFinish = false

  init(options: NativeDialogOptions) {
    self.options = options
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) unavailable") }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear

    backdrop.backgroundColor = UIColor.black.withAlphaComponent(0.48)
    backdrop.addTarget(self, action: #selector(backdropPressed), for: .touchUpInside)
    backdrop.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(backdrop)
    NSLayoutConstraint.activate([
      backdrop.topAnchor.constraint(equalTo: view.topAnchor),
      backdrop.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      backdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      backdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor)
    ])

    card.backgroundColor = .secondarySystemBackground
    card.layer.cornerRadius = 16
    card.layer.masksToBounds = true
    card.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(card)

    content.axis = .vertical
    content.spacing = 16
    content.alignment = .fill
    content.translatesAutoresizingMaskIntoConstraints = false
    card.addSubview(content)

    centerConstraint = card.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
    centerConstraint?.isActive = true
    NSLayoutConstraint.activate([
      card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      card.widthAnchor.constraint(lessThanOrEqualToConstant: 380),
      card.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
      card.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
      card.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      card.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
      content.topAnchor.constraint(equalTo: card.topAnchor, constant: 22),
      content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),
      content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
      content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20)
    ])

    buildContent()
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardChanged(_:)),
      name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardChanged(_:)),
      name: UIResponder.keyboardWillHideNotification, object: nil)
    UIAccessibility.post(notification: .screenChanged, argument: card)
  }

  deinit { NotificationCenter.default.removeObserver(self) }

  private func titleLabel(_ text: String, font: UIFont, color: UIColor = .label) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = font
    label.textColor = color
    label.textAlignment = .center
    label.numberOfLines = 0
    return label
  }

  private func buildContent() {
    let iconName: String?
    switch options.icon {
    case .none: iconName = nil
    case .info: iconName = "info.circle.fill"
    case .success: iconName = "checkmark.circle.fill"
    case .warning: iconName = "exclamationmark.triangle.fill"
    case .error: iconName = "xmark.octagon.fill"
    }
    if let iconName = iconName, let symbol = UIImage(systemName: iconName) {
      let icon = UIImageView(image: symbol)
      icon.contentMode = .scaleAspectFit
      icon.tintColor = (options.icon == .error || options.icon == .warning) ? .systemRed : .systemBlue
      icon.heightAnchor.constraint(equalToConstant: 42).isActive = true
      content.addArrangedSubview(icon)
    }

    let title = titleLabel(options.title, font: .boldSystemFont(ofSize: 21))
    title.accessibilityTraits.insert(.header)
    content.addArrangedSubview(title)

    if let message = options.message, !message.isEmpty {
      content.addArrangedSubview(titleLabel(message, font: .systemFont(ofSize: 15), color: .secondaryLabel))
    }

    for field in options.fields {
      if field.type == .textarea {
        let textarea = UITextView()
        textarea.text = field.value
        textarea.font = .systemFont(ofSize: 16)
        textarea.textColor = .label
        textarea.backgroundColor = .tertiarySystemBackground
        textarea.layer.cornerRadius = 9
        textarea.layer.borderColor = UIColor.separator.cgColor
        textarea.layer.borderWidth = 1
        textarea.accessibilityLabel = field.placeholder ?? field.id
        textarea.delegate = self
        textarea.tag = options.fields.firstIndex(where: { $0.id == field.id }) ?? 0
        textarea.heightAnchor.constraint(equalToConstant: 96).isActive = true
        content.addArrangedSubview(textarea)
        inputs[field.id] = textarea
      } else {
        let textField = UITextField()
        textField.text = field.value
        textField.placeholder = field.placeholder
        textField.font = .systemFont(ofSize: 16)
        textField.backgroundColor = .tertiarySystemBackground
        textField.layer.cornerRadius = 9
        textField.layer.borderColor = UIColor.separator.cgColor
        textField.layer.borderWidth = 1
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        textField.leftViewMode = .always
        textField.tag = options.fields.firstIndex(where: { $0.id == field.id }) ?? 0
        textField.addTarget(self, action: #selector(textChanged(_:)), for: .editingChanged)
        textField.heightAnchor.constraint(equalToConstant: 45).isActive = true
        content.addArrangedSubview(textField)
        inputs[field.id] = textField
      }
    }

    errorLabel.font = .systemFont(ofSize: 13)
    errorLabel.textColor = .systemRed
    errorLabel.numberOfLines = 0
    errorLabel.isHidden = true
    content.addArrangedSubview(errorLabel)

    let buttons = UIStackView()
    buttons.axis = options.actions.count <= 2 ? .horizontal : .vertical
    buttons.spacing = 10
    buttons.distribution = .fillEqually

    for action in options.actions {
      let button = UIButton(type: .system)
      button.setTitle(action.title, for: .normal)
      button.titleLabel?.font = .boldSystemFont(ofSize: 16)
      button.layer.cornerRadius = 9
      switch action.style {
      case .cancel:
        button.backgroundColor = .tertiarySystemBackground
        button.setTitleColor(.label, for: .normal)
      case .destructive:
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
      case .default:
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
      }
      button.tag = options.actions.firstIndex(where: { $0.id == action.id }) ?? 0
      button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
      button.heightAnchor.constraint(greaterThanOrEqualToConstant: 47).isActive = true
      buttons.addArrangedSubview(button)
    }
    content.addArrangedSubview(buttons)
  }

  @objc private func textChanged(_ sender: UITextField) {
    guard options.fields.indices.contains(sender.tag),
          let max = options.fields[sender.tag].maxLength, max > 0 else { return }
    if let text = sender.text, text.count > max { sender.text = String(text.prefix(max)) }
  }

  func textViewDidChange(_ textView: UITextView) {
    guard options.fields.indices.contains(textView.tag),
          let max = options.fields[textView.tag].maxLength, max > 0 else { return }
    if textView.text.count > max { textView.text = String(textView.text.prefix(max)) }
  }

  @objc private func buttonPressed(_ sender: UIButton) {
    guard !didFinish, options.actions.indices.contains(sender.tag) else { return }
    let action = options.actions[sender.tag]
    var values: [String: String] = [:]
    for field in options.fields {
      let value = (inputs[field.id] as? UITextField)?.text
        ?? (inputs[field.id] as? UITextView)?.text ?? ""
      if action.style != .cancel && field.required && value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        errorLabel.text = "Please complete all required fields."
        errorLabel.isHidden = false
        return
      }
      values[field.id] = value
    }
    didFinish = true
    view.endEditing(true)
    onAction?(action.id, values)
  }

  @objc private func backdropPressed() {
    guard !didFinish, options.dismissOnBackdrop else { return }
    didFinish = true
    onDismiss?("backdrop")
  }

  @objc private func keyboardChanged(_ notification: Notification) {
    guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
    let keyboardFrame = view.convert(frame, from: nil)
    let overlap = max(0, view.bounds.maxY - keyboardFrame.minY)
    let offset = -overlap * 0.42
    let adjusted = max(offset, -(view.bounds.height - card.bounds.height) / 2 + 12)
    UIView.animate(withDuration: 0.22) {
      self.centerConstraint?.constant = adjusted
      self.view.layoutIfNeeded()
    }
  }
}
