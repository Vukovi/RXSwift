import RxSwift

// ignoringElements() ce ignostisti next() evente, ali ce zato moci da zaustave eventing preko completed() ili error()

// ignosringEvents je koristan kada mi treba obavestenje da je observable gotov

example(of: "ignoringElements") {
    let strikes = PublishSubject<String>()
    let disposeBag = DisposeBag()
    
    // ovde ce se potpisati na sve strike-ove evente, ali ce ignorisati sve next() dogadjaje
    strikes.ignoreElements().subscribe({ (_) in
        print("You are out!")
    }).disposed(by: disposeBag)
    
    strikes.onNext("X")
    strikes.onNext("X")
    strikes.onNext("X")
    strikes.onCompleted() // stampa samo "You are out!"

}


example(of: "elementAt") {
    let strikes = PublishSubject<String>()
    let disposeBag = DisposeBag()
    strikes.elementAt(2).subscribe({ (_) in // ovim se igonrise sve osim 3. elementa (indeksno mesto 2)
        print("You are out!")
    }).disposed(by: disposeBag)
    
    strikes.onNext("X")
    strikes.onNext("X")
    strikes.onNext("X") // stampa samo "You are out!"
}


example(of: "filter") {
    let disposeBag = DisposeBag()
    Observable.of(1,2,3,4,5,6).filter({ (integer) -> Bool in
        integer % 2 == 0
    }).subscribe(onNext: {
        print($0)                    // 2   4   6
    }).disposed(by: disposeBag)
}

example(of: "skip") {
    let disposeBag = DisposeBag()
    Observable.of("A","B","C","D","E","F")
        .skip(3)                   ///  ovim preksace prva tri elementa
        .subscribe(onNext: {
            print($0)              ///  D  E  F
        })
        .disposed(by: disposeBag)
}


example(of: "skipWhile") {
    let disposeBag = DisposeBag()
    Observable.of(2,2,3,4,4)
        .skipWhile({ (integer) -> Bool in
            integer % 2 == 0  // zbog ovoga preskakace sve dok se ne pojavi neparni broj
        })
        .subscribe(onNext: {
            print($0)        // 3  4  4
        })
        .disposed(by: disposeBag)
}

example(of: "skipUntil") {
    let disposeBag = DisposeBag()
    let subject = PublishSubject<String>()
    let trigger = PublishSubject<String>()
    
    subject
        .skipUntil(trigger)  // dok se ne emituje event triggera nece pratiti evente
        .subscribe(onNext: {
            print($0)        // "C"
        })
        .disposed(by: disposeBag)
    
    
    subject.onNext("A")
    subject.onNext("B")
    
    trigger.onNext("X")
    
    subject.onNext("C")
}

example(of: "take") {
    let disposeBag = DisposeBag()
    Observable.of(1,2,3,4,5,6)
        .take(3)             //  uzece prva tri elementa
        .subscribe(onNext: {
            print($0)        // 1  2  3
        })
        .disposed(by: disposeBag)
}

example(of: "takeWhileWithIndex") {
    let disposeBag = DisposeBag()
    Observable.of(2,2,4,4,6,6)
        .takeWhileWithIndex({ (integer, index) -> Bool in
            integer % 2 == 0 && index < 3  // gledaj parne i one kojima je index manji od 3
        })
        .subscribe(onNext: {
            print($0)        // 2  2  4
        })
        .disposed(by: disposeBag)
}

example(of: "takeUntil") {
    let disposeBag  = DisposeBag()
    let subject = PublishSubject<String>()
    let trigger = PublishSubject<String>()
    
    subject
        .takeUntil(trigger)
        .subscribe(onNext: {
            print($0)        // 1  2
        })
        .disposed(by: disposeBag)
    
    subject.onNext("1")
    subject.onNext("2")
    
    trigger.onNext("X")
    subject.onNext("3")
    
    //takeUntil se moze koristiti umesto disposeBag-a
    /*
     someObservable
        .takeUntil(self.rx.deallocated)
        .subscribe(onNext: {
            print($0)
        })
    */
}

example(of: "distinctUntilChanged") {
    let disposeBag = DisposeBag()
    Observable.of("A","A","B","B","A")
        .distinctUntilChanged() // ovim se sprecava gledanje uzastopnih duplikata
        .subscribe(onNext: {
            print($0)        // A B A
        })
        .disposed(by: disposeBag)
}

example(of: "distinctUntilChanged(_:)") {
    let disposeBag = DisposeBag()
    let formatter = NumberFormatter()
    formatter.numberStyle = .spellOut
    
    Observable<NSNumber>.of(10,110,20,200,210,310)
        .distinctUntilChanged({ (a, b) -> Bool in
            guard let aWords = formatter.string(from: a)?.components(separatedBy: " "), let bWords = formatter.string(from: b)?.components(separatedBy: " ") else { return false}
            var containsMatch = false
            for aWord in aWords {
                for bWord in bWords {
                    if aWord == bWord {
                        containsMatch = true
                        break
                    }
                }
            }
            return containsMatch
        })
        .subscribe(onNext: {
            print($0)      // 10   20   200
        })
        .disposed(by: disposeBag)
}


// Challenge - create a phone number lookup

example(of: "Challenge 1") {
    
    let disposeBag = DisposeBag()
    
    let contacts = [
        "603-555-1212": "Florent",
        "212-555-1212": "Junior",
        "408-555-1212": "Marin",
        "617-555-1212": "Scott"
    ]
    
    func phoneNumber(from inputs: [Int]) -> String {
        var phone = inputs.map(String.init).joined()
        
        phone.insert("-", at: phone.index(
            phone.startIndex,
            offsetBy: 3)
        )
        
        phone.insert("-", at: phone.index(
            phone.startIndex,
            offsetBy: 7)
        )
        
        return phone
    }
    
    let input = PublishSubject<Int>()
    
    // Add your code here
    // Broj ne moze da pocne sa 0 - skipWhile
    // Unos broja telefona moze biti serija JEDNOCIFRENIH BROJEVA - filter
    // Broj telefona mora imati manje od 10 cifara - take % toArray
    
    input
        .skipWhile({
            $0 == 0
        })
        .filter({
            $0 < 10
        })
        .take(10).toArray()
        .subscribe(onNext: {
            let phone = phoneNumber(from: $0)
            if let contact = contacts[phone] {
                print("Zovem \(contact) \(phone)")
            } else {
                print("Kontakt nije pronadjen")
            }
        })
    
    input.onNext(0)
    input.onNext(603)
    
    input.onNext(2)
    input.onNext(1)
    
    // Confirm that 7 results in "Contact not found", and then change to 2 and confirm that Junior is found
    input.onNext(7)
    
    "5551212".characters.forEach {
        if let number = (Int("\($0)")) {
            input.onNext(number)
        }
    }
    
    input.onNext(9)
}











