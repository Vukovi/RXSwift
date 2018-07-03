import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true

import RxSwift

// postoje situacije u kojima nam je potrebno da je observable dobio inicijalnu vrednost
// npr. potrebna nam je trenutna vrednost - current location & network connectivity status
// to bi bili observable-i kojima bi bilo potrebno trenutno stanje kao prefiks

// source                    X----2----3----4---->
// source startWith 1:  X----1----2----3----4---->

example(of: "startWith") {
    let numbers = Observable.of(2,3,4)
    let observable = numbers.startWith(1)
    observable.subscribe(onNext: { (value) in
        print(value)
    })
    // 1
    // 2
    // 3
    // 4
}

example(of: "concat") {
    let first = Observable.of(1,2,3)
    let second = Observable.of(4,5,6)
    let observable = Observable.concat([first, second])
    observable.subscribe(onNext: { (value) in
        print(value)
    })
    // ako bilo koji od elemenata u konkatenaciji daje error, observable prestaje da emituje na tom mestu i baca error
    // drugi nacina za konkatenaciju
    let spanishCities = Observable.of("Madrid","Barcelona","Valencia")
    let germanCities = Observable.of("Berlin","Frankfurt","Munich")
    let observable2 = germanCities.concat(spanishCities)
    observable2.subscribe(onNext: { (value) in
        print(value)
    })
    // isto sto START_WITH
    let numbers = Observable.of(2,3,4)
    let observable3 = Observable.just(1).concat(numbers)
    observable3.subscribe(onNext: { (value) in
        print(value)
    })
    // KONAKTENACIJA vazi samo za iste tipove, je je strongly type
}


// LEVO    X----A--------------B---------C---->
// DESNO   X---------1----2---------3--------->
// SOURCE          X---LEVO---DESNO--->
// MERGE   X----A----1----2----B----3----C---->

example(of: "merge") {
    let levo = PublishSubject<String>()
    let desno = PublishSubject<String>()
    let source = Observable.of(levo.asObservable(), desno.asObservable())
    let observable = source.merge()
    let disposable = observable.subscribe(onNext: { (value) in
        print(value)
    })
    
    var leveVrednosti = ["Madrid","Barcelona","Valencia"]
    var desneVrednosti = ["Berlin","Frankfurt","Munich"]
    repeat {
        if arc4random_uniform(2) == 0 {
            if !leveVrednosti.isEmpty {
                levo.onNext("Levo: " + leveVrednosti.removeFirst())
            }
        } else if !desneVrednosti.isEmpty {
            desno.onNext("Levo: " + desneVrednosti.removeFirst())
        }
    } while !leveVrednosti.isEmpty || !desneVrednosti.isEmpty
    
    disposable.dispose()
    
}


// LEVO             X----A---------------B------------C---->
// DESNO            X---------1-----2-----------3---------->
// COMBINE_LATEST   X---------A1---A2----B2----B3----C3---->

example(of: "combineLatest") {
    let levo = PublishSubject<String>()
    let desno = PublishSubject<String>()
    let observable = Observable.combineLatest(levo, desno, resultSelector: { poslednjiLevo, poslednjiDesno in
        "\(poslednjiLevo) \(poslednjiDesno)"
    })
    let disposable = observable.subscribe(onNext: { (value) in
        print(value)
    })
    
    print("Vrednost ide na Levo")
    levo.onNext("Pozdrav")
    print("Vrednost ide na Desno")
    desno.onNext("Cao")
    print("Vrednost opet na Levo")
    levo.onNext("RxSwift")
    print("Vrednost opet na Desno")
    desno.onNext("Dovidjenja")
    
    disposable.dispose()
}


// LEVO             X----A-------B--------B------------C---->
// DESNO            X-------1--------2-----------3---------->
// COMBINE_LATEST   X---------A1------B2----------B3-------->

example(of: "zip") {
    enum Weather {
        case cloudy
        case sunny
    }
    let levo: Observable<Weather> = Observable.of(.sunny, .cloudy, .cloudy, .sunny)
    let desno = Observable.of("Lisbon", "Copenhagen", "London", "Madrid", "Vienna")
    let observable = Observable.zip(levo, desno, resultSelector: { weather, city  in
        return "It's \(weather) in \(city)"
    })
    observable.subscribe(onNext: { (value) in
        print(value)
    })
    // "It's sunny in Lisbon"
    // "It's cloudy in Copenhagen"
    // "It's cloudy in London"
    // "It's sunny in Madrid"
    // dalje nece jer nema sta da upari sa Vienna
}


// BUTTON          X-------------------------------tap-------tap-------->
// TEXT FIELD      X---"Par"---"Pari"---"Paris"------------------------->
// withLatestFrom  X------------------------------"Paris"---"Paris"----->

example(of: "withLatestFrom") {
    let button = PublishSubject<Void>()
    let textField = PublishSubject<String>()
    
    let observable = button.withLatestFrom(textField)
    let disposable = observable.subscribe(onNext: { (value) in
        print(value)
    })
    
    textField.onNext("Par")
    textField.onNext("Pari")
    textField.onNext("Paris")
    button.onNext(())
    button.onNext(())
    
    disposable.dispose()
    
    let observable2 = textField.sample(button)
}

// BUTTON          X-------------------------------tap-------tap-------->
// TEXT FIELD      X---"Par"---"Pari"---"Paris"------------------------->
// sample          X------------------------------"Paris"--------------->




// LEVO             X-------.....1.......2...........3....>
// DESNO            X-------4------5-----------6---------->
// AMB              X-------4------5-----------6---------->

example(of: "amb") {
    let levo = PublishSubject<String>()
    let desno = PublishSubject<String>()
    
    let observable = levo.amb(desno)
    let disposable = observable.subscribe(onNext: { (value) in
        print(value)
    })
    
    levo.onNext("Lisabon")
    desno.onNext("Kopenhagen")
    levo.onNext("London")
    levo.onNext("Madrid")
    desno.onNext("Bec")
    
    disposable.dispose()
    
    // ovaj stampa samo leve podatke
}


// LEVO            X---1-----2--------------------3---->
// DESNO           X------4----5---------------6------->
// SOURCE          X--one--------------two------------->
// SWITCH_LATEST   X---1-----2-----------------6------->

example(of: "switchLatest") {
    let one = PublishSubject<String>()
    let two = PublishSubject<String>()
    let three = PublishSubject<String>()
    
    let source = PublishSubject<Observable<String>>()
    
    let observable = source.switchLatest()
    let disposable = observable.subscribe(onNext: { (value) in
        print(value)
    })
    
    source.onNext(one)
    one.onNext("Nesto za jedan")
    two.onNext("Nesto za dva")
    
    source.onNext(two)
    two.onNext("Opet nesto za dva")
    one.onNext("Opet nesto za jedan")
    
    source.onNext(three)
    two.onNext("Ne vidim te")
    one.onNext("Sam sam")
    three.onNext("Trojka")
    
    source.onNext(one)
    one.onNext("Ipak jedan")
    
    disposable.dispose()
    
    // "Nesto za jedan"
    // "Opet nesto za dva"
    // "Trojka"
    // "Ipak jedan"
}

// SEQ      X----1--------2-----3-------->
// REDUCE   X----------------------6----->   sabrao je sve iz SEQ

example(of: "reduce") {
    let source = Observable.of(1,3,5,7,9)
    let observable = source.reduce(0, accumulator: +)
    // ovo gore je u stvari ovo dole
//    let observable = source.reduce(0, accumulator: { summary, newValue  in
//        return summary + newValue
//    })
    observable.subscribe(onNext: { (value) in
        print(value) // 25
    })
}


// Seq    X---1---2---3--->
// SCAN   X---1---3---6

example(of: "scan") {
    let source = Observable.of(1,3,5,7,9)
    let observable = source.reduce(0, accumulator: +)
    observable.subscribe(onNext: { (value) in
        print(value) // 1, 4, 9, 16, 25
    })
    
//    let observable2 = Observable.zip(source, scanObservable) { value, runningTotal in
//        (value, runningTotal)
//    }
//    observable2.subscribe(onNext: { tuple in
//        print("Value = \(tuple.0)   Running total = \(tuple.1)")
//    })
}
