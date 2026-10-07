import PhotosUI
import SwiftData
import SwiftUI

/// Creates a new product when `product` is nil, otherwise edits it.
struct ProductFormView: View {
    let product: Product?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var location: String
    @State private var quantity: Int
    @State private var expirationDate: Date
    @State private var barcode: String
    @State private var notes: String

    @State private var isShowingCameraScanner = false
    @State private var isShowingPhotoPicker = false
    @State private var pickedPhoto: PhotosPickerItem?
    @State private var scanMessage: String?

    init(product: Product?) {
        self.product = product
        _name = State(initialValue: product?.name ?? "")
        _location = State(initialValue: product?.location ?? "")
        _quantity = State(initialValue: product?.quantity ?? 1)
        _expirationDate = State(
            initialValue: product?.expirationDate
                ?? Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now
        )
        _barcode = State(initialValue: product?.barcode ?? "")
        _notes = State(initialValue: product?.notes ?? "")
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("Barcode", text: $barcode)
                            .keyboardType(.numberPad)
                        scanMenu
                    }
                    TextField("Name", text: $name)
                    TextField("Location (e.g. Shelf 3)", text: $location)
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...9_999)
                } header: {
                    Text("Product")
                } footer: {
                    if let scanMessage {
                        Text(scanMessage)
                    }
                }

                Section("Expiration") {
                    DatePicker("Expires on", selection: $expirationDate, displayedComponents: .date)
                }

                Section("Details") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(product == nil ? "New Product" : "Edit Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(trimmedName.isEmpty)
                }
            }
            .sheet(isPresented: $isShowingCameraScanner) {
                LiveBarcodeScanner { code in
                    isShowingCameraScanner = false
                    apply(scannedCode: code)
                }
                .ignoresSafeArea()
            }
            .photosPicker(isPresented: $isShowingPhotoPicker, selection: $pickedPhoto, matching: .images)
            .onChange(of: pickedPhoto) { _, item in
                guard let item else { return }
                Task { await readBarcode(from: item) }
            }
        }
    }

    private var scanMenu: some View {
        Menu {
            Button("Scan with Camera", systemImage: "camera") {
                isShowingCameraScanner = true
            }
            .disabled(!LiveBarcodeScanner.isAvailable)
            Button("Choose Photo", systemImage: "photo") {
                isShowingPhotoPicker = true
            }
        } label: {
            Image(systemName: "barcode.viewfinder")
                .font(.title3)
        }
        .accessibilityLabel("Scan Barcode")
    }

    private func readBarcode(from item: PhotosPickerItem) async {
        defer { pickedPhoto = nil }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let code = try await BarcodeImageReader.firstBarcode(in: data)
            else {
                scanMessage = "No barcode found in that photo."
                return
            }
            apply(scannedCode: code)
        } catch {
            scanMessage = "Couldn't read the photo: \(error.localizedDescription)"
        }
    }

    /// Fills the barcode and, for a product scanned before, reuses its name and location.
    private func apply(scannedCode code: String) {
        barcode = code
        scanMessage = "Scanned \(code)."
        guard trimmedName.isEmpty else { return }

        var descriptor = FetchDescriptor<Product>(
            predicate: #Predicate { $0.barcode == code },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        if let previous = try? modelContext.fetch(descriptor).first {
            name = previous.name
            location = previous.location
            scanMessage = "Scanned \(code). Filled in from an earlier \(previous.name) entry."
        }
    }

    private func save() {
        let barcodeValue = barcode.isEmpty ? nil : barcode
        if let product {
            product.name = trimmedName
            product.location = location
            product.quantity = quantity
            product.expirationDate = expirationDate
            product.barcode = barcodeValue
            product.notes = notes
        } else {
            modelContext.insert(
                Product(
                    name: trimmedName,
                    location: location,
                    quantity: quantity,
                    expirationDate: expirationDate,
                    barcode: barcodeValue,
                    notes: notes
                )
            )
        }
        ProductSync.refresh(using: modelContext)
        dismiss()
    }
}

#Preview("New") {
    ProductFormView(product: nil)
        .modelContainer(.preview)
}
