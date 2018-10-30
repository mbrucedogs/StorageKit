//
//  ContextRepo.swift
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

public protocol ContextRepoType: class {
	init(cleaningTimerInterval: Double?)

	func store(context: StorageContext?, queue: DispatchQueue)
	func retrieveQueue(for context: StorageContext) -> DispatchQueue?
}

final public class ContextRepo {

	var cleaningTimerInterval: Double = 3 * 60

    fileprivate var contextQueues: [String: ContextQueue]

	private var cleaningTimer = Timer()

    public init(cleaningTimerInterval: Double? = nil) {
        contextQueues = [:]

		if let cleaningTimerInterval = cleaningTimerInterval {
			self.cleaningTimerInterval = cleaningTimerInterval
		}

		cleaningTimer = Timer.scheduledTimer(timeInterval: self.cleaningTimerInterval, target: self, selector: #selector(cleanNilReferences), userInfo: nil, repeats: true)
    }

	deinit {
		cleaningTimer.invalidate()
	}

	@objc
	private func cleanNilReferences() {
		contextQueues.lazy
			.filter { $1.context == nil || $1.queue == nil }
			.flatMap { $0.key }
			.forEach { contextQueues.removeValue(forKey: $0) }
	}
}

extension ContextRepo: ContextRepoType {
    public func store(context: StorageContext?, queue: DispatchQueue) {
		if let context = context {
			contextQueues[context.identifier] = ContextQueue(context: context, queue: queue)
		}
	}

    public func retrieveQueue(for context: StorageContext) -> DispatchQueue? {
		return contextQueues[context.identifier]?.queue
	}
}
