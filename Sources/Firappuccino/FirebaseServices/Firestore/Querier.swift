import FirebaseFirestore
import FirebaseFirestoreSwift

extension Firappuccino {
	
	/**
	 A service for querying Firestore data.
	 */
	public struct Querier {
		
		public typealias QueryConditionBlock<T, U> = (ReferenceWritableKeyPath<T, U>, QueryCondition<T, U>.Comparison, U)
		
		/**
		 FQuery a collection of documents, matching the given condition.
		 
		 Use the `path` argument to specify the collection to query. For instance, if you have a collection of `FUser` objects, and you want to search for users matching the `displayName` of `"Atreyu"`, you can query like so:
		 
		 ```swift
		 Firappuccino.Querier.`queryWhere`(\MyUser.displayName, .equals, "Atreyu") { users in
		 // ...
		 }
		 ```
		 
		 - parameter path: The path to the field to check.
		 - parameter comparison: The comparison to use.
		 - parameter value: The value to compare with.
		 - parameter order: The way the documents are ordered. This will always order by the field provided in the `path` parameter.
		 - parameter limit: The maximum amount of documents to query.
		 */
		public static func wherePath<T, U>(_ path: ReferenceWritableKeyPath<T, U>, _ comparison: QueryCondition<T, U>.Comparison, _ value: U, order: OrderBy? = nil, limit: Int? = nil) async throws -> [T] where T: FDocument {
			await whereCondition(QueryCondition(path: path, comparison: comparison, value: value), order: order, limit: limit)
		}
		
		/**
		 FQuery a collection of documents, matching the given conditions.
		 
		 Each condition you wish to check is organized in `QueryConditionBlock`s. A `QueryConditionBlock` is equivalent to the tuple `(path, comparison, value)` of types `(KeyPath<_,_>, Comparison, Any)`. You can use this method to query with multiple conditions chained by the logical `AND` operator.
		 
		 
		 ```swift
		 let users = try await Firappuccino.Querier.`queryWhere`(
		 (\MyFirappuccinoUser.displayName, .equals, "Atreyu"),
		 (\MyFirappuccinoUser.createdAt, .lessThan, Date())
		 )
		 ```
		 
		 - note: If you are passing `order: .ascending` or `order: .descending` as an argument, ensure that your *first* `QueryConditionBlock` constrains the field you want to have ordered.
		 
		 ```swift
		 let users = try await Firappuccino.Querier.`queryWhere`(
		 (\MyFirappuccinoUser.displayName, .equals, "Atreyu"),
		 (\MyFirappuccinoUser.createdAt, .lessThan, Date()),
		 order: .ascending, limit: 8
		 )
		 ```
		 - parameter path: The path to the field to check.
		 - parameter comparison: The comparison to use.
		 - parameter value: The value to compare with.
		 - parameter order: The way the documents are ordered. See **Discussion** for more information.
		 - parameter limit: The maximum amount of documents to query.
		 */
		public static func `whereConditions`<T, U>(_ conditions: QueryConditionBlock<T, U> ..., order: OrderBy? = nil, limit: Int? = nil) async throws -> [T] where T: FDocument {
			var conditionsArr: [QueryCondition<T, U>] = []
			for condition in conditions {
				conditionsArr.append(QueryCondition(path: condition.0, comparison: condition.1, value: condition.2))
			}
			return await `whereConditions`(conditionsArr, order: order, limit: limit)
		}

		private static func whereCondition<T, U>(_ condition: QueryCondition<T, U>, order: OrderBy?, limit: Int?) async -> [T] where T: FDocument {
			await `whereConditions`([condition], order: order, limit: limit)
		}

		private static func `whereConditions`<T, U>(_ conditions: [QueryCondition<T, U>], order: OrderBy?, limit: Int?) async -> [T] where T: FDocument {
			let collectionName = String(describing: T.self)
			let collection = db.collection(collectionName)
			guard conditions.count > 0 else { return [] }
			var query: Query = conditions.first!.`apply`(to: collection)
			for condition in conditions.dropFirst() {
				query = condition.`apply`(to: query)
			}
			if let order = order {
				if order == .ascending {
					query = query.order(by: conditions.first!.path.fieldName)
				} else if order == .descending {
					query = query.order(by: conditions.first!.path.fieldName, descending: true)
				}
			}
			if let limit = limit {
				query = query.limit(to: limit)
			}
			do {
				let snapshot = try await query.getDocuments()
				var arr: [T] = []
				for document in snapshot.documents {
					let object = try? document.data(as: T.self)
					if let object = object {
						arr.append(object)
					}
				}
				return arr
			} catch let error {
				Firappuccino.logger.error("\(error.localizedDescription)")
				return []
			}
		}
		
		public enum OrderBy {
			case ascending, descending
		}
		
		public struct QueryCondition<T, U> {
			
			/// The path of the field to query.
			public var path: ReferenceWritableKeyPath<T, U>
			/// The comparison used to filter a query.
			public var comparison: Comparison
			/// The value to check.
			public var value: U
			
			
			internal func apply(to reference: CollectionReference) -> Query {
				switch comparison {
					case .equals: return reference.whereField(path.fieldName, isEqualTo: value)
					case .lessThan: return reference.whereField(path.fieldName, isLessThan: value)
					case .lessEqualTo: return reference.whereField(path.fieldName, isLessThanOrEqualTo: value)
					case .greaterThan: return reference.whereField(path.fieldName, isGreaterThan: value)
					case .greaterEqualTo: return reference.whereField(path.fieldName, isGreaterThanOrEqualTo: value)
					case .notEquals: return reference.whereField(path.fieldName, isNotEqualTo: value)
					case .contains: return reference.whereField(path.fieldName, arrayContains: value)
					case .in:
						guard let array = value as? [Any] else {
							fatalError("You must pass an array as a value when using the IN query comparison.")
						}
						return reference.whereField(path.fieldName, in: array)
					case .notIn:
						guard let array = value as? [Any] else {
							fatalError("You must pass an array as a value when using the NOT_IN query comparison.")
						}
						return reference.whereField(path.fieldName, notIn: array)
					case .containsAnyOf:
						guard let array = value as? [Any] else {
							fatalError("You must pass an array as a value when using the CONTAINS_ANY_OF query comparison.")
						}
						return reference.whereField(path.fieldName, arrayContainsAny: array)
				}
			}
			
			internal func apply(to query: Query) -> Query {
				switch comparison {
					case .equals: return query.whereField(path.fieldName, isEqualTo: value)
					case .lessThan: return query.whereField(path.fieldName, isLessThan: value)
					case .lessEqualTo: return query.whereField(path.fieldName, isLessThanOrEqualTo: value)
					case .greaterThan: return query.whereField(path.fieldName, isGreaterThan: value)
					case .greaterEqualTo: return query.whereField(path.fieldName, isGreaterThanOrEqualTo: value)
					case .notEquals: return query.whereField(path.fieldName, isNotEqualTo: value)
					case .contains: return query.whereField(path.fieldName, arrayContains: value)
					case .in:
						guard let array = value as? [Any] else {
							fatalError("You must pass an array as a value when using the IN query comparison.")
						}
						return query.whereField(path.fieldName, in: array)
					case .notIn:
						guard let array = value as? [Any] else {
							fatalError("You must pass an array as a value when using the NOT_IN query comparison.")
						}
						return query.whereField(path.fieldName, notIn: array)
					case .containsAnyOf:
						guard let array = value as? [Any] else {
							fatalError("You must pass an array as a value when using the CONTAINS_ANY_OF query comparison.")
						}
						return query.whereField(path.fieldName, arrayContainsAny: array)
				}
			}
			
			public enum Comparison {
				case equals, lessThan, greaterThan, lessEqualTo, greaterEqualTo, notEquals, contains, containsAnyOf, `in`, notIn
			}
		}
	}
}
