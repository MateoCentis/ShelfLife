import SwiftData
import SwiftUI

struct ProductListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Product.expirationDate) private var products: [Product]

    @State private var searchText = ""
    @State private var isAddingProduct = false
    @State private var productToEdit: Product?
    @State private var isShowingSettings = false

    private var filteredProducts: [Product] {
        guard !searchText.isEmpty else { return products }
        return products.filter {
            $0.name.localizedStandardContains(searchText)
                || $0.location.localizedStandardContains(searchText)
        }
    }

    private var sections: [(status: ExpirationStatus, products: [Product])] {
        let grouped = Dictionary(grouping: filteredProducts) { $0.status() }
        return ExpirationStatus.allCases.compactMap { status in
            guard let items = grouped[status] else { return nil }
            return (status, items)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(sections, id: \.status) { section in
                    Section {
                        ForEach(section.products) { product in
                            Button {
                                productToEdit = product
                            } label: {
                                ProductRow(product: product)
                            }
                            .foregroundStyle(.primary)
                        }
                        .onDelete { offsets in
                            delete(section.products, at: offsets)
                        }
                    } header: {
                        Label(section.status.title, systemImage: section.status.symbolName)
                            .foregroundStyle(section.status.color)
                    }
                }
            }
            .overlay {
                if products.isEmpty {
                    ContentUnavailableView(
                        "No Products Yet",
                        systemImage: "shippingbox",
                        description: Text("Tap + to start tracking expiration dates.")
                    )
                } else if filteredProducts.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .navigationTitle("ShelfLife")
            .searchable(text: $searchText, prompt: "Search products or locations")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Settings", systemImage: "gearshape") {
                        isShowingSettings = true
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Product", systemImage: "plus") {
                        isAddingProduct = true
                    }
                }
            }
            .sheet(isPresented: $isAddingProduct) {
                ProductFormView(product: nil)
            }
            .sheet(item: $productToEdit) { product in
                ProductFormView(product: product)
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
        }
    }

    private func delete(_ items: [Product], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(items[index])
        }
        ProductSync.refresh(using: modelContext)
    }
}

#Preview {
    ProductListView()
        .modelContainer(.preview)
}

#Preview("Empty") {
    ProductListView()
        .modelContainer(for: Product.self, inMemory: true)
}
