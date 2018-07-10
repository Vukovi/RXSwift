import Foundation
import CoreLocation
import RxSwift
import RxCocoa

class RxCLLocationManagerDelegateProxy: DelegateProxy, CLLocationManagerDelegate, DelegateProxyType {
    
    // pomocu sledece dve metode, geter i seter delegata
    // ovako ekstendujem klasu da bi mogla da koristi DELEGATE PROXY PATTERN
    static func setCurrentDelegate(_ delegate: AnyObject?, toObject object: AnyObject) {
        let locationManager: CLLocationManager = object as! CLLocationManager
        locationManager.delegate = delegate as? CLLocationManagerDelegate
    }
    static func currentDelegateFor(_ object: AnyObject) -> AnyObject? {
        let locationManager: CLLocationManager = object as! CLLocationManager
        return locationManager.delegate
    }
    
}

// sad cu napraviti observable, kojima cu posmatrati promenu lokacija pomocu proxy delegata
extension Reactive where Base: CLLocationManager {
    
    var delegate: DelegateProxy {
        return RxCLLocationManagerDelegateProxy.proxyForObject(base)
    }
    
    var didUpdateLocations: Observable<[CLLocation]> {
        return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didUpdateLocations:)))
            .map({ parameters in
                return parameters[1] as! [CLLocation]
            })
    }
    
    
    
}
