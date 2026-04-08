//
//  DesignableTextField.swift
//  Steam_Air
//

internal import UIKit

@IBDesignable
class DesignableTextField: UITextField {
    
    @IBInspectable var cornerRadius: CGFloat = 0
    @IBInspectable var borderWidth: CGFloat = 0
    @IBInspectable var borderColor: UIColor = .clear
    @IBInspectable var leftPadding: CGFloat = 0
    @IBInspectable var fillColor: UIColor = .gray
    
    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyle()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        applyStyle()
    }
    
    private func applyStyle() {
        layer.cornerRadius = cornerRadius
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor.cgColor
        clipsToBounds = cornerRadius > 0
        backgroundColor = fillColor
        
        if leftView == nil {
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: leftPadding, height: 1))
            leftView = paddingView
            leftViewMode = .always
        } else {
            leftView?.frame = CGRect(x: 0, y: 0, width: leftPadding, height: 1)
        }
    }
}
