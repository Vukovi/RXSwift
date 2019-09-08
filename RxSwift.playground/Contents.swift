import UIKit
// Nisam importovao RxSwift i RxCocoa

class RxSwift: UIViewController {
    var tableView: UITableView = UITableView()
    var movieSearch: UISearchBar = UISearchBar()
    
    var movies = [String]() {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    let disposalBag = CompositeDisposable()
    let disposableBag = DisposeBag()
    
    deinit {
        print("EVO GA DEINIT")
        disposalBag.dispose()
    }
    
    enum EventError: Error {
        case Test
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // movieSearch je koriscenjem subscribe-a postao disposable
        // a disposable poseduje u sebi ARC, tj neku vrstu ARC-a kojim eliminise posmatrace
        // ali mora se odraditi despose()
        movieSearch.rx.text
            .orEmpty // ako je searchBar prazan ne reaguj
            .distinctUntilChanged() // ako u searchBar nesto upises, brises i na
            // kraju rezultat bude isti kao sto je bio, nece ga
            // pustiti da reaguje, da ne bi imao objavu istog
            // dogadjaja; veoma je korisna stvar
            .filter{ !$0.isEmpty } // jos jedna provera isto ono sto radi .OrEMPTY, jer moze
            // da se desi da sam nesto pisao,zastao, vratio se i
            // obrisao do kraja, a prva dva uslova su pustila event dalje
            .debounce(0.5, scheduler: MainScheduler.instance) // ovo je vremenska
            // kontrola pustanja dogadjaja, sacekaj 0.5 sekundi pri emitovanju
            // svakog dogadjaja, a to je svako novo uneto slovo, i onda, posto je
            // u pitanju UI komponenta, tj movieSearcBar, idi na main thread
            // posle ovih vremenskih kontrola, obicno se pravi subscriber
            // pored DEBOUNCE, slicno radi THROTTLE
            .subscribe(onNext: { query in
                let url = "https://www.omdbapi.com/?apikey=" + Values.key + "&s=" + query
                
                Alamofire.request(url).responseJSON(completionHandler: { response in
                    if let value = response.result.value {
                        let json = JSON(value)
                        
                        self.movies.removeAll()
                        
                        for movie in json["Search"] {
                            if let title = movie.1["Title"].string {
                                self.movies.append(title)
                            }
                        }
                    }
                })
            })
        
        // Observables
        
        let observable1 = Observable.just("Pozdrav!")
        let disposable1: Disposable = observable1.subscribe { (event: Event<String>) in // mada je  ovo vec i ponudio tako da nisam morao da ga kastujem kao Event<String>
            print("Observable 1: \(event)")
        }
        disposableBag.insert(disposable1)
        /*
         Observable 1: next(Pozdrav!)
         Observable 1: completed
         */
        
        let observable2 = Observable.of(1,2,3)
        let disposable2: Disposable = observable2.subscribe { (event) in
            print("Observable 2: \(event)")
        }
        disposableBag.insert(disposable2)
        /*
         Observable 2: next(1)
         Observable 2: next(2)
         Observable 2: next(3)
         Observable 2: completed
         */
        
        // MARK: - Subjects - mogu biti i observer i observable
        // MARK: - 1. Publish Subject
        // Kada je disposable, odnosno slusalac, napravljen potpisivanjem na Publish Subject, slusalac uzima samo evente koje dobija posle svog kreiranja
        let publishSubject = PublishSubject<String>()
        let disposable3: Disposable = publishSubject.subscribe { (event) in
            print("PublishSubject: \(event)")
        }
        disposableBag.insert(disposable3)
        publishSubject.on(Event.next("Cao Publish Subject"))
        publishSubject.onNext("onNext - Isto sto i ovo iznad")
        //        publishSubject.onError(EventError.Test)
        //        publishSubject.onNext("Sad nece proci ni do onCompleted jer ga zaustavlja onError")
        //        publishSubject.onCompleted()
        //        publishSubject.onNext("Ovo se ne vidi jer je onCompleted iznad iskoriscen i on zaustavlja eventing")
        let disposable4 = publishSubject.subscribe { (event) in
            print("PublishSubject Novi Event: \(event)")
        }
        disposableBag.insert(disposable4)
        publishSubject.onNext("Gde se vidi ovaj event")
        /*
         PublishSubject: next(Cao Publish Subject)
         PublishSubject: next(onNext - Isto sto i ovo iznad)
         PublishSubject: next(Gde se vidi ovaj event)
         PublishSubject Novi Event: next(Gde se vidi ovaj event)
         */
        publishSubject.onNext("A OVAJ")
        /*
         PublishSubject: next(Cao Publish Subject)
         PublishSubject: next(onNext - Isto sto i ovo iznad)
         PublishSubject: next(Gde se vidi ovaj event)
         PublishSubject Novi Event: next(Gde se vidi ovaj event)
         PublishSubject: next(A OVAJ)
         PublishSubject Novi Event: next(A OVAJ)
         */
        
        
        // MARK: - 2. Behavior Subject
        // Kada je slusalac, odnosno disposable, napravljen potpisivanjem na Behavior Subject, slusalac uzima i event koji se desio pre njegovog kreiranja i naravno evente koje dobija posle svog kreiranja.
        let behaviorSubject = BehaviorSubject(value: "AA")
        let disposable5: Disposable = behaviorSubject.subscribe { (event) in
            print("BehaviorSubject: \(event)")
        }
        disposableBag.insert(disposable5)
        behaviorSubject.onNext("BB")
        let disposable6: Disposable = behaviorSubject.subscribe { (event) in
            print("BehaviorSubject Novi: \(event)")
        }
        disposableBag.insert(disposable6)
        /*
         BehaviorSubject za razliku od PublishSubjecta uzme poslednji dogadjaj koji se sedio pre kreiranja novog slusaoca
         BehaviorSubject: next(AA)
         BehaviorSubject: next(BB)
         BehaviorSubject Novi: next(BB)
         */
        
        // MARK: - 3. Reply Subject
        // Kada je slusalac, odnosno disposable, napravljen potpisivanjem na Reply Subject, slusalac uzima onoliko poslednjih evenata pre nego sto je kreiran, koliko ih je obaveznom inicijalizacijom definisano i naravno sve evente koji slede pose njegovog kreiranja
        let replySubject = ReplaySubject<String>.create(bufferSize: 3)
        replySubject.onNext("prvi reply")
        replySubject.onNext("drugi reply")
        replySubject.onNext("treci reply")
        replySubject.onNext("cetvrti reply")
        let disposable7: Disposable = replySubject.subscribe { (event) in
            print("ReplaySubject: \(event)")
        }
        disposableBag.insert(disposable7)
        replySubject.onNext("peti reply")
        /*
         ReplaySubject: next(drugi reply)
         ReplaySubject: next(treci reply)
         ReplaySubject: next(cetvrti reply)
         ReplaySubject: next(peti reply)
         */
        
        // MARK: - 4. Variable
        let variable = Variable("VAR-A")
        let disposable8 = variable.asObservable().subscribe { (event) in
            print("Variable: \(event)")
        }
        disposableBag.insert(disposable8)
        variable.value = "VAR-B" // ovo zapravo nije promenjena vrednost nego dodat novi event
        /*
         Variable: next(VAR-A)
         Variable: next(VAR-B)
         Variable: completed
         */
        
        // MARK: - Mapiranje
        let om = Observable.of(1,2,3)
        let dm = om.map { $0 * $0 }.subscribe { print("Nisam svestan mapiranja, a ovo je ono sto dobijam: \($0)") }
        disposableBag.insert(dm)
        /*
         Nisam svestan mapiranja, a ovo je ono sto dobijam: next(1)
         Nisam svestan mapiranja, a ovo je ono sto dobijam: next(4)
         Nisam svestan mapiranja, a ovo je ono sto dobijam: next(9)
         Nisam svestan mapiranja, a ovo je ono sto dobijam: completed
         */
        
        // MARK: - Flat Map & Flat Latest Map
        struct Player {
            let score: Variable<Int>
        }
        let igrac1 = Player(score: Variable<Int>(60))
        let igrac2 = Player(score: Variable(85))
        
        let player = Variable<Player>(igrac1)
        
        let disp = player.asObservable()
            .flatMap { $0.score.asObservable() }  // trazim event property unutar Player structa i onda ga krstim kao observable
            .subscribe { print("score player: \($0)") }
        disposableBag.insert(disp)
        /*
         score player: next(60)
         score player: completed
         Variable: completed
         */
        player.value.score.value = 64
        /*
         score player: next(60)
         score player: next(64)
         score player: completed
         Variable: completed
         */
        igrac1.score.value = 71 // S'obzirom da player prati kao event p1, odnosno rezultat koji pravi igrac1, tacnije event score, ova promena je takodje notirana
        /*
         score player: next(60)
         score player: next(64)
         score player: next(71)
         score player: completed
         Variable: completed
         */
        // sad cu da promenim igraca kojeg slusa player
        player.value = igrac2
        igrac2.score.value = 93
        igrac1.score.value = 100
        /*
         score player: next(60)
         score player: next(64)
         score player: next(71)
         score player: next(85)
         score player: next(93)
         score player: next(100)  sa FlatMapom
         score player: completed
         Variable: completed
         */
        /*
         score player: next(60)
         score player: next(64)
         score player: next(71)
         score player: next(85)
         score player: next(93)
         FlatMapLatest prati samo poslednji izvor
         score player: completed
         Variable: completed
         */
        
        // Flat map slusa sve izvore, iako je zamenjen igrac koji se slusa, flatMap pamti sve sto je slusao za razliku of FlatMapLatest koji pamti samo poslednjeg emitera.
        
        // MARK: - Scan je veoma slicno sto i Swiftov reduce()
        let odbrojavanje = PublishSubject<Int>()
        let potpisnik = odbrojavanje.asObservable()
            .scan(501) { (trenutnaVrednost, novaVrednost) -> Int in
                let result = trenutnaVrednost - novaVrednost
                return result >= 0 ? result : trenutnaVrednost
            }
            .filter { (trenutnaVrednost) -> Bool in
                if trenutnaVrednost == 0 {
                    odbrojavanje.onCompleted()
                }
                return true
            }
            .subscribe { (trenutnaVrednost) in
                print("Trenutna vrednost je \(trenutnaVrednost)")
        }
        disposableBag.insert(potpisnik)
        
        odbrojavanje.onNext(13)
        odbrojavanje.onNext(60)
        odbrojavanje.onNext(50)
        odbrojavanje.onNext(378) // ****
        /*
         Trenutna vrednost je next(488)
         Trenutna vrednost je next(428)
         Trenutna vrednost je next(378)
         Trenutna vrednost je completed // ****
         */
        
        // MARK: - Start With pocinje sa poslednjim eventom pre potipsivanja
        let startWithDisoposal = Observable.of("1", "2", "3")
            .startWith("A")
            .startWith("B")
            .startWith("C", "D")
            .subscribe({ print($0) })
        disposableBag.insert(startWithDisoposal)
        /*
         C
         D
         B
         A
         1
         2
         3
         */
        
        // MARK: - Merge sjedinjuje dva i vise izvora istog tipa da rade kao jedan
        let subject1 = PublishSubject<String>()
        let subject2 = PublishSubject<String>()
        
        let mergedDisposal = Observable.of(subject1, subject2)
            .merge()
            .subscribe { print($0) }
        
        disposableBag.insert(startWithDisoposal)
        
        subject1.onNext("A")
        subject1.onNext("B")
        
        subject2.onNext("1")
        subject2.onNext("2")
        
        subject1.onNext("C")
        subject2.onNext("3")
        
        /*
         A
         B
         1
         2
         C
         3
         */
        
        // MARK: - ZIP sjedinjuje od dva do osam izvora da rade kao jedan, ali svi izovri moraju emitovati nesto da bi ovo zip krenuo u igru
        let stringSubject = PublishSubject<String>()
        let intSubject = PublishSubject<Int>()
        
        let zipDisposal = Observable
            .zip(stringSubject, intSubject) { stringElement, intElement in
                "\(stringElement) \(intElement)"
            }
            .subscribe { print($0) }
        disposableBag.insert(zipDisposal)
        
        stringSubject.onNext("A")
        stringSubject.onNext("B")
        
        intSubject.onNext(1)
        intSubject.onNext(2)
        
        intSubject.onNext(3)
        stringSubject.onNext("C")
        /*
         A
         B
         1
         2
         3
         C
         */
        
        // SIDE EFFECTS se izovde primenom doOnNext
        let fahrenheitTemps = Observable.from([-40, 0, 32, 70, 212])
        
        let sideEffectsDisposal = fahrenheitTemps
            .do(onNext: {
                $0 * $0
            })
            .do(onNext: {
                print("\($0)℉ = ", terminator: "")
            })
            .map {
                Double($0 - 32) * 5/9.0
            }
            .subscribe({
                print(String(format: "%.1f℃", $0 as! CVarArg))
            })
        disposableBag.insert(sideEffectsDisposal)
        
        // Scheduleri za concurrency se koriste, prate GCD ili NSOperation
        let imageView = UIImageView()
        let image = UIImage(named: "SparrowLogo")!
        let imageData = UIImagePNGRepresentation(image)!
        
        let imageSubject = PublishSubject<Data>()
        let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)
        
        let imageDisposable = imageSubject
            .observeOn(scheduler)
            .map { (data) -> UIImage in
                UIImage(data: data)!
            }
            .observeOn(MainScheduler.instance)
            .subscribe { (imageEvent) in
                imageView.image = imageEvent.element
        }
        disposableBag.insert(imageDisposable)
        
        imageSubject.onNext(imageData)
        
        disposalBag.disposed(by: disposableBag)
        
    }
}




