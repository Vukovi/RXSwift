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

// 2. buffer() - kontrolisani buffering

// ovi ce definisati ponasanje buffer operatora
let bufferTimeSpan: RxTimeInterval = 4
let bufferMaxCount = 2

let sourceObservable = PublishSubject<String>()

let sourceTimeline = TimelineView<String>.make()
let bufferedTimeline = TimelineView<String>.make()

let stack = UIStackView.makeVertical([
        UILabel.makeTitle("buffer"),
        UILabel.make("Emitted elements"),
        sourceTimeline,
        UILabel.make("Buffered elements (at most \(bufferMaxCount) every \(bufferedTimeline)"),
        bufferedTimeline
    ])

_ = sourceObservable.subscribe(sourceTimeline)

// hocu da dobijem nizove elemenata od source observable
// svaki niz moze da sadrzi najvise bufferMaxCount elemenata
// ako se dobije toliko elemenata pre nego sto istekne bufferTimeSpan, operator ce emitovati bufferovane elemente i resetovace timer
// prilikom delay-a, tj bufferTimeSpan, posto je emitovana zadnja grupa, buffer ce emitovati niz, ali ako nije primljen ni jedan element tokom ovog intervala, niz ce biti prazan
_ = sourceObservable
    .buffer(timeSpan: bufferTimeSpan, count: bufferMaxCount, scheduler: MainScheduler.instance)
    .map { $0.count }
    .subscribe(bufferedTimeline)

let hostView = setupHostView()
hostView.addSubview(stack)
hostView

DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
    sourceObservable.onNext("$")
    sourceObservable.onNext("$")
    sourceObservable.onNext("$")
}

//        $
// X------$----------------------> emitovani elementi
//        $

// X---0--2------------1--------0 bufferovani elementi (najvise na 2.4 sekunde)

// ovde se dogadja sledece: buffer timeline emituje prazan niz, zatim se pushuju 3 elementa ($) na source observable, buffer timeline odmah dobija dva elementa zato sto toliko najvise sme moze da ih primi, zatim prodju 4 sekunde i onda se emituje niz sa jednim elementom i to je posldenji od 3 $ koji su pushovani na source observable
