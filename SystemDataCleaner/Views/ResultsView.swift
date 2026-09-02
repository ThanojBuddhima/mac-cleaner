import SwiftUI

struct ResultsView: View {
    @ObservedObject var viewModel: ResultsViewModel
    @ObservedObject var cleanupViewModel: CleanupViewModel
    @State private var showCleanupConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar area
            HStack {
                Text("System Data")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text(formatBytes(viewModel.allItems.reduce(0) { $0 + $1.effectiveSize }))
                    .font(.title2)
            }
            .padding()
            
            Divider()
            
            // Filters and Search
            HStack {
                Picker("Sort", selection: $viewModel.sortOption) {
                    Text("Size").tag(SortOption.size)
                    Text("Name").tag(SortOption.name)
                    Text("Date").tag(SortOption.lastModified)
                    Text("Category").tag(SortOption.category)
                }
                .frame(width: 150)
                
                Picker("Filter", selection: $viewModel.filterOption) {
                    Text("All").tag(FilterOption.all)
                    Text("Safe").tag(FilterOption.safe)
                    Text("Review").tag(FilterOption.review)
                }
                .frame(width: 150)
                
                Spacer()
                
                TextField("Search...", text: $viewModel.searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 200)
            }
            .padding()
            
            // List
            List(viewModel.filteredItems) { item in
                HStack {
                    Toggle("", isOn: Binding(
                        get: { viewModel.selectedItemIDs.contains(item.id) },
                        set: { _ in viewModel.toggleSelection(for: item) }
                    ))
                    
                    Image(systemName: item.category.sfSymbol)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text(item.name)
                            .font(.headline)
                        Text(item.category.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(item.safetyLevel.rawValue)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(4)
                        .background(item.safetyLevel.color.opacity(0.2))
                        .foregroundColor(item.safetyLevel.color)
                        .cornerRadius(4)
                    
                    Text(formatBytes(item.effectiveSize))
                        .font(.body)
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.vertical, 4)
            }
            
            Divider()
            
            // Bottom Action Bar
            HStack {
                Button("Select All Safe") {
                    viewModel.selectAllSafe()
                }
                Button("Deselect All") {
                    viewModel.deselectAll()
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Selected:")
                        .font(.caption)
                    Text(formatBytes(viewModel.selectedTotalSize))
                        .font(.headline)
                }
                .padding(.trailing)
                
                Button("Review Cleanup") {
                    cleanupViewModel.createPlan(for: viewModel.selectedItems)
                    showCleanupConfirmation = true
                }
                .disabled(viewModel.selectedItemIDs.isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .sheet(isPresented: $showCleanupConfirmation) {
            CleanupConfirmationView(cleanupViewModel: cleanupViewModel, isPresented: $showCleanupConfirmation)
        }
    }
}
