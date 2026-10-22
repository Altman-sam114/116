import AppKit
import Foundation

guard CommandLine.arguments.count == 2,
      let image = NSBitmapImageRep(contentsOfFile: CommandLine.arguments[1]) else {
    fputs("Cannot decode screenshot\n", stderr)
    exit(1)
}

// Exclude status bars and HUD: detect a readable battlefield, not just a white clock.
var samples = 0
var luminance = 0.0
var brightSamples = 0
for y in stride(from: image.pixelsHigh / 5, to: image.pixelsHigh * 7 / 10, by: 12) {
    for x in stride(from: image.pixelsWide / 10, to: image.pixelsWide * 9 / 10, by: 12) {
        guard let color = image.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else { continue }
        let value = Double(color.redComponent * 0.2126 + color.greenComponent * 0.7152 + color.blueComponent * 0.0722) * 255
        samples += 1
        luminance += value
        if value >= 55 { brightSamples += 1 }
    }
}
let mean = luminance / Double(max(samples, 1))
let visibleFraction = Double(brightSamples) / Double(max(samples, 1))
let result: [String: Any] = [
    "width": image.pixelsWide, "height": image.pixelsHigh,
    "orientation": image.pixelsHigh >= image.pixelsWide ? "portrait" : "landscape",
    "meanLuminance": mean, "visibleFraction": visibleFraction,
    "readable": mean >= 45 && visibleFraction >= 0.45
]
let data = try JSONSerialization.data(withJSONObject: result, options: [.sortedKeys])
print(String(decoding: data, as: UTF8.self))
exit(mean >= 45 && visibleFraction >= 0.45 ? 0 : 1)
