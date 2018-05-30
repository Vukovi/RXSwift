import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true

import RxSwift

// Sta su subjekti
// Oni se ponasaju i kao observable i kao observer
// Posotje 4 tipa subjekta u RxSwift-u
// PublishSubject - pocinje prazan i emituje samo nove elemente subscriberima
// BehaviorSubject - pocinje sa nekom inicijalnom vrednoscu i ponavlja subscriberima ili tu vrednost ili poslednji element
// ReplaySubject - pocinje sa nekom buffer velicinom i odrzavace elemente tog buffera do velicine buffera i ponvaljce ih novim subscriberima
// Varibale - vrapuje BehaviorSubject, cuva njegove trenutne vrednosti i ponvlaj ih novim subscriberima

// PublishSubject
// ----- 1 ----- 2 ----- 3 ----->   ovo je subjekat
//           |-- 2 ----- 3 ----->   prvi subscriber koji dobija sve posle svog potpisivanja na subjekat
//                   |-- 3 ----->   drugi subscriber koji dobije sve posle svog potpisivanja na subjekat

example(of: "PublishSubject") {
    let subject = PublishSubject<String>()
    subject.onNext("Ovo je za slusaoca")
    
    let subscriptionOne = subject.subscribe(onNext: { (string) in
        print("*", string)
        // Ovde se ne printa nista jer PublishSubject emituje samo trenutne subscribere
        // tako da ako nisam bio potpisan a nesto mu je dodato,
        // necu to nesto dobiti kadas se potpisem
    })
    // da bi se ovo iznad odstampalo treba dodati sledeci red
    subject.on(.next("1")) // * 1
    subject.onNext("2") // skracena verzija reda iznad // * 1  * 2
    
    let subscriptionTwo = subject.subscribe({ (event) in
        print("2)", event.element ?? event)
    })
    subject.onNext("3") // zbog stampanja reda iznad
    // * 1   * 2   * 3    2) 3
    
    subscriptionOne.dispose() // zaustavljamo prijem prvom subscriberu
    subject.onNext("4") // 2) 3    2) 4
    
    subject.onCompleted() // 2) completed
    subject.onNext("5") // ovo vise ne stampa
    
    subscriptionTwo.dispose() // zaustavljamo prijem drugom subscriberu
    
    let disposeBag = DisposeBag()
    
    // ovaj ce odmah emitovatovan event odraditi i prestace da slusa evente dalje
    subject.subscribe({
        print("3)", $0.element ?? $0) // 3) completed
    }).disposed(by: disposeBag)
    
    subject.onNext("?") // s obzirom da ej upotrebljen disposed iznad, a da su ostali subscriberi ponisteni, ovo se nece stampati
    
}

// BehaviorSubject
// ----- 1 ----- 2 ----- 3 ----->   ovo je subjekat
//          |1 - 2 ----- 3 ----->   prvi subscriber koji dobija i event pre svog potpisivanja na subjekat i sve ostale evente posle toga
//                  |2 - 3 ----->   drugi subscriber koji dobije i event pre svog potpisivanja na subjekat i sve ostale evente posle toga

enum MyError: Error {
    case greska
}

func print<T: CustomStringConvertible>(label: String, event: Event<T>) {
    print(label, event.error ?? event)
}

example(of: "BehaviorSubject") {
    let subject = BehaviorSubject(value: "Pocetna vrednost")
    let disposeBag = DisposeBag()
    subject.onNext("X")
    // sledece ce se potpisati na subject posle njegovog kreiranja, a s obzirom da nikakvi elementi ( ne racunam naknadno dodat subject.onNext("X") ) nisu dodati subjektu, subscriber ce dobiti pocetnu vrednost
    subject.subscribe({
        print(label: "1)", event: $0) // 1) next(Pocetna vrednost)
        // a sa dodatim subject.onNext("X") // next(X)
    })
    subject.onError(MyError.greska)
    subject.subscribe({
        print(label: "2)", event: $0)
    }).disposed(by: disposeBag)
    // 1) greska  2) greska  //  ovo printa u oba subscribera zbog koriscenja Errora kao poslednjeg eventa
}


// ReplaySubject
// ----- 1 ----- 2 ----- 3 ----->   ovo je subjekat
// ----- 1 ----- 2 ----- 3 ----->   prvi subscriber je potpisan na subjekat sve evente dobija kako su emitovani
//                 |1-2- 3 ----->   drugi subscriber se potpisuje na subjekat posle drugog eventa dobija velicinu eventova, tj onoliko eventova koliko je to bufferom predvidjeno (dva u ovom slucaju)
example(of: "ReplaySubject") {
    let subject = ReplaySubject<String>.create(bufferSize: 2)
    let disposeBag = DisposeBag()
    subject.onNext("1")
    subject.onNext("2")
    subject.onNext("3")
    subject.subscribe({
        print(label: "1)", event: $0)
    }).disposed(by: disposeBag) // 1) 2   1) 3
    subject.subscribe({
        print(label: "2)", event: $0)
    }).disposed(by: disposeBag) // 2) 2   2) 3
    
    subject.onNext("4") // 1) 4   2) 4
    subject.subscribe({
        print(label: "3)", event: $0)
    }).disposed(by: disposeBag) // 3) 3   3) 4
    
    subject.onError(MyError.greska) // 1) greska  2) greska  3) greska  // ovo se tri puta printa jer je je to poslednji aktivni event
    
    subject.dispose()
}

// Variables
// ne koristi se onNext i sigurno ne emituje Error i ne moze joj se dodeliti
example(of: "Varibale") {
    var variable = Variable("Pocetna vrednost")
    let disposeBag = DisposeBag()
    
    variable.value = "Nova inicijalna vrednost"
    variable.asObservable().subscribe({
        print(label: "1)", event: $0) // 1) next(Nova inicijalna vrednost)
    }).disposed(by: disposeBag)
    
    variable.value = "1"
    variable.asObservable().subscribe({
        print(label: "2)", event: $0)
    }).disposed(by: disposeBag)
    // 1) next(1)
    // 2) next(1)
    
    variable.value = "2"
    // 1) next(2)
    // 2) next(2)
    
}



// CHALLENGE 1
public let cards = [
    ("🂡", 11), ("🂢", 2), ("🂣", 3), ("🂤", 4), ("🂥", 5), ("🂦", 6), ("🂧", 7), ("🂨", 8), ("🂩", 9), ("🂪", 10), ("🂫", 10), ("🂭", 10), ("🂮", 10),
    ("🂱", 11), ("🂲", 2), ("🂳", 3), ("🂴", 4), ("🂵", 5), ("🂶", 6), ("🂷", 7), ("🂸", 8), ("🂹", 9), ("🂺", 10), ("🂻", 10), ("🂽", 10), ("🂾", 10),
    ("🃁", 11), ("🃂", 2), ("🃃", 3), ("🃄", 4), ("🃅", 5), ("🃆", 6), ("🃇", 7), ("🃈", 8), ("🃉", 9), ("🃊", 10), ("🃋", 10), ("🃍", 10), ("🃎", 10),
    ("🃑", 11), ("🃒", 2), ("🃓", 3), ("🃔", 4), ("🃕", 5), ("🃖", 6), ("🃗", 7), ("🃘", 8), ("🃙", 9), ("🃚", 10), ("🃛", 10), ("🃝", 10), ("🃞", 10)
]

public func cardString(for hand: [(String, Int)]) -> String {
    return hand.map { $0.0 }.joined(separator: "")
}

public func points(for hand: [(String, Int)]) -> Int {
    return hand.map { $0.1 }.reduce(0, +)
}

public enum HandError: Error {
    case busted
}

example(of: "PublishSubject") {
    
    let disposeBag = DisposeBag()
    
    let dealtHand = PublishSubject<[(String, Int)]>()
    
    func deal(_ cardCount: UInt) {
        var deck = cards
        var cardsRemaining: UInt32 = 52
        var hand = [(String, Int)]()
        
        for _ in 0..<cardCount {
            let randomIndex = Int(arc4random_uniform(cardsRemaining))
            hand.append(deck[randomIndex])
            deck.remove(at: randomIndex)
            cardsRemaining -= 1
        }
        
        // Add code to update dealtHand here
        if points(for: hand) > 21 {
            dealtHand.onError(HandError.busted)
        } else {
            dealtHand.onNext(hand)
        }
        
    }
    
    // Add subscription to dealtHand here
    dealtHand.subscribe(onNext: {
        print(cardString(for: $0), "for", points(for: $0), "points")
    }, onError: {
        print(String(describing: $0).capitalized)
    }).disposed(by: disposeBag)
    
    deal(3) // 🃍🃔🃂 for 16 points
}



// CHALLENGE 2
example(of: "Variable") {
    
    enum UserSession {
        case loggedIn, loggedOut
    }
    
    enum LoginError: Error {
        case invalidCredentials
    }
    
    let disposeBag = DisposeBag()
    
    // Create userSession Variable of type UserSession with initial value of .loggedOut
    var userSession: Variable<UserSession> = Variable(UserSession.loggedOut)
    
    
    // Subscribe to receive next events from userSession
    userSession.asObservable().subscribe(onNext: {
        print("User session is changed:", $0)
    }).disposed(by: disposeBag)
    
    
    func logInWith(username: String, password: String, completion: (Error?) -> Void) {
        guard username == "johnny@appleseed.com",
            password == "appleseed"
            else {
                completion(LoginError.invalidCredentials)
                return
        }
        
        // Update userSession
        userSession.value = .loggedIn
    }
    
    func logOut() {
        // Update userSession
        userSession.value = .loggedIn
    }
    
    func performActionRequiringLoggedInUser(_ action: () -> Void) {
        // Ensure that userSession is loggedIn and then execute action()
        guard userSession.value == .loggedIn else {
            print("Ne moze jer nisi ulogovan")
            return
        }
        action()
    }
    
    for i in 1...2 {
        let password = i % 2 == 0 ? "appleseed" : "password"
        
        logInWith(username: "johnny@appleseed.com", password: password) { error in
            guard error == nil else {
                print(error!)
                return
            }
            
            print("User logged in.")
        }
        
        performActionRequiringLoggedInUser {
            print("Successfully did something only a logged in user can do.")
        }
    }
}








