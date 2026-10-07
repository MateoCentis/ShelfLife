import Foundation
import Vision

/// Finds barcodes in a still image (e.g. a photo from the library) with the Vision framework.
nonisolated enum BarcodeImageReader {
    /// The payload of the first barcode found, or nil if the image has none.
    static func firstBarcode(in imageData: Data) async throws -> String? {
        #if targetEnvironment(simulator)
        try legacyFirstBarcode(in: imageData)
        #else
        var request = DetectBarcodesRequest()
        request.symbologies = [.ean13, .ean8, .upce, .code128, .code39, .qr, .dataMatrix]
        let observations = try await request.perform(on: imageData)
        return observations.lazy.compactMap(\.payloadString).first
        #endif
    }

    #if targetEnvironment(simulator)
    /// The current detector needs hardware the simulator lacks ("Failed to create
    /// barcode detector"), so the simulator falls back to the CPU-only first revision.
    private static func legacyFirstBarcode(in imageData: Data) throws -> String? {
        let request = VNDetectBarcodesRequest()
        request.revision = 1 // VNDetectBarcodesRequestRevision1 (constant is deprecated)
        try VNImageRequestHandler(data: imageData).perform([request])
        return request.results?.lazy.compactMap(\.payloadStringValue).first
    }
    #endif
}
