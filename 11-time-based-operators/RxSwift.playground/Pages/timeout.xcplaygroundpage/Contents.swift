//: Please build the scheme 'RxSwiftPlayground' first
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

let button = UIButton(type: .system)
button.setTitle("Press me now!", for: .normal)
button.sizeToFit()


let tapsTimeline = TimelineView<String>.make()

let stack = UIStackView.makeVertical([
        button,
        UILabel.make("Taps button above"),
        tapsTimeline
    ])

// setup observable and connect it to timaline view
let _ = button
            .rx.tap
    .map { "." }
//    .timeout(5, scheduler: MainScheduler.instance)
    .timeout(5, other: Observable.just("X"), scheduler: MainScheduler.instance)
    .subscribe(tapsTimeline)

let hostView = setupHostView()
hostView.addSubview(stack)
hostView



