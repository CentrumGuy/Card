//
//  WeakSet.swift
//  Sine Graph
//
//  Created by Shahar Ben-Dor on 12/3/20.
//  Copyright © 2020 Specter. All rights reserved.
//

import Foundation

internal class WeakSet<T>: Sequence, ExpressibleByArrayLiteral, CustomStringConvertible, CustomDebugStringConvertible {

    private var objects = NSHashTable<AnyObject>.weakObjects()

    public init(_ objects: [T]) {
        for object in objects {
            insert(object)
        }
    }

    public convenience required init(arrayLiteral elements: T...) {
        self.init(elements)
    }

    public var allObjects: [T] {
        return objects.allObjects as! [T]
    }
    
    public var isEmpty: Bool {
        for _ in self { return false }
        return true
    }

    public var count: Int {
        return objects.count
    }
    
    public var weakObjectCount: Int {
        return allObjects.count
    }

    public func contains(_ object: T) -> Bool {
        let anyObject = object as AnyObject
        return objects.contains(anyObject)
    }

    public func insert(_ object: T) {
        objects.add(object as AnyObject)
    }

    public func remove(_ object: T) {
        objects.remove(object as AnyObject)
    }

    public func makeIterator() -> AnyIterator<T> {
        let iterator = objects.objectEnumerator()
        return AnyIterator {
            return iterator.nextObject() as? T
        }
    }

    public var description: String {
        return objects.description
    }

    public var debugDescription: String {
        return objects.debugDescription
    }
}
