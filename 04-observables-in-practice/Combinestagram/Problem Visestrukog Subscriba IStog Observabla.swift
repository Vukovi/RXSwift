//
//  Problem Visestrukog Subscriba IStog Observabla.swift
//  Combinestagram
//
//  Created by Vuk Knežević on 6/16/18.
//  Copyright © 2018 Underplot ltd. All rights reserved.
//

import Foundation
import RxSwift

class ProblemVisetrukogSubscribovanjaNaIstiObservable: NSObject {
    static var start = 0
    
    static func getStartNumber() -> Int {
        start += 1
        return start
    }
    
    let numbers = Observable<Int>.create { (observer) -> Disposable in
        var start: Int = ProblemVisetrukogSubscribovanjaNaIstiObservable.getStartNumber()
        observer.onNext(start)
        observer.onNext(start + 1)
        observer.onNext(start + 2)
        observer.onCompleted()
        return Disposables.create()
    }
    
    override init() {
        numbers.subscribe(onNext: { (element) in
            print("Element je \(element)")
        }) {
            print("-----------")
        }
        // Prvi print ce biti - "Element je 1"  "Element je 2"  "Element je 3"
        // Ali ako bih jos jednom potpisao na numbers
        numbers.subscribe(onNext: { (element) in
            print("Element je \(element)")
        }) {
            print("-----------")
        }
        // Drugi print ce biti - "Element je 2"  "Element je 3"  "Element je 4"
        // Problem je u tome sto svaki put kad pozovem subscribe na numbers, numbers pravi novi Observable, a svaka novi KOPIJA nije ista kao prethodna
        // Da bi se ovo izbeglo koristi se SHARE() metoda
    }
    
    
    
}
