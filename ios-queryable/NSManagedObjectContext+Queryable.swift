//
//  NSManagedObjectContext+Queryable.swift
//  ios-queryable
//
//  Created by Afonso Graça on 09/03/15.
//  Copyright (c) 2015 Afonso Graça. All rights reserved.
//

import Foundation
import CoreData


class Queryable : NSFastEnumeration {
	
	// MARK: - Private Properties
	
	private let context : NSManagedObjectContext
	private let type : String
	private let skipCount : Int
	private let fetchCount : Int
	
	private var sorts : [AnyObject]?
	private var whereClauses : [AnyObject]?
	
	// MARK: - Initialisers
	
	init(type entityType : String, context theContext: NSManagedObjectContext){
		self.type = entityType
		self.context = theContext
		self.fetchCount = Int.max
		self.skipCount = 0
	}
	
	init(type entityType : String, context theContext : NSManagedObjectContext, fetch newFetch: Int, skip newSkip : Int, sorts newSorts : [AnyObject]?, whereClauses newWhereClauses : [AnyObject]?){
		self.type = entityType
		self.context = theContext
		self.fetchCount = newFetch
		self.skipCount = newSkip
		self.sorts = newSorts
		self.whereClauses = newWhereClauses
	}
	
	// MARK: - Public Methods
	
	func toArray() -> [AnyObject]? {
		if self.fetchCount <= 0 {
			return [AnyObject]()
		}
		
		var error : NSError?
		let results = self.context.executeFetchRequest(self.getFetchRequest(), error: &error)
		if let err = error {
			NSLog("[\(self) \(__FUNCTION__)] \(err.localizedDescription) (\(err.localizedFailureReason))")
		}
		return results
	}
	
	func add(object : AnyObject, array : [AnyObject]?) -> [AnyObject]? {
		if let array = array {
			return array + [object]
		}
		else {
			return [object]
		}
	}
	
	func orderBy(fieldName : String, ascending : Bool) -> Queryable {
		let descriptor = NSSortDescriptor(key: fieldName, ascending: ascending)
		let newSorts = self.add(descriptor, array: self.sorts)
		
		return Queryable(type: self.type, context: self.context, fetch: self.fetchCount, skip: self.skipCount, sorts: newSorts, whereClauses: self.whereClauses)
		
	}
	
	func skip(numberToSKip : Int) -> Queryable {
		return Queryable(type: self.type, context: self.context, fetch: self.fetchCount, skip: numberToSKip, sorts: self.sorts, whereClauses: self.whereClauses)
	}
	
	func fetch(numberToFetch : Int) -> Queryable {
		return Queryable(type: self.type, context: self.context, fetch: numberToFetch, skip: self.skipCount, sorts: self.sorts, whereClauses: self.whereClauses)
	}
	
	func whereConditions( conditions : [String]) -> Queryable {
		if conditions.count > 0 {
			let predicate = NSPredicate(format: conditions[0], conditions)
			if let pred = predicate {
				let newWhere = self.add(pred, array: self.whereClauses)
				
				return Queryable(type: self.type, context: self.context, fetch: self.fetchCount, skip: self.skipCount, sorts: self.sorts, whereClauses: newWhere)
			}
		}
		return Queryable(type: self.type, context: self.context, fetch: self.fetchCount, skip: self.skipCount, sorts: self.sorts, whereClauses: self.whereClauses)
	}
	
	func countRequest() -> Int {
		var error : NSError?
		let theCount = self.context.countForFetchRequest(self.getFetchRequest(), error: &error)
		if let err = error {
			NSLog("[\(self) \(__FUNCTION__)] \(err.localizedDescription) (\(err.localizedFailureReason))")
		}
		return theCount
	}
	
	func countRequest(conditions : [String]) -> Int {
		let query = self.whereConditions(conditions)
		return query.countRequest()
	}
	
	func anyRequest() -> Bool {
		return self.countRequest() > 0 ? true : false
	}
	
	func anyRequest(conditions : String...) -> Bool {
		return self.countRequest(conditions) > 0 ? true : false
	}
	
	func allRequest(conditions : String...) -> Bool {
		return self.countRequest() == self.countRequest(conditions) ? true : false
	}
	
	func first() -> AnyObject? {
		if let result: AnyObject = self.firstOrDefault() {
			return result
		}
		else {
			var list : CVaListPointer?
			NSException.raise("The source sequence is empty", format: "", arguments: list!)
			return nil
		}
	}
	
	func firstRequest(conditions : String...) -> AnyObject? {
		let query = self.whereConditions(conditions)
		return query.first()
	}
	
	func firstOrDefault() -> AnyObject? {
		let query = Queryable(type: self.type, context: self.context, fetch: 1, skip: self.skipCount, sorts: self.sorts, whereClauses: self.whereClauses)
		if let results = query.toArray() {
			return results[0]
		}
		else {
			return nil
		}
	}
	
	func firstOrDefaultRequest(conditions : String...) -> AnyObject? {
		let query = self.whereConditions(conditions)
		return query.firstOrDefault()
	}
	
	func single() -> AnyObject? {
		if let result: AnyObject = self.singleOrDefault() {
			return result
		}
		else {
			var list : CVaListPointer?
			NSException.raise("The source sequence is empty", format: "", arguments: list!)
			return nil
		}
	}
	
	func singleRequest(conditions : String...) -> AnyObject? {
		let query = self.whereConditions(conditions)
		return query.single()
	}
	
	func singleOrDefault() -> AnyObject? {
		var howManyShouldIFetch = min(self.fetchCount < 0 ? 0 : self.fetchCount, 2)
		
		let query = Queryable(type: self.type, context: self.context, fetch: howManyShouldIFetch, skip: self.skipCount, sorts: self.sorts, whereClauses: self.whereClauses)
		if let results = query.toArray() {
			switch results.count {
			case 0 :
				return nil
			case 1:
				return results[0]
			default:
				var list : CVaListPointer?
				NSException.raise("The source sequence is empty", format: "", arguments: list!)
				return nil
			}
		}
		else {
			return nil
		}
	}
	
	func singleOrDefaultRequest(conditions : String...) -> AnyObject? {
		let query = self.whereConditions(conditions)
		return query.singleOrDefault()
	}
	
	/**
	* Fetches the value of a function applied to an entity's attribute
	* property - the attribute to perform the expression on
	* function - the function to be performed (i.e. average: sum: min: max:)
	*/
	func getExpressionValue(property : String, function : String) -> Double {
		let keyPathExpression = NSExpression(forKeyPath: property)
		let exp = NSExpression(forFunction: function, arguments: [keyPathExpression])
		
		let expressionDescription = NSExpressionDescription()
		expressionDescription.name = "expressionValue"
		expressionDescription.expression = exp
		expressionDescription.expressionResultType = .DoubleAttributeType
		
		let request = self.getFetchRequest()
		request.resultType = .DictionaryResultType
		request.propertiesToFetch = [expressionDescription]
		
		var error : NSError?
		let fetchResultArray = self.context.executeFetchRequest(request, error: &error)
		if let err = error {
			println("\(err)")
		}
		else {
			if let fra = fetchResultArray {
				let fetchResultsDictionary: AnyObject = fra[0]
				return fetchResultsDictionary.objectForKey("expressionValue")! as Double
			}
		}
		return 0
	}
	
	// MARK: - NSFastEnumeration Protocol Conformance
	func countByEnumeratingWithState(state: UnsafeMutablePointer<NSFastEnumerationState>, objects buffer: AutoreleasingUnsafeMutablePointer<AnyObject?>, count len: Int) -> Int {
		let items : AnyObject? = self.toArray()
		if let nsarray = items as? NSArray {
			return nsarray.countByEnumeratingWithState(state, objects: buffer, count: len)
			
		}
		return 0
	}
	
	// MARK: - Private Methods
	
	func getFetchRequest() -> NSFetchRequest {
		let entityDescription = NSEntityDescription.entityForName(self.type, inManagedObjectContext: self.context)
		
		let fetchRequest = NSFetchRequest()
		fetchRequest.entity = entityDescription
		
		fetchRequest.sortDescriptors = self.sorts
		
		fetchRequest.fetchOffset = max(self.skipCount, 0)
		fetchRequest.fetchLimit = self.fetchCount
		
		if let whereClauses = self.whereClauses {
			fetchRequest.predicate = NSCompoundPredicate.andPredicateWithSubpredicates(whereClauses)
		}
		
		return fetchRequest
	}
}

extension NSManagedObjectContext { //+Queryable
	func ofType(name : String) -> Queryable {
		return Queryable(type : name, context : self)
	}
}