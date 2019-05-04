//
//  CustomView.swift
//  TestDrawingLetters
//
//  Copyright © 2016 Telegram. All rights reserved.
//  https://github.com/peter-iakovlev/TelegramUI/blob/023737c1c1e63cd9832d9e5ea05183ecf212796e/TelegramUI/AvatarNode.swift
//  Changes after 03/05/2019 are: Copyright © 2019 TeamUUUU. All rights reserved.
//

import UIKit

public let UIScreenScale = UIScreen.main.scale
public func floorToScreenPixels(_ value: CGFloat) -> CGFloat {
    return floor(value * UIScreenScale) / UIScreenScale
}

private let avatarFont: UIFont = UIFont(name: ".SFCompactRounded-Semibold", size: 26.0)!

public extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(red: CGFloat((rgb >> 16) & 0xff) / 255.0, green: CGFloat((rgb >> 8) & 0xff) / 255.0, blue: CGFloat(rgb & 0xff) / 255.0, alpha: 1.0)
    }
}

private let gradientColors: [NSArray] = [
    [UIColor(rgb: 0xff516a).cgColor, UIColor(rgb: 0xff885e).cgColor],
    [UIColor(rgb: 0xffa85c).cgColor, UIColor(rgb: 0xffcd6a).cgColor],
    [UIColor(rgb: 0x665fff).cgColor, UIColor(rgb: 0x82b1ff).cgColor],
    [UIColor(rgb: 0x54cb68).cgColor, UIColor(rgb: 0xa0de7e).cgColor],
    [UIColor(rgb: 0x4acccd).cgColor, UIColor(rgb: 0x00fcfd).cgColor],
    [UIColor(rgb: 0x2a9ef1).cgColor, UIColor(rgb: 0x72d5fd).cgColor],
    [UIColor(rgb: 0xd669ed).cgColor, UIColor(rgb: 0xe0a2f3).cgColor],
]

class AvatarView: UIView
{
    var image: UIImage?
    {
        didSet
        {
            if image == oldValue { return }
            
            DispatchQueue.main.async
            {
                self.setNeedsDisplay()
            }
        }
    }
    
    var parameters: (id: Int, letters:[String]) = (0, [])
    {
        didSet
        {
            if parameters == oldValue || image != nil { return }
            
            DispatchQueue.main.async
            {
                self.setNeedsDisplay()
            }
        }
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect)
    {
        // Drawing code
        let context = UIGraphicsGetCurrentContext()!
        
        context.beginPath()
        context.addEllipse(in: CGRect(x: 0.0, y: 0.0, width: bounds.size.width, height:
            bounds.size.height))
        context.clip()
        
        if let image = image
        {
            let factor = bounds.size.width / 60.0
            context.translateBy(x: bounds.size.width / 2.0, y: bounds.size.height / 2.0)
            context.scaleBy(x: factor, y: -factor)
            context.translateBy(x: -bounds.size.width / 2.0, y: -bounds.size.height / 2.0)
            
            context.draw(image.cgImage!, in: self.bounds)
        }
        else
        {
            let colorIndex: Int = abs(parameters.id)
            
            let colorsArray: NSArray
            
            colorsArray = gradientColors[colorIndex % gradientColors.count]
            
            var locations: [CGFloat] = [1.0, 0.0]
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colorsArray, locations: &locations)!
            
            context.drawLinearGradient(gradient, start: CGPoint(), end: CGPoint(x: 0.0, y: bounds.size.height), options: CGGradientDrawingOptions())
            
            context.setBlendMode(.normal)
            
            let letters = parameters.letters
            
            let string = letters.count == 0 ? "" : (letters[0] + (letters.count == 1 ? "" : letters[1]))
            let attributedString = NSAttributedString(string: string, attributes: [NSAttributedString.Key.font: avatarFont, NSAttributedString.Key.foregroundColor: UIColor.white])
            
            let line = CTLineCreateWithAttributedString(attributedString)
            let lineBounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
            
            let lineOffset = CGPoint(x: string == "B" ? 1.0 : 0.0, y: 0.0)
            let lineOrigin = CGPoint(x: floorToScreenPixels(-lineBounds.origin.x + (bounds.size.width - lineBounds.size.width) / 2.0) + lineOffset.x, y: floorToScreenPixels(-lineBounds.origin.y + (bounds.size.height - lineBounds.size.height) / 2.0))
            
            context.translateBy(x: bounds.size.width / 2.0, y: bounds.size.height / 2.0)
            context.scaleBy(x: 1.0, y: -1.0)
            context.translateBy(x: -bounds.size.width / 2.0, y: -bounds.size.height / 2.0)
            
            context.translateBy(x: lineOrigin.x, y: lineOrigin.y)
            CTLineDraw(line, context)
            context.translateBy(x: -lineOrigin.x, y: -lineOrigin.y)
        }
    }
}
