//
//  ViewController.swift
//  CombineLogin
//
//  Created by roy on 2022/1/18.
//

import UIKit
import Combine

class ViewController: UIViewController {
    @IBOutlet private var firstTextField: UITextField!
    @IBOutlet private var lastTextField: UITextField!
    @IBOutlet private var hintIconView: UIImageView!
    @IBOutlet private var hintLabel: UILabel!
    @IBOutlet private var submitBtn: UIButton!
    
    private var subscribers: Set<AnyCancellable> = []
    
    var validateInput: AnyPublisher<String?, Never> {
        firstTextField
            .textPublisher
            .map { [self] firstInput in
                guard checkPassword(firstInput) else {
                    hintLabel.text = "Must contains uppercase letters, lowercase letters, numbers and symbols."
                    hintIconView.image =
                        UIImage(systemName: "xmark.circle.fill")?.withRenderingMode(.alwaysOriginal)
                    
                    return nil
                }
                
                hintLabel.text = ""
                hintIconView.image = nil
                
                return firstInput
            }
            .eraseToAnyPublisher()
    }
    
    var validateRepeat: AnyPublisher<String?, Never> {
        Publishers.CombineLatest(firstTextField.textPublisher, lastTextField.textPublisher)
            .receive(on: DispatchQueue.main)
            .map { [self] input, repeated in
                guard input == repeated else {
                    if !input.isEmpty, checkPassword(input) {
                        hintLabel.text = "Two passwords must be identical."
                        hintIconView.image =
                            UIImage(systemName: "xmark.circle.fill")?.withRenderingMode(.alwaysOriginal)
                    }
                    
                    return nil
                }
                
                hintLabel.text = ""
                hintIconView.image = nil
                
                return repeated
            }
            .eraseToAnyPublisher()
    }
    
    var isReady: AnyPublisher<(String, String)?, Never> {
        Publishers.CombineLatest(validateInput, validateRepeat)
            .map { input, repeated in
                guard let input = input, let repeated = repeated else {
                    return nil
                }
                
                return (input, repeated)
            }
            .eraseToAnyPublisher()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setup()
    }
}


extension ViewController {
    
    private func setup() {
        view.addGestureRecognizer(UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:))))
        
        // Disable On Launch
        submitBtn.isEnabled = false
        
        // Removing Spaces
        firstTextField
            .textPublisher
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .assign(to: \.text, on: firstTextField)
            .store(in: &subscribers)
        
        // Removing Spaces
        lastTextField
            .textPublisher
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .assign(to: \.text, on: lastTextField)
            .store(in: &subscribers)
        
        isReady
            .map { $0 != nil }
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: submitBtn)
            .store(in: &subscribers)
    }
    
    @IBAction private func submitDidTap(_ sender: UIButton) {
        showAlert(title: "Congrats!", message: "")
    }
    
    private func checkPassword(_ password: String) -> Bool {
        let containsUppercase = !password.filter({ $0.isUppercase }).isEmpty
        let containsLowercase = !password.filter({ $0.isLowercase }).isEmpty
        let containsNumber = !password.filter({ $0.isNumber }).isEmpty
        let containsPunctuation = !password.filter({ $0.isPunctuation }).isEmpty
        
        return containsUppercase && containsLowercase && containsNumber && containsPunctuation
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
}


extension UITextField {
    
    var textPublisher: AnyPublisher<String, Never> {
        NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: self)
            .map { ($0.object as? UITextField)?.text ?? "" }
            .eraseToAnyPublisher()
    }
}
