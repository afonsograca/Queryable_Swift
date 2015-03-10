#Queryable Swift
## NSManagedObjectContext+Queryable.swift is a Swift port based in martydill's [ios-queryable](https://github.com/martydill/ios-queryable) project

Basically it let's you get rid of Core Data immense boilerplate code.

The class supports query composition and deferred execution, and implements a subset of IEnumerable's methods, including where, take, skip, orderBy, first/firstOrDefault, single/singleOrDefault, count, any, and all.

Feel free to use, re-use and improve it!

#Example
Queryable lets you write code like this:
```swift
self.managedObjectContext.ofType("Category").whereConditions(["name like '*n*'"]).orderBy("name", ascending: true).fetch(5).toArray()
```

instead of like this:
```swift
let entityDescription = NSEntityDescription.entityForName("Category", inManagedObjectContext: self.managedObjectContext)

let fetchRequest = NSFetchRequest()
fetchRequest.entity = entityDescription

fetchRequest.predicate = NSPredicate(format: "name like '*n*'")

var descriptor: NSSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
request.sortDescriptors = [descriptor]

fetchRequest.fetchLimit = 5

var error : NSError?
let fetchResult = self.managedObjectContext.executeFetchRequest(fetchRequest error:&error) as [AnyObject]?
```

Queryable also supports the NSFastEnumeration protocol.

#Usage
To use Queryable, simply copy NSManagedObjectContext+Queryable.swift into your project folder and start writing your queries

