import UIKit
import RxSwift
import RxCocoa



// Support code -- DO NOT REMOVE
class TimelineView<E>: TimelineViewBase, ObserverType where E: CustomStringConvertible {
  static func make() -> TimelineView<E> {
    return TimelineView(width: 400, height: 100)
  }
  public func on(_ event: Event<E>) {
    switch event {
    case .next(let value):
      add(.Next(String(describing: value)))
    case .completed:
      add(.Completed())
    case .error(_):
      add(.Error())
    }
  }
}


// Buffering operators

// 1. replay(), replayAll()  -  kada sekvenca emituje neki dogadjaj, buduci subscriber treba da primi neki deo dogadjaja ili ceo dogadjaj

let elementsPerSecond = 1
let maxElements = 5
let replayedElements = 1
let replayDelay: TimeInterval = 3

// ovaj observable emituje koliko god moze elemenata i nema kraja (nema completed)
//let sourceObservable = Observable<Int>.create { (observer) -> Disposable in
//    var value = 1
//    let timer = DispatchSource.timer(interval: 1.0/Double(elementsPerSecond), queue: .main, handler: {
//        if value <= maxElements {
//            observer.onNext(value)
//            value = value + 1
//        }
//    })
//    return Disposables.create {
//        timer.suspend()
//    }
//}.replay(replayedElements)
let sourceObservable = Observable<Int>.interval(RxTimeInterval(exactly: 1.0 / Double(elementsPerSecond)), scheduler: MainScheduler.instance).replay(replayedElements)

// da bi se zamislio kako izgleda REPLAY() napravicu nekoliko TimeLineView-eva
let sourceTimeline = TimelineView<Int>.make()
let replayedTimeline = TimelineView<Int>.make()

// napravio nekoliko vertikalnih stack view-eva
let stack = UIStackView.makeVertical([UILabel.makeTitle("replay"), UILabel.make("Emit \(elementsPerSecond) per second"), sourceTimeline, UILabel.make("Replay \(replayedElements) after \(replayDelay) sec:"), replayedTimeline])

// ovo je instant subscriber koji ce prikazati sta dobija od gornjeg timeline-a
_ = sourceObservable.subscribe(sourceTimeline)

// sad hocu da ponovim potpisivanje, sa sledecim odlaganjem
DispatchQueue.main.asyncAfter(deadline: .now() + replayDelay) {
    _ = sourceObservable.subscribe(replayedTimeline)
//    _ = sourceObservable.connect()
}
_ = sourceObservable.connect()

// .connect() je neophodno jer pomocu njega subsciberi dobijaju evente
// on se koristi kod replay(), replayAll(), multicast(), publish()

// sad podesavam host view jer ce se u njemu prikazati stack view
let hostView = setupHostView()
hostView.addSubview(stack)
hostView

// X---1-2-3-4-5----> emitovani elementi, element po sekundi
// X---------3-5----> replay 1 posle 3 sekunde
//           4





