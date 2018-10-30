//
//  RealmDataStorage.swift
//  StorageKit
//
//  Copyright (c) 2017 StorageKit (https://github.com/StorageKit)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
import StorageKit
import RealmSwift

final public class RealmDataStorage: Storage {
    
    public enum StoreType {
        case sql
        case memory
    }
    
    public struct Configuration {
        var contentRepoType: ContextRepoType.Type = ContextRepo.self
        var realmContextType: RealmContextType.Type = RealmContext.self
        public init(){}
    }
    
    public var mainContext: StorageContext?
    private let backgroundQueue = DispatchQueue(label: "com.StorageKit.realmDataStorage")
    private let configuration: Configuration
    private let contextRepo: ContextRepoType
    
    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
        
        mainContext = configuration.realmContextType.init(realmType: Realm.self)
        
        contextRepo = configuration.contentRepoType.init(cleaningTimerInterval: nil)
        contextRepo.store(context: mainContext, queue: .main)
    }
    
    public func performBackgroundTask(_ taskClosure: @escaping TaskClosure) {
        backgroundQueue.async { [unowned self] in
            autoreleasepool {
                let context = self.configuration.realmContextType.init(realmType: Realm.self)
                
                self.contextRepo.store(context: context, queue: self.backgroundQueue)
                
                taskClosure(context)
            }
        }
    }
    
    public func getThreadSafeEntities<T: StorageEntityType>(for destinationContext: StorageContext, originalContext: StorageContext, originalEntities: [T], completion: @escaping ([T]) -> Void) throws {
        guard T.self is Object.Type else {
            throw StorageKitErrors.Entity.wrongType
        }
        
        guard let destinationContext = destinationContext as? RealmContextType,
            let originalQueue = contextRepo.retrieveQueue(for: originalContext),
            let destinationQueue = contextRepo.retrieveQueue(for: destinationContext) else {
                throw StorageKitErrors.Context.wrongType
        }
        
        retrieveThreadSafeReferences(queue: originalQueue, originalEntities: originalEntities) { refs in
            destinationQueue.async {
                autoreleasepool {
                    let threadSafeEntities: [T] = refs.lazy
                        .compactMap { destinationContext.realm.resolve($0) }
                        .compactMap { $0 as? T }
                    
                    completion(threadSafeEntities)
                }
            }
        }
    }
    
    private func retrieveThreadSafeReferences<T>(queue: DispatchQueue, originalEntities: [T], completion: @escaping ([ThreadSafeReference<Object>]) -> Void) {
        queue.async {
            
            let threadSafeRefs: [ThreadSafeReference] = originalEntities.lazy
                .compactMap { $0 as? Object }
                .compactMap { ThreadSafeReference(to: $0) }
            
            completion(threadSafeRefs)
        }
    }
}

