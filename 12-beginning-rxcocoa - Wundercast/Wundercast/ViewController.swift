import UIKit
import RxSwift
import RxCocoa
import MapKit
import CoreLocation

class ViewController: UIViewController {
    
    // TRAITS - specijalni RxCocoa-ini observable-i koji su namenjeni boljem radu sa Cocoa-om
    // UNITS - RxCocoa-ina implementacija observable-a koji se koriste sa UI-jem
    // U ovoj aplikaciji se nije koristio UNOWNED ili WEAK ni u jednom closure-u, zato sto ima samo jedan VC koji je stalno prikazan i onda ne mora da se vodi racuna o retain cycle-ovima ili memory leak-ovima, tako da
    // 1# ne korisitmo nista kod Singletona ili kod VC koji se nikad ne sklanjaju
    // 2# unowned - unutar VC-ova koji se otpustaju tek posto je blok clouser-a zavrsen
    // 3# weak - u svim drugim slucajevima
    
    @IBOutlet weak var searchCityName: UITextField!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var cityNameLabel: UILabel!
    //Challenge
    @IBOutlet weak var tempSwitch: UISwitch!
    //
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapButton: UIButton!
    @IBOutlet weak var geoLocationButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let bag = DisposeBag()
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        style()
        
        // Listener trenutnog vremena ApiControllera, setovan sa bzvz podacima
//        ApiController.shared.currentWeather(city: "RxCity")
//            .observeOn(MainScheduler.instance)
//            .subscribe { (data) in
//                if let element = data.element {
//                    self.tempLabel.text = "\(element.temperature) C"
//                    self.iconLabel.text = element.icon
//                    self.humidityLabel.text = "\(element.humidity)"
//                    self.cityNameLabel.text = element.cityName
//                }
//            }
//            .disposed(by: bag)
        
        //MARK: - Part 1
        // Povezivanje text fielda sa ApiController-om
        
        //    searchCityName.rx.text
        //      .filter { ($0 ?? "").characters.count > 0 }
        //      .flatMapLatest { text in
        //        return ApiController.shared.currentWeather(city: text ?? "Error")
        //          .catchErrorJustReturn(ApiController.Weather.empty)
        //      }
        //      .observeOn(MainScheduler.instance)
        //      .subscribe(onNext: { data in
        //        self.tempLabel.text = "\(data.temperature)° C"
        //        self.iconLabel.text = data.icon
        //        self.humidityLabel.text = "\(data.humidity)%"
        //        self.cityNameLabel.text = data.cityName
        //      }).disposed(by:bag)
        
        //MARK: - Part 2
        // Subscribe je zakomentarisan zato sto  umesto pojedinacnog observable-a u smislu podataka
        // dobijam visestruko iskoristljiv observable, a ovo je narocito pogodno za MVVM
        
        //    let search = searchCityName.rx.text
        //      .filter { ($0 ?? "").characters.count > 0 }
        //      .flatMapLatest { text in
        //        return ApiController.shared.currentWeather(city: text ?? "Error")
        //          .catchErrorJustReturn(ApiController.Weather.empty)
        //      }
        //      .shareReplay(1)
        //      .observeOn(MainScheduler.instance)
        //
        //
        //    search.map { "\($0.temperature)° C" }
        //      .bind(to: tempLabel.rx.text)
        //      .disposed(by:bag)
        //
        //    search.map { $0.icon }
        //      .bind(to: iconLabel.rx.text)
        //      .disposed(by:bag)
        //
        //    search.map { "\($0.humidity)%" }
        //      .bind(to: humidityLabel.rx.text)
        //      .disposed(by:bag)
        //
        //    search.map { $0.cityName }
        //      .bind(to: cityNameLabel.rx.text)
        //      .disposed(by:bag)
        
        
        //MARK: - Part 3
        // shareReplay(1) i observeOn(MainScheduler.instance) su zamenjeni DRIVER-OM
        // DRIVER se po defaultu pbavlja na Main threadu
        
        //    let search = searchCityName.rx.text
        //      .filter { ($0 ?? "").characters.count > 0 }
        //      .flatMap { text in
        //        return ApiController.shared.currentWeather(city: text ?? "Error")
        //          .catchErrorJustReturn(ApiController.Weather.empty)
        //      }.asDriver(onErrorJustReturn: ApiController.Weather.empty)
        //
        //    search.map { "\($0.temperature)° C" }
        //      .drive(tempLabel.rx.text)
        //      .disposed(by:bag)
        //
        //    search.map { $0.icon }
        //      .drive(iconLabel.rx.text)
        //      .disposed(by:bag)
        //
        //    search.map { "\($0.humidity)%" }
        //      .drive(humidityLabel.rx.text)
        //      .disposed(by:bag)
        //
        //    search.map { $0.cityName }
        //      .drive(cityNameLabel.rx.text)
        //      .disposed(by:bag)
        
        //MARK: - Part 4
        // umesto direktnog pristupa textField-u, koristice se drugaciji, koji ce smanjiti broj poziva ka API-ju
        // dakle umesto searchCityName.rx.text, koristi se searchCityName.rx.controlEvent(.editingDidEndOnExit).asObservable()
        
        //        let textSearch = searchCityName.rx.controlEvent(.editingDidEndOnExit).asObservable()
        //        let temperature = tempSwitch.rx.controlEvent(.valueChanged).asObservable()
        //
        //        let search = Observable.from([textSearch, temperature])
        //            .merge()
        //            .map { self.searchCityName.text }
        //            .filter { ($0 ?? "").characters.count > 0 }
        //            .flatMap { text in
        //                return ApiController.shared.currentWeather(city: text ?? "Error")
        //                    .catchErrorJustReturn(ApiController.Weather.empty)
        //            }.asDriver(onErrorJustReturn: ApiController.Weather.empty)
        //
        //        search.map { w in
        //            if self.tempSwitch.isOn {
        //                return "\(Int(Double(w.temperature) * 1.8 + 32))° F"
        //            }
        //            return "\(w.temperature)° C"
        //            }
        //            .drive(tempLabel.rx.text)
        //            .disposed(by:bag)
        //
        //        search.map { $0.icon }
        //            .drive(iconLabel.rx.text)
        //            .disposed(by:bag)
        //
        //        search.map { "\($0.humidity)%" }
        //            .drive(humidityLabel.rx.text)
        //            .disposed(by:bag)
        //
        //        search.map { $0.cityName }
        //            .drive(cityNameLabel.rx.text)
        //            .disposed(by:bag)
        
        //MARK: - Part 5
        // jos jedna kombinacija da bi se dobio multi observable
        let searchInput = searchCityName.rx
            .controlEvent(UIControlEvents.editingDidEndOnExit)
            .asObservable()
            .map { self.searchCityName.text }
            .filter { ($0 ?? "").characters.count > 0 }
        
        let temperatureSwitch = tempSwitch.rx
            .controlEvent(.valueChanged)
            .asObservable()
            .map { _ in true }
            .map { self.searchCityName.text }
            .filter { ($0 ?? "").characters.count > 0 }
            .flatMap { text in
                return ApiController.shared
                    .currentWeather(city: text ?? "Error")
                    .catchErrorJustReturn(ApiController.Weather.empty)
            }
            .asDriver(onErrorJustReturn: ApiController.Weather.empty)
        
        let textSearch = searchInput.flatMap { text in
            return ApiController.shared.currentWeather(city: text ?? "Error")
                .catchErrorJustReturn(ApiController.Weather.dummy)
        }
        
        let mapInput = mapView.rx.regionDidChangeAnimated
            .skip(1)
            .map { _ in self.mapView.centerCoordinate }
        
        let mapSearch = mapInput.flatMap { coordinate in
            return ApiController.shared.currentWeather(lat: coordinate.latitude, lon: coordinate.longitude)
                .catchErrorJustReturn(ApiController.Weather.dummy)
        }
        
        let currentLocation = locationManager.rx.didUpdateLocations
            .map { locations in
                return locations[0]
            }
            .filter { location in
                return location.horizontalAccuracy < kCLLocationAccuracyHundredMeters
        }
        
        let geoInput = geoLocationButton.rx.tap.asObservable()
            .do(onNext: {
                self.locationManager.requestWhenInUseAuthorization()
                self.locationManager.startUpdatingLocation()
            })
        
        let geoLocation = geoInput.flatMap {
            return currentLocation.take(1)
        }
        
        let geoSearch = geoLocation.flatMap { location in
            return ApiController.shared.currentWeather(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
                .catchErrorJustReturn(ApiController.Weather.dummy)
        }
        
        let search = Observable.from([geoSearch, textSearch, mapSearch])
            .merge()
            .asDriver(onErrorJustReturn: ApiController.Weather.dummy)
        
        let running = Observable.from([searchInput.map { _ in true },
                                       geoInput.map { _ in true },
                                       mapInput.map { _ in true},
                                       search.map { _ in false }.asObservable()])
            .merge()
            .startWith(true)
            .asDriver(onErrorJustReturn: false)
        
        
        running
            .skip(1)
            .drive(activityIndicator.rx.isAnimating)
            .disposed(by: bag)
        
        running
            .drive(tempLabel.rx.isHidden)
            .disposed(by: bag)
        
        running
            .drive(iconLabel.rx.isHidden)
            .disposed(by:bag)
        
        running
            .drive(humidityLabel.rx.isHidden)
            .disposed(by:bag)
        
        running
            .drive(cityNameLabel.rx.isHidden)
            .disposed(by:bag)
        
        
        
        search.map { "\($0.temperature)° C" }
            .drive(tempLabel.rx.text)
            .disposed(by: bag)
        
        search.map { $0.icon }
            .drive(iconLabel.rx.text)
            .disposed(by: bag)
        
        search.map { "\($0.humidity)%" }
            .drive(humidityLabel.rx.text)
            .disposed(by: bag)
        
        search.map { $0.cityName }
            .drive(cityNameLabel.rx.text)
            .disposed(by: bag)
        
        
        
        geoLocationButton.rx.tap
            .subscribe(onNext: { _ in
                self.locationManager.requestWhenInUseAuthorization()
                self.locationManager.startUpdatingLocation()
            })
            .disposed(by: bag)
        
        locationManager.rx.didUpdateLocations
            .subscribe(onNext: { locations in
                print(locations)
            })
            .disposed(by: bag)
        
        mapButton.rx.tap
            .subscribe(onNext: {
                self.mapView.isHidden = !self.mapView.isHidden
            })
            .disposed(by: bag)

        mapView.rx.setDelegate(self)
            .disposed(by: bag)
        
        search.map { [$0.overlay()] }
            .drive(mapView.rx.overlays)
            .disposed(by: bag)
        
        
        textSearch.asDriver(onErrorJustReturn: ApiController.Weather.dummy)
            .map { $0.coordinate }
            .drive(mapView.rx.location)
            .disposed(by: bag)
        
        mapInput.flatMap { coordinate in
            return ApiController.shared.currentWeatherAround(lat: coordinate.latitude, lon: coordinate.longitude)
                .catchErrorJustReturn([])
            }
            .asDriver(onErrorJustReturn:[])
            .map { $0.map { $0.overlay() } }
            .drive(mapView.rx.overlays)
            .disposed(by: bag)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        Appearance.applyBottomLine(to: searchCityName)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Style
    
    private func style() {
        view.backgroundColor = UIColor.aztec
        searchCityName.textColor = UIColor.ufoGreen
        tempLabel.textColor = UIColor.cream
        humidityLabel.textColor = UIColor.cream
        iconLabel.textColor = UIColor.cream
        cityNameLabel.textColor = UIColor.cream
    }
}


extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? ApiController.Weather.Overlay {
            let overlayView = ApiController.Weather.OverlayView(overlay: overlay, overlayIcon: overlay.icon)
            return overlayView
        }
        return MKOverlayRenderer()
    }
}
