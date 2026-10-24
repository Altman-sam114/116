import AppKit
import Foundation
import Vision

guard CommandLine.arguments.count == 2,
      let imageData = try? Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])),
      let image = NSBitmapImageRep(data: imageData) else {
    fputs("Cannot decode screenshot\n", stderr)
    exit(1)
}

// Exclude status bars and HUD: detect a readable battlefield, not just a white clock.
var samples = 0
var luminance = 0.0
var brightSamples = 0
for y in stride(from: image.pixelsHigh / 5, to: image.pixelsHigh * 7 / 10, by: 12) {
    for x in stride(from: image.pixelsWide / 10, to: image.pixelsWide * 9 / 10, by: 12) {
        guard let color = image.colorAt(x: x, y: y)?.usingColorSpace(NSColorSpace.deviceRGB) else { continue }
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
if let cgImage = image.cgImage {
    do {
        try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([recognition])
        let text = (recognition.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ").lowercased()
        systemBanner = text.contains("apple intelligence") || text.contains("personal intelligence system")
    } catch {
        fputs("Cannot inspect system overlays: \(error)\n", stderr)
        exit(1)
    }
} else {
    fputs("Cannot load screenshot for system overlay inspection\n", stderr)
    exit(1)
}
let readable = mean >= 45 && visibleFraction >= 0.45 && !systemBanner
let result: [String: Any] = [
    "width": image.pixelsWide, "height": image.pixelsHigh,
    "orientation": image.pixelsHigh >= image.pixelsWide ? "portrait" : "landscape",
    "meanLuminance": mean, "visibleFraction": visibleFraction,
    "systemBannerDetected": systemBanner,
    "readable": readable
]
let jsonData = try JSONSerialization.data(withJSONObject: result, options: [.sortedKeys])
print(String(decoding: jsonData, as: UTF8.self))
exit(readable ? 0 : 1)
