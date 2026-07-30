#!/usr/bin/env swift

import AppKit
import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

let arguments = CommandLine.arguments
guard arguments.count == 4 else {
    FileHandle.standardError.write(
        Data("Usage: compose_play_feature_graphic.swift <source.png> <font.ttf> <output.png>\n".utf8)
    )
    exit(64)
}

let sourceURL = URL(fileURLWithPath: arguments[1])
let fontURL = URL(fileURLWithPath: arguments[2])
let outputURL = URL(fileURLWithPath: arguments[3])

guard
    let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
    let sourceImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil),
    let fontProvider = CGDataProvider(url: fontURL as CFURL),
    let graphicsFont = CGFont(fontProvider)
else {
    FileHandle.standardError.write(Data("Unable to load source image or font.\n".utf8))
    exit(1)
}

let width = 1024
let height = 500
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(
    data: nil,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    FileHandle.standardError.write(Data("Unable to create drawing context.\n".utf8))
    exit(1)
}

context.interpolationQuality = .high
let sourceWidth = CGFloat(sourceImage.width)
let sourceHeight = CGFloat(sourceImage.height)
let scale = max(CGFloat(width) / sourceWidth, CGFloat(height) / sourceHeight)
let drawWidth = sourceWidth * scale
let drawHeight = sourceHeight * scale
let imageRect = CGRect(
    x: (CGFloat(width) - drawWidth) / 2,
    y: (CGFloat(height) - drawHeight) / 2,
    width: drawWidth,
    height: drawHeight
)
context.draw(sourceImage, in: imageRect)

let panelRect = CGRect(x: 44, y: 96, width: 430, height: 308)
context.setFillColor(CGColor(red: 1.0, green: 0.985, blue: 0.91, alpha: 0.80))
context.addPath(CGPath(roundedRect: panelRect, cornerWidth: 36, cornerHeight: 36, transform: nil))
context.fillPath()
context.setStrokeColor(CGColor(red: 0.29, green: 0.57, blue: 0.39, alpha: 0.28))
context.setLineWidth(3)
context.addPath(CGPath(roundedRect: panelRect, cornerWidth: 36, cornerHeight: 36, transform: nil))
context.strokePath()

let titleFont = CTFontCreateWithGraphicsFont(graphicsFont, 72, nil, nil)
let titleColor = CGColor(red: 0.20, green: 0.40, blue: 0.27, alpha: 1.0)
let accentColor = CGColor(red: 0.86, green: 0.32, blue: 0.17, alpha: 1.0)

func drawLine(_ text: String, at point: CGPoint, color: CGColor) {
    let attributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(kCTFontAttributeName as String): titleFont,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): color,
        NSAttributedString.Key(kCTKernAttributeName as String): 2.0,
    ]
    let attributed = NSAttributedString(string: text, attributes: attributes)
    let line = CTLineCreateWithAttributedString(attributed)
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -3), blur: 7, color: CGColor(gray: 1.0, alpha: 0.82))
    context.textPosition = point
    CTLineDraw(line, context)
    context.restoreGState()
}

drawLine("萌宠小镇", at: CGPoint(x: 86, y: 285), color: titleColor)
drawLine("数学冒险", at: CGPoint(x: 86, y: 175), color: accentColor)

guard let finalImage = context.makeImage() else {
    FileHandle.standardError.write(Data("Unable to render final image.\n".utf8))
    exit(1)
}

guard let destination = CGImageDestinationCreateWithURL(
    outputURL as CFURL,
    UTType.png.identifier as CFString,
    1,
    nil
) else {
    FileHandle.standardError.write(Data("Unable to create PNG output.\n".utf8))
    exit(1)
}

CGImageDestinationAddImage(destination, finalImage, nil)
guard CGImageDestinationFinalize(destination) else {
    FileHandle.standardError.write(Data("Unable to save PNG output.\n".utf8))
    exit(1)
}

print("FEATURE_GRAPHIC: \(outputURL.path) (\(width)x\(height))")
