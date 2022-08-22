import SwiftUI
import Firappuccino


struct ContentView: View {
	
	@Published var selectedSortType = SortType.createdAt
	@Published var isDescending = true
	@Published var editedName = ""
	@Published var items: [InventoryItem] = []

	var body: some View {
		VStack {
			if let error = $items.error {
				Text(error.localizedDescription)
			}
			
			if items.count > 0 {
				List {
					sortBySectionView
					listItemsSectionView
				}
				.listStyle(.insetGrouped)
			}
		}
		.toolbar {
			ToolbarItem(placement: .navigationBarTrailing) {
				Button("+") { addItem() }.font(.title)
			}
			
			ToolbarItem(placement: .navigationBarLeading) { EditButton() }
		}
		.onChange(of: selectedSortType) { _ in onSortTypeChanged() }
		.onChange(of: isDescending) { _ in onSortTypeChanged() }
		.navigationTitle("Inventories")
	}
	
	private var listItemsSectionView: some View {
		Section {
			ForEach(items) { item in
				VStack {
					TextField("Name", text: Binding<String>(
						get: { item.name },
						set: { editedName = $0 }),
							  onEditingChanged: { onEditingItemNameChanged(item: item, isEditing: $0)}
					)
					.disableAutocorrection(true)
					.font(.headline)
					
					Stepper("Quantity: \(item.quantity)",
							value: Binding<Int>(
								get: { item.quantity },
								set: { item.set() }),
							in: 0...1000)
				}
			}
			.onDelete {
				
				onDelete(items: items, indexset: $0)
			}
		}
	}
	
	private var sortBySectionView: some View {
		Section {
			DisclosureGroup("Sort by") {
				Picker("Sort by", selection: $selectedSortType) {
					ForEach(SortType.allCases, id: \.rawValue) { sortType in
						Text(sortType.text).tag(sortType)
					}
				}.pickerStyle(.segmented)
				
				Toggle("Is Descending", isOn: $isDescending)
			}
		}
	}
	
	private func onSortTypeChanged() {
		$items.predicates = predicates
	}
	
	
//	func addItem() {
//		Task {
//			do {
//				let item = InventoryItem(name: "New Item", quantity: 1)
//				try await item.set()
//			}
//			catch let error {
//				Firappuccino.logger.error("\(error.localizedDescription)")
//			}
//		}
//	}
	
	func updateItem(_ item: InventoryItem) {
		guard let id = item.id else { return }
		item.dateUpdated = Date()
		item.set()
		db.document(id).updateData(_data)
	}
	
	func onDelete(items: [InventoryItem], indexset: IndexSet) {
		for index in indexset {
			Task { guard let item = items[index] else { continue }
			Firappuccino.Trash.remove(item)
			}
		}
	}
	
	func onEditingItemNameChanged(item: InventoryItem, isEditing: Bool) {
		if !isEditing {
			if item.name != editedName {
				item.set(field: "name", with: self.editedName, using: \.name)
				updateItem(item, data: ["name": editedName])
			}
			editedName = ""
		} else {
			editedName = item.name
		}
	}
}

//struct ContentView_Previews: PreviewProvider {
//	static var previews: some View {
//		ContentView()
//	}
//}

//enum SortType: String, CaseIterable {
//
//	case createdAt
//	case updatedAt
//	case name
//	case quantity
//
//	var text: String {
//		switch self {
//			case .createdAt: return "Created At"
//			case .updatedAt: return "Updated At"
//			case .name: return "Name"
//			case .quantity: return "Quantity"
//		}
//	}
//
//}


class InventoryItem: FirappuccinoDocument {
	
	var id: String
	var dateCreated: Date
	
	var dateUpdated: Date?
	var name: String = ""
	var quantity: Int = 0
	
	init(name: String, quantity: Int) {
		self.id = UUID().uuidStringSansDashes
		self.dateCreated = Date()
		self.dateUpdated = Date()
		self.name = name
		self.quantity = quantity
	}
}

