import Foundation
import SwiftUI

enum SortOption {
    case size
    case name
    case lastModified
    case category
}

enum FilterOption: Hashable {
    case all
    case safe
    case review
    case category(StorageCategory)
}

@MainActor
class ResultsViewModel: ObservableObject {
    @Published var allItems: [StorageItem] = []
    @Published var sortOption: SortOption = .size
    @Published var searchQuery: String = ""
    @Published var filterOption: FilterOption = .all
    
    @Published var selectedItemIDs: Set<UUID> = []
    
    var filteredItems: [StorageItem] {
        var items = allItems
        
        // Filter
        if filterOption != .all {
            switch filterOption {
            case .safe:
                items = items.filter { $0.safetyLevel == .safe }
            case .review:
                items = items.filter { $0.safetyLevel == .review }
            case .category(let cat):
                items = items.filter { $0.category == cat }
            case .all: break
            }
        }
        
        // Search
        if !searchQuery.isEmpty {
            let lowerQuery = searchQuery.lowercased()
            items = items.filter { item in
                item.name.lowercased().contains(lowerQuery) ||
                item.category.rawValue.lowercased().contains(lowerQuery) ||
                item.path.path.lowercased().contains(lowerQuery)
            }
        }
        
        // Sort
        items.sort { a, b in
            switch sortOption {
            case .size:
                return a.effectiveSize > b.effectiveSize
            case .name:
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            case .lastModified:
                let dateA = a.modifiedDate ?? Date.distantPast
                let dateB = b.modifiedDate ?? Date.distantPast
                return dateA > dateB
            case .category:
                return a.category.rawValue < b.category.rawValue
            }
        }
        
        return items
    }
    
    var selectedItems: [StorageItem] {
        var foundItems: [StorageItem] = []
        func search(_ items: [StorageItem]) {
            for item in items {
                if selectedItemIDs.contains(item.id) {
                    foundItems.append(item)
                }
                if let children = item.children {
                    search(children)
                }
            }
        }
        search(allItems)
        return foundItems
    }
    
    var selectedTotalSize: Int64 {
        return selectedItems.reduce(0) { $0 + $1.effectiveSize }
    }
    
    func selectAllSafe() {
        func selectSafe(in items: [StorageItem]) {
            for item in items {
                if item.safetyLevel == .safe {
                    selectedItemIDs.insert(item.id)
                }
                if let children = item.children {
                    selectSafe(in: children)
                }
            }
        }
        selectSafe(in: filteredItems)
    }
    
    func deselectAll() {
        selectedItemIDs.removeAll()
    }
    
    func toggleSelection(for item: StorageItem) {
        if selectedItemIDs.contains(item.id) {
            selectedItemIDs.remove(item.id)
        } else {
            selectedItemIDs.insert(item.id)
        }
    }
    
    func removeItem(with id: UUID) {
        allItems.removeItem(with: id)
        selectedItemIDs.remove(id)
    }
}

extension Array where Element == StorageItem {
    mutating func removeItem(with id: UUID) {
        if let index = self.firstIndex(where: { $0.id == id }) {
            self.remove(at: index)
            return
        }
        
        for i in 0..<self.count {
            if var children = self[i].children {
                let initialCount = children.count
                children.removeItem(with: id)
                if children.count < initialCount {
                    self[i].children = children.isEmpty ? nil : children
                    return
                }
            }
        }
    }
}
