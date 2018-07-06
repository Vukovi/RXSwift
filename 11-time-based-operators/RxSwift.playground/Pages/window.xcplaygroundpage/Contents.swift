//: Please build the scheme 'RxSwiftPlayground' first
import UIKit
import RxSwift
import RxCocoa



// Support code -- DO NOT REMOVE
class TimelineView<E>: TimelineViewBase, ObserverType where E: CustomStringConvertible {
  static func make() -> TimelineView<E> {
    let view = TimelineView(frame: CGRect(x: 0, y: 0, width: 400, height: 100))
    view.setup()
    return view
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

// 3. window() - kontrolisani buffering, radi veoma slicno kao buffer(), samo sto za razliku od njega emituje Observable bufferovanih elemenata umesto emitovanja niza

let elementsperSecond = 3
let windowTimeSpan: RxTimeInterval = 4
let windowMaxCount = 10
let sourceObservable = PublishSubject<String>()

let sourceTimeline = TimelineView<String>.make()
let stack = UIStackView.makeVertical([
        UILabel.makeTitle("Window"),
        UILabel.make("Emitted elements \(elementsperSecond) per sec:"),
        sourceTimeline,
        UILabel.make("Windowed observables at most \(windowMaxCount) every \(windowTimeSpan) sec:")
    ])

let timer = DispatchSource.timer(interval: 1.0 / Double(elementsperSecond), queue: .main) {
    sourceObservable.onNext("$$")
}

_ = sourceObservable.subscribe(sourceTimeline)

_ = sourceObservable.window(timeSpan: windowTimeSpan, count: windowMaxCount, scheduler: MainScheduler.instance).flatMap({ (windowedObservable) -> Observable<(TimelineView<Int>,String?)> in
    let timeline = TimelineView<Int>.make()
    stack.insert(timeline, at: 4)
    stack.keep(atMost: 8)
    return windowedObservable
        .map({ value in (timeline, value) })
        .concat(Observable.just(timeline, nil))
}).subscribe(onNext: { (tuple) in
    let (timeline, value) = tuple
    if let value = value {
        timeline.add(.Next(value))
    } else {
        timeline.add(.Completed(true))
    }
})

// svaki put kada flatMap dobije novi Observable, ubacuje se novi timeline view
// onda se mapira observable elemenata kao observable tapla, ovo treba zbog prenosenja obe vrednosti i vremena kada ih prikazati
// kad se ovi unutrasnji observables elemenata zavrsi, obavim konkatenaciju u jedan tuple

let hostView = setupHostView()
hostView.addSubview(stack)
hostView

// X---|---|---|---|---|---|---|---$$ ovo su emitovani elementi na tri sekunde
// windowed observables - najvise 10 na svakih 4 sekunde
//                             |---$$
//                 |---|---|---|---$$
//                                 C
//  X|---|---|---|---$$
//                    C
//  X|---|---$$

