import AppKit
import Foundation
import ImageIO
import Vision

struct ScreenshotDisplayGeometry {
    let pixelWidth: Int
    let pixelHeight: Int
    let orientation: CGImagePropertyOrientation

    var swapsAxes: Bool {
        [CGImagePropertyOrientation.leftMirrored, .right, .rightMirrored, .left].contains(orientation)
    }
    var width: Int { swapsAxes ? pixelHeight : pixelWidth }
    var height: Int { swapsAxes ? pixelWidth : pixelHeight }

    // Sampling coordinates only; the original screenshot bytes are never rewritten.
    func rawPoint(x: Int, y: Int) -> (x: Int, y: Int) {
        switch orientation {
        case .up: (x, y)
        case .upMirrored: (pixelWidth - 1 - x, y)
        case .down: (pixelWidth - 1 - x, pixelHeight - 1 - y)
        case .downMirrored: (x, pixelHeight - 1 - y)
        case .leftMirrored: (y, x)
        case .right: (y, pixelHeight - 1 - x)
        case .rightMirrored: (pixelWidth - 1 - y, pixelHeight - 1 - x)
        case .left: (pixelWidth - 1 - y, x)
        @unknown default: (x, y)
        }
    }
}

struct ScreenshotImage {
    let pixels: CGImage
    let bitmap: NSBitmapImageRep
    let display: ScreenshotDisplayGeometry

    init?(data: Data) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let pixels = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] ?? [:]
        let value = (properties[kCGImagePropertyOrientation as String] as? NSNumber)?.uint32Value ?? 1
        guard let orientation = CGImagePropertyOrientation(rawValue: value) else { return nil }
        self.pixels = pixels
        // AppKit's data initializer normalizes EXIF; raw ImageIO pixels must only be oriented once.
        bitmap = NSBitmapImageRep(cgImage: pixels)
        display = ScreenshotDisplayGeometry(pixelWidth: pixels.width, pixelHeight: pixels.height,
                                            orientation: orientation)
    }
}

if CommandLine.arguments == [CommandLine.arguments[0], "--self-test"] {
    let colors: [UInt8] = [255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255,
                           255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 255]
    let provider = CGDataProvider(data: Data(colors) as CFData)!
    let fixture = CGImage(width: 3, height: 2, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 12,
                          space: CGColorSpace(name: CGColorSpace.sRGB)!,
                          bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                          provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
    let corners = [(0, 0, 2, 1), (2, 0, 0, 1), (2, 1, 0, 0), (0, 1, 2, 0),
                   (0, 0, 2, 1), (0, 1, 2, 0), (2, 1, 0, 0), (2, 0, 0, 1)]
    for value in UInt32(1)...8 {
        let encoded = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(encoded, "public.png" as CFString, 1, nil) else { exit(1) }
        CGImageDestinationAddImage(destination, fixture, [kCGImagePropertyOrientation: value] as CFDictionary)
        guard CGImageDestinationFinalize(destination), let decoded = ScreenshotImage(data: encoded as Data),
              decoded.pixels.width == 3, decoded.pixels.height == 2,
              decoded.bitmap.pixelsWide == 3, decoded.bitmap.pixelsHigh == 2,
              decoded.display.orientation.rawValue == value else {
            fputs("Screenshot PNG raw decode/orientation contract failed\n", stderr)
            exit(1)
        }
        let geometry = decoded.display
        let first = geometry.rawPoint(x: 0, y: 0)
        let last = geometry.rawPoint(x: geometry.width - 1, y: geometry.height - 1)
        let expected = corners[Int(value) - 1]
        guard first.x == expected.0, first.y == expected.1, last.x == expected.2, last.y == expected.3,
              geometry.width == (value >= 5 ? 2 : 3), geometry.height == (value >= 5 ? 3 : 2) else {
            fputs("Screenshot orientation corner/dimension contract failed\n", stderr)
            exit(1)
        }
        var samples = Set<String>()
        for y in 0..<geometry.height {
            for x in 0..<geometry.width {
                let point = geometry.rawPoint(x: x, y: y)
                guard (0..<3).contains(point.x), (0..<2).contains(point.y) else { exit(1) }
                guard let color = decoded.bitmap.colorAt(x: point.x, y: point.y)?.usingColorSpace(.sRGB) else { exit(1) }
                let index = (point.y * 3 + point.x) * 4
                let actual = [color.redComponent, color.greenComponent, color.blueComponent]
                guard actual.enumerated().allSatisfy({ abs($0.element * 255 - CGFloat(colors[index + $0.offset])) < 2 }) else {
                    fputs("Screenshot PNG sampling contract failed: EXIF=\(value), raw=(\(point.x),\(point.y)), expected=\(Array(colors[index..<(index + 3)])), sRGB=\(actual.map { $0 * 255 })\n", stderr)
                    exit(1)
                }
                samples.insert("\(point.x),\(point.y)")
            }
        }
        guard samples.count == 6 else { exit(1) }
    }
    print("Screenshot orientation contracts passed: 8 PNG decodes/transforms, original pixels unchanged")
    exit(0)
}

guard CommandLine.arguments.count == 2,
      let imageData = try? Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])),
      let screenshot = ScreenshotImage(data: imageData) else {
    fputs("Cannot decode screenshot\n", stderr)
    exit(1)
}

let image = screenshot.bitmap
let display = screenshot.display

// Exclude status bars and HUD: detect a readable battlefield, not just a white clock.
var samples = 0
var luminance = 0.0
var brightSamples = 0
for y in stride(from: display.height / 5, to: display.height * 7 / 10, by: 12) {
    for x in stride(from: display.width / 10, to: display.width * 9 / 10, by: 12) {
        let point = display.rawPoint(x: x, y: y)
        guard let color = image.colorAt(x: point.x, y: point.y)?.usingColorSpace(NSColorSpace.sRGB) else { continue }
        let red = Double(color.redComponent) * 0.2126
        let green = Double(color.greenComponent) * 0.7152
        let blue = Double(color.blueComponent) * 0.0722
        let value = (red + green + blue) * 255
        samples += 1
        luminance += value
        if value >= 55 { brightSamples += 1 }
    }
}
let mean = luminance / Double(max(samples, 1))
let visibleFraction = Double(brightSamples) / Double(max(samples, 1))
// Launch-time system banners can pass luminance checks while hiding the game's command bar.
let recognition = VNRecognizeTextRequest()
recognition.recognitionLevel = .accurate
recognition.regionOfInterest = CGRect(x: 0, y: 0.66, width: 1, height: 0.34)
var systemBanner = false
do {
    try VNImageRequestHandler(cgImage: screenshot.pixels, orientation: display.orientation, options: [:]).perform([recognition])
    let text = (recognition.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ").lowercased()
    systemBanner = text.contains("apple intelligence") || text.contains("personal intelligence system")
} catch {
    fputs("Cannot inspect system overlays: \(error)\n", stderr)
    exit(1)
}
let readable = mean >= 45 && visibleFraction >= 0.45 && !systemBanner
let result: [String: Any] = [
    "width": display.width, "height": display.height,
    "pixelWidth": image.pixelsWide, "pixelHeight": image.pixelsHigh,
    "exifOrientation": display.orientation.rawValue,
    "samplingColorSpace": "sRGB",
    "orientation": display.height >= display.width ? "portrait" : "landscape",
    "meanLuminance": mean, "visibleFraction": visibleFraction,
    "systemBannerDetected": systemBanner,
    "readable": readable
]
let jsonData = try JSONSerialization.data(withJSONObject: result, options: [.sortedKeys])
print(String(decoding: jsonData, as: UTF8.self))
exit(readable ? 0 : 1)
