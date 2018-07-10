import Foundation
import RxSwift

print("\n\n\n===== Schedulers =====\n")

let globalScheduler = ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global())
let bag = DisposeBag()
let animal = BehaviorSubject(value: "[dog]")


//animal
//  .dump()
//    // 00s | [D] [dog] received on Main Thread
//  .dumpingSubscription()
//    // 00s | [S] [dog] received on Main Thread
//  .disposed(by: bag)

let fruit = Observable<String>.create { observer in
    observer.onNext("[apple]")
    sleep(2)
    observer.onNext("[pineapple]")
    sleep(2)
    observer.onNext("[strawberry]")
    return Disposables.create()
}

//fruit
//    .dump()
//    // 00s | [D] [apple] received on Main Thread
//    // 02s | [D] [pineapple] received on Main Thread
//    // 04s | [D] [strawberry] received on Main Thread
//    .dumpingSubscription()
//    // 00s | [S] [apple] received on Main Thread
//    // 02s | [S] [pineapple] received on Main Thread
//    // 04s | [S] [strawberry] received on Main Thread
//    .disposed(by: bag)

//fruit
//    .subscribeOn(globalScheduler)
//    .dump()
//    // 00s | [D] [apple] received on Anonymous Thread
//    // 02s | [D] [pineapple] received on Anonymous Thread
//    // 04s | [D] [strawberry] received on Anonymous Thread
//    .dumpingSubscription()
//    // 00s | [S] [apple] received on Anonymous Thread
//    // 02s | [S] [pineapple] received on Anonymous Thread
//    // 04s | [S] [strawberry] received on Anonymous Thread
//    .disposed(by: bag)

// ovo je hack, da bi se sprecilo zavrsavanje terminala dodatnih 13 sekundi, jer da nema ovoga, sve sto se zavrsi na main threadu zavrsava i terminla, a to bi ubilo globalScheduler i observable
//RunLoop.main.run(until: Date(timeIntervalSinceNow: 13))

//fruit
//    .subscribeOn(globalScheduler)
//    .dump()
//    // 00s | [D] [apple] received on Anonymous Thread
//    // 02s | [D] [pineapple] received on Anonymous Thread
//    // 04s | [D] [strawberry] received on Anonymous Thread
//    .observeOn(MainScheduler.instance)
//    .dumpingSubscription()
//    // 00s | [S] [apple] received on Main Thread
//    // 02s | [S] [pineapple] received on Main Thread
//    // 04s | [S] [strawberry] received on Main Thread
//    .disposed(by: bag)

//RunLoop.main.run(until: Date(timeIntervalSinceNow: 13))

//let animalsThread = Thread() {
//    sleep(3)
//    animal.onNext("[cat]")
//    sleep(3)
//    animal.onNext("[tiger]")
//    sleep(3)
//    animal.onNext("[fox]")
//    sleep(3)
//    animal.onNext("[leopard]")
//}
//animalsThread.name = "Animals Thread"
//animalsThread.start()

//03s | [D] [cat] received on Animals Thread
//03s | [S] [cat] received on Animals Thread
//04s | [D] [strawberry] received on Anonymous Thread
//04s | [S] [strawberry] received on Main Thread
//06s | [D] [tiger] received on Animals Thread
//06s | [S] [tiger] received on Animals Thread
//09s | [D] [fox] received on Animals Thread
//09s | [S] [fox] received on Animals Thread
//12s | [D] [leopard] received on Animals Thread
//12s | [S] [leopard] received on Animals Thread

//animal
//    .dump()
//    .observeOn(globalScheduler)
//    .dumpingSubscription()
//    .disposed(by:bag)

//03s | [D] [cat] received on Animals Thread
//03s | [S] [cat] received on Anonymous Thread
//04s | [D] [strawberry] received on Anonymous Thread
//04s | [S] [strawberry] received on Main Thread
//06s | [D] [tiger] received on Animals Thread
//06s | [S] [tiger] received on Anonymous Thread
//09s | [D] [fox] received on Animals Thread
//09s | [S] [fox] received on Anonymous Thread
//12s | [D] [leopard] received on Animals Thread
//12s | [S] [leopard] received on Anonymous Thread


/// PITFALL - GRESKA, ako se misli da su SCHEDULERsi ASYNC i MULTITHREADING

//animal
//    .subscribeOn(MainScheduler.instance) // zbog ovoga
//    .dump()
//    .observeOn(globalScheduler)
//    .dumpingSubscription()
//    .disposed(by:bag)

// rezultat isiti kao malopredjasnji
//03s | [D] [cat] received on Animals Thread
//03s | [S] [cat] received on Anonymous Thread
//04s | [D] [strawberry] received on Anonymous Thread
//04s | [S] [strawberry] received on Main Thread
//06s | [D] [tiger] received on Animals Thread
//06s | [S] [tiger] received on Anonymous Thread
//09s | [D] [fox] received on Animals Thread
//09s | [S] [fox] received on Anonymous Thread
//12s | [D] [leopard] received on Animals Thread
//12s | [S] [leopard] received on Anonymous Thread

// Sigurnije je koristiti kao kod FRUITSa Observable<NESTO>.create......
// jer tako Rx upravlja sa onim sto se dogadja unutar bloka i bolje se hendla asnyc i multythreading
// to je poznato i kao HOT&COLD problem
// Fruits su hot observable jer nema side effects koji bi uticali na njih, kao sto su request serveru, editovanje baze, upisivanje fajla u sistem ....

