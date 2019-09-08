import UIKit

// FRP ili funkcionalno reaktivno programiranje
// Razlika u odnosu na imperativno programiranje je u tome sto FRP omogucava modelovanje vremena, najjednostavnije receno

// Uzeci neki Label i TextView, gde label treba da reflektuje tekst unet u textView

let Label = UILabel()
let TextView = UITextView()

// imerpativano programiranje
func textViewDidChange(_ textView: UITextView) {
    Label.text = TextView.text
}
// Ovo je nesto sto je dobro poznato, a problem sa imperativnim programiranjem je u trenutku kada tekst labele postaje jednak
// tesktu iz textView-a, a to je tek kad udje u izvrsenje linije koda gde je to naznaceno i sve do tog momenta to nije tacno

func reaktivno() {
    // kod reaktivnog programiranja, ono sto je ostvareno imperativnom vezom izmedju labela i textView-a, ostvaruje se ovako:
    Label.reactive.text <~ TextView.reactive.continuousTextValues
    // binding target      binding source (u ovom slucaju signal)
    
    // Kod imperativnog programiranja ponasanje labela je odgovor na uneti tekst
    // Kod reaktivnog programiranja ponasanje labela je odgovor na evente
    
    
    //  SADRZAJ / ALATI  REAKTIVNOG SWIFTA  -  REACTIVE SWIFT PRIMITIVES
    // ---------------------------------------------------------------
    //      SOURCE       |  OPERATORI  |     CONSUMER     |  SCOPE
    // ---------------------------------------------------------------
    //      Event          SideEffects      Observer        Lifetime
    //      Signal          Transform    MutableProperty    Disposable
    //   SignalProducer      Combine
    //      Action          Flattern
    //     Property       ErrorHandling
    
    
    // Event - pokazuje nesto sto se vec desilo. Postoje 4 eventa
    //         Value - event sa validnom informacijom
    //         Failed - event koji pokazuje error
    //         Completed - event koji objavljuje kraj emitovanja i posle njega nece vise biti primanja dogadjaja
    //         Interrupted - objavljuje da je rad eventa prekinut
    //
    // Signal - je jednosmerno objavljivanje evenata. Sve evente salje istovremeno svim slusaocima(observerima).
    //          slusanjem Signala se ne mogu koristiti SideEffect-i
    //          On fukcionise kao emitovanje TV-a, SVOJ KLOZER ODRADJUJE ODMAH
    //
    // SignalProducer - jednostvano receno proizvodi signal koji moze biti iskoriscen kasnije u toku vremena.
    //                  on u stvari enkapsulira Signal koji se na taj nacin moze ponavljati vise puta i kasnije
    //                  tokom vremena. S'obzirom da SignalProducer MORA BITI POKRENUT (activate()), zato se moze
    //                  odigrati kasnije. Za njega se kaze da je Cold, a Signal koji se odigrava odmah je Warm.
    //                  On funkcionise kao OnDemand TV, SVOJ KLOZER ODRADJUJE ONDA KADA SE PRACENI PROPERTY PROMENI
    //
    // Action - radi isto sto i SignalProducer, samo sa vecom kontrolom. On enkaspulira SignalProducer. Kod njega
    //          se moze kontrolisati output slanjem razlicitih input vrednosti. Moze biti omogucen ili onemmogucen
    //          njegov state se moze kontrolisati pomocu property-ja. Kada se Action okine, on primeni input sa
    //          poslednjim state-om, a output salje observerima
    //          1. omogucuje serijsko izvrenje
    //          2. omogucava razne izmene unosa
    //          3. omogucava uslovljeno izvrenje koda
    //          4. omogucava da se porveri da li je izvresnje vec u toku
    //
    // Property - je observerski okvir koji cuva vrednosti i notifikuje observere o buducim promenama prema cuvanim
    //            vrednostima. Ima getere za producere i signale. Property se inicijalizuje ili sa pocetnom vrednoscu
    //            Signala, SignalProducera ili direktno preko drugog Property-ja
    //
    // Observer - enkapsulira ono sto treba da se obavi kao odgovor na emitovane evente. To je wrapper oko clouser-a
    //            koji uzima event kao input, a ovako se pravi:
    //
    //            let observer = Signal<Int,Error>.Observer.init { (event) in
    //                switch event {
    //                case let .value(val):
    //                    print("Vrednost: \(val)")
    //                case let .failed(err):
    //                    print("Error: \(err)")
    //                case .completed:
    //                    print("Dogadjaj je zavrsen")
    //                case .interrupted:
    //                    print("Dogadjaj je prekinut")
    //                }
    //             }
    //
    // MutableProperty - je observerski okvir kao i Property, isto ima getere za producera i signal, ali se za
    //                   razliku od Property-ja direktno zbog protokola BindingTargetProvider, tako da vrednosti
    //                   koje cuva moze da azurira, pomocu binding operatora | <~ |
    //
    // Disposable - je mehanizam menadzmenta memorije i otkazivanja rada. Kada se posmatra Signal, dobija se i
    //              jedan Disposable. Kada se Disposable isprazni, Observer vise nece gledati na evente doticnog Signala
    //              U slucaju SignalProducer-a, Disposable-om se moze prekinuti i izvrsenje kode je pocelo
    //
    // Lifetime - predstavlja zivotni vek objekta i korsitan je kada potpisivanje na event moze nadziveti observera.
    //            Npr, posmatramo notifikaciju dokle god je UI komponenta na ekranu.
    
    
    // Prakticna primena
    // PRETVARANJE SIGNALA - OMOGUCI DUGME KADA JE BROJ SLOVA TEKSTA U TEXT_FIELDU VECI OD 10
    
    let tField = UITextField()
    let button = UIButton()
    // definisanje signala
    let signal_1 = tField.reactive.continuousTextValues
    // transformisanje signala - jer za sada on emituje opcionalni string, a treba ga trensformisati da emituje Bool
    let tranformedSignal_1 = signal_1
        .map { $0.characters.count > 10 }
    // kreiram observer
    let observer_1 = Signal<Bool,Never>.Observer.init { (isMoreThen10) in
        button.isEnabled = isMoreThen10.value ?? false
    }
    // posmatranje signala
    let disposable_1 = tranformedSignal_1.observe(observer_1)
    //prestanak posmattrnaja signala
    disposable_1?.dispose()
    
    
    // UPOTREBA SIGNALA I PIPE-a - STAMPAJ PORUKE O TOME KOLIKO JE VREMENA PROSLO NA SVAKIH 5 SEKUNDI TOKOM INTERVALA OD 55 SEKUNDI
    
    // definisanje signala
    let (output, input) = Signal<Int,Never>.pipe()
    
    // saljem vrednost signala
    for interval in 0..<10 {
        DispatchQueue.main.asyncAfter(deadline: .now() + (5.0 * Double(interval))) {
            input.send(value: interval)
        }
    }
    
    // kreiram observer
    let observer_2 = Signal<Int,Never>.Observer.init(value: { (time) in
        print("Proteklo vreme iznosi: \(time)")
    }, failed: { (greska) in
        print("Koristio sam Never, tako da se greska nece desiti")
    }, completed: {
        print("Zavrseno odbrojavanje")
    }) {
        print("Prekinuto odbrojavanje")
    }
    // posmatranje signala
    let disposable_2 = output.observe(observer_2)
    
    //prestanak posmattrnaja signala
    disposable_2?.dispose()
    
    
    // UPOTREBA SIGNAL PRODUCERA - TEK POSTO SE PRITISNE DUGME STAMPAJ PORUKE O TOME KOLIKO JE VREMENA PROSLO NA SVAKIH 5 SEKUNDI TOKOM INTERVALA OD 55 SEKUNDI
    
    // definisanje signal producera - enkapsuliracu integer koji je emiter; inicijalizacije pomocu startHandler-a
    let signalProducer_3 = SignalProducer<Int,Never>.init { (signal, lifetime) in
        // ovde nam lifetime omogucuje da mozemo prekinuti desavanje ako je posmatranje prekinuto
        for interval in 0..<10 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(interval), execute: {
                // !!!! Vazno !!!!
                // Pre nego sto se pocne sa emitovanjem treba iskoristiti lifetime
                // Npr. prekinuo sam posmatranje evenata posle 10 sekundi
                // da signalProducer ne bi nastavio da odasilje evete koje niko ne slusa
                // i tako trosi resurse iskoristicu lifetime
                guard !lifetime.hasEnded else {
                    signal.sendInterrupted()
                    return
                }
                signal.send(value: interval)
                if interval == 9 {
                    signal.sendCompleted() // kad interval dodje do kraja sviraj kraj emitovanju
                }
            })
        }
    }
    
    // kreiram observer
    let observer_3 = Signal<Int,Never>.Observer.init(value: { (time) in
        print("Proteklo vreme iznosi: \(time)")
    }, failed: { (greska) in
        print("Koristio sam Never, tako da se greska nece desiti")
    }, completed: {
        print("Zavrseno odbrojavanje")
    }) {
        print("Prekinuto odbrojavanje")
    }
    
    // posmatranje signala i klik na dugme u cijoj bi funkcionalnosti stajalo ovo ispod
    let disposable_3 = signalProducer_3.start(observer_3)
    
    // signal producer mi omogucava da prekinem eventing, npr posle 10 sekundi
    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
        disposable_3.dispose()
    }
    
    
    // UPOTREBA PROPERTYja - TEK POSTO SE PRITISNE DUGME STAMPAJ PORUKE O TOME KOLIKO JE VREMENA PROSLO NA SVAKIH 5 SEKUNDI TOKOM INTERVALA OD 55 SEKUNDI
    
    // S'obzirom da propery ne radi sa errorima, mozemo iskoristiti prethodni signalProducer_3
    let property_4 = Property(initial: 0, then: signalProducer_3) // pocetna vrednost je 0
    
    // posmatranje signala
    let disposable_4 = property_4.producer.startWithValues { (val) in
        print("Proteklo vreme iznosi: \(val)") // --> 0 0 5 10 15 20 25 30 35 40 45   // ima nulu vise
    }
    disposable_4.dispose()
    // ili
    let disposable_5 = property_4.signal.observeValues { (val) in
        print("Proteklo vreme iznosi: \(val)") // --> 0 5 10 15 20 25 30 35 40 45
    }
    disposable_5?.dispose()
    
    
    // UPOTREBA MUTABILNOG PROPERTYja - ZGODAN JE ZA BINDOVANJE
    let mutableProperty_6 = MutableProperty(1)
    mutableProperty_6.value = 3
    mutableProperty_6 <~ property_4
    
    
    // UPOTREBA ACTIONA - STAMPAJ PORUKE O TOME KOLIKO JE VREMENA PROSLO NA SVAKIH N SEKUNDI SLEDECIH N * 10 SEKUNDI
    // Dakle, sta kad hocu da koristim razlicit interval stampanja svaki put kada pokrenem SignalProducerwhat?
    
    // kreiram generator signalProducera
    let signalProducerGenerator: (Int) -> SignalProducer<Int, Never>  = { timeInterval in
        return SignalProducer<Int, Never> { (observer, lifetime) in
            let now = DispatchTime.now()
            for index in 0..<10 {
                let timeElapsed = index * timeInterval
                DispatchQueue.main.asyncAfter(deadline: now + Double(timeElapsed)) {
                    guard !lifetime.hasEnded else {
                        observer.sendInterrupted()
                        return
                    }
                    observer.send(value: timeElapsed)
                    if index == 9 {
                        observer.sendCompleted()
                    }
                }
            }
        }
    }
    
    
    // kreiram signalProducere
    let signalProducer1 = signalProducerGenerator(1)
    let signalProducer2 = signalProducerGenerator(2)
    
    signalProducer1.startWithValues { value in
        print("vrednost od signalProducer1 = \(value)")
    }
    
    signalProducer2.startWithValues { value in
        print("vrednost od signalProducer2 = \(value)")
    }
    
    // Sad hocu da su ove dve akcije uzajamno povezane.
    // Drugim recima, necu da signalProducer2 startuje sve dok se signalProducer1 ne zavrsi.
    // Sad stupa na scenu - Action i to u obliku klozera koji je potreban
    let action = Action<(Int), Int, Never>(execute: signalProducerGenerator)
    //A. Posmatraj dobijene vrednosti
    action.values.observeValues { value in
        print("Proteklo vreme = \(value)")
    }
    
    //B. Posmatraj kada se prethodna aktivnost zavrsi
    action.values.observeCompleted {
        print("Akcija zavrsena")
    }
    
    // 1. Primeni akciju sa inputima i pokreni je
    action.apply(1).start()
    
    // 2. Ovo je ignorisano jer je akcija zauzeta izvresnjem pod 1
    action.apply(2).start()
    
    //3. Ovo ce biti izvrseno jer je pocetak sigurno posle zavrsetka izvrsenja action.apply(1)
    DispatchQueue.main.asyncAfter(deadline: .now() + 12.0) {
        action.apply(3).start()
    }
    
    
    // U prethodnom primeru Action je zavisila od spoljnih inputa, dobijenih preko apply metode.
    // Action se moze podesiti tako da moze praviti output zavisno od svog unutrasnjeg state-a, dikitrano Property-jem
    // kao i spoljnim inputima. U ovom slucaju izvrsni klozer moze pristupiti
    // i trenutnom state-u Action-a (predstavljeno Propertyjem) i spoljnom inputu koji dovodi apply metoda
    
    // Da bi se ovo razumelo posmatramo neku blogging aplikaciju sa sledecim zahtevom:
    // NASLOV BLOGA MORA DA IMA NAJMANJE 10 KARAKTERA - POTREBNO JE NAPRAVITI VALIDATOR KOJI PRIHVATA NAJMANJE 10 ZNAKOVA
    // I OBAVLJA PROVERU TRENUTNO UNETOG TEKSTSA
    
    // Potreban nam je ovakav klozer:      (State.Value, Input) -> SignalProducer<Output, Error>
    // Prvi parametar klozera predstavlja unutrasnji state, a drugi parametar predstavlja spoljasnji input dobijen preko apply metode
    // Dakle prvi parametar je tekst, a drugi je minimalni broj karaktera
    
    // 1. Pravim klozer koje ce emitovati bool vrednost u zavisnosti od toga da li je ispunjen zahtev o broju karaktera
    func lengthCheckerSignalProducer(text: String, minimumLength: Int) ->  SignalProducer<Bool, Never> {
        return SignalProducer<Bool, Never> { (observer, _) in
            observer.send(value: (text.count > minimumLength))
            observer.sendCompleted()
        }
    }
    
    // 2. Definisem Property
    // Ukoliko koristim ReactiveCocoa onda bih povezao signal od textField textField.reactive.continuousTextValues
    // Za sada cu da simuliram ovaj unos teksta pomocu Signala koji emituje jedan karakter svake sekunde
    func textSignalGenerator(text: String) -> Signal<String, Never> {
        return Signal<String, Never> { (observer, _) in
            let now = DispatchTime.now()
            for index in 0..<text.count {
                DispatchQueue.main.asyncAfter(deadline: now + 1.0 * Double(index)) {
                    let indexStartOfText = text.index(text.startIndex, offsetBy: 0)
                    let indexEndOfText = text.index(text.startIndex, offsetBy: index)
                    let substring = text[indexStartOfText...indexEndOfText]
                    let value = String(substring)
                    observer.send(value: value)
                }
            }
        }
    }
    
    let title = "ReactiveSwift"
    let titleSignal = textSignalGenerator(text: title)
    let titleProperty = Property(initial: "", then: titleSignal) // Evo ga property
    
    // 3. Definisem Action
    let titleLengthChecker = Action<Int, Bool, Never>(
        state: titleProperty,
        enabledIf: { $0.count > 5 },  // ovo uslovni parametar koji Action omogucava -> ne pocinji dok tekst nije preko 5 slova
        execute: lengthCheckerSignalProducer
    )
    
    // 4. Definisem observer
    titleLengthChecker.values.observeValues { isValid in
        print("is title valid = \(isValid)")
    }
    
    // 5. Odpocni Action
    for i in 0..<title.count {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(i)) {
            titleLengthChecker.apply(10).start()
        }
    }
    
    
    // DISPOSABLE
    // 1. Serijski disposabli - ce se otarasiti svog zavrapovanog disposable-a i omogouciti da bude zamenjen.
    //                          Zgodni su za upotrebu kada hocemo da se prethodni disposable zavrsi onda kada novi odpocinje.
    // 2. Scoped disposables - oni ce se otarsiti svog vrapovanog disposable-a onda kada budu deinicijalizovani.
    // 3. Kompozitni disposabli - cine kolekciju drugih disposable-a. Kada se pozove njihova metoda dispose(), cela kolekcija
    //                            se prazni. Ova vrsta dispozable je korisna onda kada prestanak slusanja svih signala i
    //                            i signalProducera hocu da napravim kada se klasa deinicijalizuje
    
    // NAPRAVITI STRUKTURU - TIMER - SA METODOM START(INTERVAL: INT) KOJA CE DA STAMPA PROTEKLO VREME ZA DATI INTERVAL
    
    struct Timer {
        func start(interval: Int) {
            self.timerSignalProducer(interval: interval).startWithValues { value in
                print("timeElapsed = \(value) : interval = \(interval)")
            }
        }
        
        func timerSignalProducer(interval: Int) -> SignalProducer<Int, Never> {
            return SignalProducer { (observer, lifetime) in
                for i in 0..<10 {
                    let timeElapsed = interval * i
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(timeElapsed)) {
                        guard !lifetime.hasEnded else {
                            observer.sendInterrupted()
                            return
                        }
                        observer.send(value: timeElapsed)
                        if i == 9 {
                            observer.sendCompleted()
                        }
                    }
                }
            }
        }
    }
    
    // primena
    let timer = Timer()
    timer.start(interval: 2)
    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
        timer.start(interval: 1)
    }
    /*
     timeElapsed = 0 : interval = 2
     timeElapsed = 2 : interval = 2
     timeElapsed = 4 : interval = 2
     timeElapsed = 0 : interval = 1
     timeElapsed = 1 : interval = 1
     timeElapsed = 6 : interval = 2
     timeElapsed = 2 : interval = 1
     timeElapsed = 3 : interval = 1
     timeElapsed = 8 : interval = 2
     timeElapsed = 4 : interval = 1
     timeElapsed = 5 : interval = 1
     timeElapsed = 10 : interval = 2
     timeElapsed = 6 : interval = 1
     timeElapsed = 7 : interval = 1
     timeElapsed = 12 : interval = 2
     timeElapsed = 8 : interval = 1
     timeElapsed = 9 : interval = 1
     timeElapsed = 14 : interval = 2
     timeElapsed = 16 : interval = 2
     timeElapsed = 18 : interval = 2
     Kao sto se moze videti, oba obsrevera su aktivna.
     Hocu da se prethdoni observer zavrsi onog momenta kada pozovem novi, tj kad opet pozovem start metodu.
     */
    
    struct TimerSerial {
        let serialDisposable = SerialDisposable()
        
        func start(interval: Int) {
            serialDisposable.inner = self.timerSignalProducer(interval: interval).startWithValues { value in
                print("timeElapsed = \(value) : interval = \(interval)")
            }
        }
        
        func timerSignalProducer(interval: Int) -> SignalProducer<Int, Never> {
            return SignalProducer { (observer, lifetime) in
                for i in 0..<10 {
                    let timeElapsed = interval * i
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(timeElapsed)) {
                        guard !lifetime.hasEnded else {
                            observer.sendInterrupted()
                            return
                        }
                        observer.send(value: timeElapsed)
                        if i == 9 {
                            observer.sendCompleted()
                        }
                    }
                }
            }
        }
    }
    // primena
    let timerSerial = TimerSerial()
    timerSerial.start(interval: 2)
    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
        timerSerial.start(interval: 1)
    }
    /*
     timeElapsed = 0 : interval = 2
     timeElapsed = 2 : interval = 2
     timeElapsed = 4 : interval = 2
     timeElapsed = 0 : interval = 1
     timeElapsed = 1 : interval = 1
     timeElapsed = 2 : interval = 1
     timeElapsed = 3 : interval = 1
     timeElapsed = 4 : interval = 1
     timeElapsed = 5 : interval = 1
     timeElapsed = 6 : interval = 1
     timeElapsed = 7 : interval = 1
     timeElapsed = 8 : interval = 1
     timeElapsed = 9 : interval = 1
     */
    // Ovde se javlja drugi problem. Ako se objekat deinicijalizuje, trenutno emitovanje ne prestaje
    var timerSerial_2: TimerSerial? = TimerSerial()
    timerSerial_2?.start(interval: 2)
    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
        timerSerial_2?.start(interval: 1)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
        timerSerial_2 = nil
    }
    /*
     timeElapsed = 0 : interval = 2
     timeElapsed = 2 : interval = 2
     timeElapsed = 4 : interval = 2
     timeElapsed = 0 : interval = 1
     timeElapsed = 1 : interval = 1
     timeElapsed = 2 : interval = 1
     timeElapsed = 3 : interval = 1
     timeElapsed = 4 : interval = 1
     timeElapsed = 5 : interval = 1
     timeElapsed = 6 : interval = 1
     timeElapsed = 7 : interval = 1
     timeElapsed = 8 : interval = 1
     timeElapsed = 9 : interval = 1
     Nastavio je da emituje dogadjaje sa intervalom 1 sekunda iako je emiter deinicijalizovan
     Ovo cemo resiti pomocu ScopeDisposable
     */
    
    struct TimerScoped {
        let serialDisposable = SerialDisposable()
        let scopedDisposable: ScopedDisposable<AnyDisposable>
        
        init() {
            self.scopedDisposable = ScopedDisposable(serialDisposable)
        }
        
        func start(interval: Int) {
            self.serialDisposable.inner = self.timerSignalProducer(interval: interval).startWithValues { value in
                print("timeElapsed = \(value) : interval = \(interval)")
            }
        }
        
        func timerSignalProducer(interval: Int) -> SignalProducer<Int, Never> {
            return SignalProducer { (observer, lifetime) in
                for i in 0..<10 {
                    let timeElapsed = interval * i
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(timeElapsed)) {
                        guard !lifetime.hasEnded else {
                            observer.sendInterrupted()
                            return
                        }
                        observer.send(value: timeElapsed)
                        if i == 9 {
                            observer.sendCompleted()
                        }
                    }
                }
            }
        }
    }
    
    var timerScoped: TimerScoped? = TimerScoped()
    timerScoped?.start(interval: 2)
    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
        timerScoped?.start(interval: 1)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
        timerScoped = nil
    }
    /*
     timeElapsed = 0 : interval = 2
     timeElapsed = 2 : interval = 2
     timeElapsed = 4 : interval = 2
     timeElapsed = 0 : interval = 1
     timeElapsed = 1 : interval = 1
     I jos jedan scenario.
     Npr da necemo da staro slusanje dogadjaja bude gotovo kada sledece pocne,
     vec hocemo da se sva slusanja zavrse onda kada ceo objekat u kojem se nalaze bude deinicijalizovan.
     Za taj scenario koristicemo CompositeDisposable
     */
    
    struct TimerComposite {
        let compositeDisposable = CompositeDisposable()
        let scopedDisposable: ScopedDisposable<AnyDisposable>
        
        init() {
            self.scopedDisposable = ScopedDisposable(self.compositeDisposable)
        }
        
        func start(interval: Int) {
            self.compositeDisposable += self.timerSignalProducer(interval: interval).startWithValues { value in
                print("timeElapsed = \(value) : interval = \(interval)")
            }
        }
        
        func timerSignalProducer(interval: Int) -> SignalProducer<Int, Never> {
            return SignalProducer { (observer, lifetime) in
                for i in 0..<10 {
                    let timeElapsed = interval * i
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(timeElapsed)) {
                        guard !lifetime.hasEnded else {
                            observer.sendInterrupted()
                            return
                        }
                        observer.send(value: timeElapsed)
                        if i == 9 {
                            observer.sendCompleted()
                        }
                    }
                }
            }
        }
    }
    var timerComposite: TimerComposite? = TimerComposite()
    timerComposite?.start(interval: 2)
    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
        timerComposite?.start(interval: 1)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
        timerComposite = nil
    }
    
    /*
     timeElapsed = 0 : interval = 2
     timeElapsed = 2 : interval = 2
     timeElapsed = 4 : interval = 2
     timeElapsed = 0 : interval = 1
     timeElapsed = 1 : interval = 1
     timeElapsed = 6 : interval = 2
     Oba su aktivna dok se timerComposite ne deinicijalizuje
     */
}
