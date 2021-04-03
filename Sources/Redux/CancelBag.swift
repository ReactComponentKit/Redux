//
//  CancelBag.swift
//
//  Created by Suyeol Jeon (xoul.kr)
//
//  https://github.com/devxoul/CancelBag
//

/*
    The MIT License (MIT)

    Copyright (c) 2019 Suyeol Jeon (xoul.kr)

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/

import Combine
import class Foundation.NSLock

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class CancelBag: Cancellable {

  private let lock: NSLock = NSLock()
  private var cancellables: [Cancellable] = []

  public init() {
  }

  internal func add(_ cancellable: Cancellable) {
    self.lock.lock()
    defer { self.lock.unlock() }
    self.cancellables.append(cancellable)
  }

  public func cancel() {
    self.lock.lock()
    let cancellables = self.cancellables
    self.cancellables.removeAll()
    self.lock.unlock()

    for cancellable in cancellables {
      cancellable.cancel()
    }
  }

  deinit {
    self.cancel()
  }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Cancellable {
  func cancel(with cancellable: CancelBag) {
    cancellable.add(self)
  }
}
