import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import Testing
import UIKit
@testable import ShelfLife

struct BarcodeImageReaderTests {
    /// Renders a Code 128 barcode as PNG data, padded with white like a real photo.
    private func barcodeImage(_ message: String) throws -> Data {
        let filter = CIFilter.code128BarcodeGenerator()
        filter.message = Data(message.utf8)
        filter.quietSpace = 20
        let output = try #require(filter.outputImage)
            .transformed(by: CGAffineTransform(scaleX: 4, y: 4))
        let cgImage = try #require(CIContext().createCGImage(output, from: output.extent))
        return try #require(UIImage(cgImage: cgImage).pngData())
    }

    @Test func readsBarcodeFromImage() async throws {
        let data = try barcodeImage("7790001234567")
        let payload = try await BarcodeImageReader.firstBarcode(in: data)
        #expect(payload == "7790001234567")
    }

    @Test func returnsNilForImageWithoutBarcode() async throws {
        let blank = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 200)).pngData { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 200, height: 200))
        }
        let payload = try await BarcodeImageReader.firstBarcode(in: blank)
        #expect(payload == nil)
    }
}
