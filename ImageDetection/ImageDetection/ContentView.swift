//
//  ContentView.swift
//  ImageDetection
//
//  Created by Utkarsh Raj on 01/11/24.
//

import SwiftUI
import CoreML
extension UIImage {
    func resize(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
    func buffer() -> CVPixelBuffer? {
      let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
      var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(self.size.width), Int(self.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
      guard (status == kCVReturnSuccess) else {
        return nil
      }

      CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
      let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

      let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(self.size.width), height: Int(self.size.height), bitsPerComponent: self.cgImage?.bitsPerComponent ?? 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

      context?.translateBy(x: 0, y: self.size.height)
      context?.scaleBy(x: 1.0, y: -1.0)

      UIGraphicsPushContext(context!)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
      UIGraphicsPopContext()
      CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

      return pixelBuffer
    }
}
struct ContentView: View {
    let images = ["1","2","3","4","5"]
    let model = try! MobileNetV2(configuration: MLModelConfiguration())
    @State private var predictions: [String] = []
    @State private var currentImage = 0
    var body: some View {
        VStack {
            Image(images[currentImage])
                .resizable()
                .scaledToFit() // Scale it to fit its container
                .frame(width: 300, height: 300) // Set the desired frame size
                .clipped()
            Spacer()
            
            HStack {
                Button {
                    currentImage = (currentImage + 1) % images.count
                    predictions = []
                    
                } label: {
                    Text("Change Image")
                    
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: {
                    guard let uiImage = UIImage(named: images[currentImage]) else { return }
                    let resizedImage = uiImage.resize(to: CGSize(width: 224, height: 224))
                    guard let buffer = resizedImage.buffer() else { return }
                    do {
                        let prediction = try model.prediction(image: buffer)
                        print(prediction.classLabel)
                        predictions = prediction.classLabel.components(separatedBy: ",")
                    } catch let error {
                        print(error.localizedDescription)
                    }
                }, label: {
                    Text("Predict")
                })
                .buttonStyle(.borderedProminent)
            }
            
            List {
                ForEach(predictions, id: \.self) { item in
                    Text("\(item)")
                }
            }

        }
        .padding()
    }
}

#Preview {
    ContentView()
}
