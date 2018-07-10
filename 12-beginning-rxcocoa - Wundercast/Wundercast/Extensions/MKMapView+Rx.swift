import Foundation
import MapKit
import RxSwift
import RxCocoa

class RxMKMapViewDelegateProxy: DelegateProxy, MKMapViewDelegate, DelegateProxyType {
    static func currentDelegateFor(_ object: AnyObject) -> AnyObject? {
        let mapView: MKMapView = object as! MKMapView
        return mapView.delegate
    }
    static func setCurrentDelegate(_ delegate: AnyObject?, toObject object: AnyObject) {
        let mapView: MKMapView = object as! MKMapView
        mapView.delegate = delegate as? MKMapViewDelegate
    }
}

extension Reactive where Base: MKMapView {
    public var delegate: DelegateProxy {
        return RxMKMapViewDelegateProxy.proxyForObject(base)
    }
    
    public func setDelegate(_ delegate: MKMapViewDelegate) -> Disposable {
        return RxMKMapViewDelegateProxy.installForwardDelegate(
            delegate,
            retainDelegate: false,
            onProxyForObject: self.base
        )
    }
    
    var overlays: UIBindingObserver<Base, [MKOverlay]> {
        return UIBindingObserver(UIElement: self.base) { mapView, overlays in
            mapView.removeOverlays(mapView.overlays)
            mapView.addOverlays(overlays)
        }
    }
    
    public var regionDidChangeAnimated: ControlEvent<Bool> {
        let source = delegate
            .methodInvoked(#selector(MKMapViewDelegate.mapView(_:regionDidChangeAnimated:)))
            .map { parameters in
                return (parameters[1] as? Bool) ?? false
        }
        return ControlEvent(events: source)
    }
    
    public var location: UIBindingObserver<Base, CLLocationCoordinate2D> {
        return UIBindingObserver(UIElement: self.base) { map, location in
            let span = MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
            map.region = MKCoordinateRegion(center: location, span: span)
        }
    }
}
