import RxSwift

example(of: "sada, od, do") {
    let jedan = 1
    let dva = 2
    let tri = 3
    
    let observable: Observable<Int> = Observable<Int>.just(jedan)
    // observable2 nije array, nego je i dalje Observable<Int>
    let observable2 = Observable.of(jedan, dva, tri)
    // observable3 je array i to Observable<[Int]> niz
    let observable3 = Observable.of([jedan, dva, tri])
    // observable4 je Observable<Int> iako Observable.from uvek uzima niz kao argument
    let observable4 = Observable.from([jedan, dva, tri])
}

let observer = NotificationCenter.default.addObserver(forName: .UIKeyboardDidChangeFrame, object: nil, queue: nil) { (notification) in
    // uradi nesto sa primljenom notifikacijom
}

// Observable ima sequence definiciju, a potpisivanje na observable je nalik pozivanju meetode next() kod Iterator protokola
let sequence = 0..<3
var iterator = sequence.makeIterator()
while let n = iterator.next() {
    print(n) // 0  1  2
}
// a sad analogija sa RX observables
example(of: "subscribe") {
    let one = 1
    let two = 2
    let three = 3
    
    let observable = Observable.of(one, two, three)
    observable.subscribe({ (event) in
        print(event) // next(1) next(2) next(3) completed
        if let element = event.element {
            print(element) // 1  2  3
        }
    })
    // ovaj if let element = event.element ima svoju skracenicu
    observable.subscribe(onNext: { (element) in
        print(element)
    })
}

// zasto koristiti empty observable, zato sto nekad hocemo da odmah vratimo observable koji se istog trenutka zavrsava ili nam namerno treba observable sa nula vrednostima
example(of: "empty") {
    let observable = Observable<Void>.empty()
    observable.subscribe(onNext: { (element) in
        print(element)
    }, onCompleted: {
        print("Completed")
    })
}

// nasuprot Empty observable, postoji never observable koji ne emituje nista i nikad se ne zavrsava; moze se koristiti kada treba da predstavlja neko neprekidno trajanje
example(of: "never") {
    let observable = Observable<Any>.never()
    observable.subscribe(onNext: { (element) in
        print(element)
    }, onCompleted: {
        print("Completed") // ovo se kod njega nikad nece desiti
    })
}

example(of: "range") {
    let observable = Observable<Int>.range(start: 1, count: 10)
    observable.subscribe(onNext: { (i) in
        let n = Double(i)
        let fibonacci = Int(((pow(1.61803, n) - pow(0.61803, n))/2.23606).rounded())
        print(fibonacci)
    })
}

// Observables ne rade nista dok ne dobiju subscription
// Subscription je taj koji okida observable da emituje evente sve dok ne bude complete() ili error()

// Moze se manuelno zaustaviti observable ukidanjem potipisivanja na njega
example(of: "dispose") {
    let observable = Observable.of("A", "B", "C")
    let subscription = observable.subscribe({ (event) in
        print(event)
    })
    subscription.dispose() // ovim se prekida emitovanje eventa ovog observable-a
}

// DisposeBag se koristi kada ima vise subscription-a i bilo bi glupo hendlati svaki pojedinacno
// ovaj pattern se prilicno cesto koristi, jer se observable kreira i odmah se na njega potpisuje, a subscription se odmah dodaje u dipose bag
example(of: "DisposeBag") {
    let disposeBag = DisposeBag()
    Observable.of("A", "B", "C").subscribe({
        print($0)
    }).disposed(by: disposeBag)
}

// Jos jedan nacin, pored koriscenja next() metode, za kreiranje observable-a i emitovanje evenata subsciberima, je pomocu metode create()
example(of: "create") {
    enum MyError: Error {
        case anError
    }
    let disposeBag = DisposeBag()
    Observable<String>.create({ (observer) -> Disposable in
        observer.onNext("1")
        observer.onError(MyError.anError)
        observer.onCompleted() // ukoliko ukinem ovaj red i red iznad sa error-om dobicu memory leak
        observer.onNext("?") // nece se izvrsiti jer je posle complete()
        return Disposables.create() // ovo moze imati pratece efekte
    })
}

// Observable Factories
// Umesto da se kreiraju observable-i koji ce da cekaju na svoje subscribere, moze se napraviti fabrika koja ce dodeljivate observera svakom subscriberu
example(of: "deferred") {
    let disposeBag = DisposeBag()
    var flip = false
    let factory: Observable<Int> = Observable.deferred({
        flip = !flip
        if flip {
            return Observable.of(1,2,3)
        } else {
            return Observable.of(4,5,6)
        }
    })
    
    for _ in 0...3 {
        factory.subscribe(onNext: {
            print($0, terminator: "")
        }).disposed(by: disposeBag)
        print() // 123  456  123  456
    }
}

// CHALLENGE 1
example(of: "never - challenge 1") {
    
    let observable = Observable<Any>.never()
    
    let disposeBag = DisposeBag()
    
    observable
        .do(onSubscribe: {
            print("Subscribed")
        })
        .subscribe(
            onNext: { element in
                print(element)
        },
            onCompleted: {
                print("Completed")
        },
            onDisposed: {
                print("Disposed")
        })
        .disposed(by: disposeBag)
}

// CHALLENGE 2
example(of: "never - challenge 2") {
    
    let observable = Observable<Any>.never()
    
    let disposeBag = DisposeBag()
    
    observable
        .debug() // ovaj umesto do pokriva odmah sve po pitanju debugging-a
        .subscribe(
            onNext: { element in
                print(element)
        },
            onCompleted: {
                print("Completed")
        },
            onDisposed: {
                print("Disposed")
        })
        .disposed(by: disposeBag)
}


