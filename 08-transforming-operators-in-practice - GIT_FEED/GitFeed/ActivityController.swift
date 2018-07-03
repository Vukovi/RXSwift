/*
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import RxSwift
import RxCocoa
import Kingfisher

class ActivityController: UITableViewController {
    
    let repo = "ReactiveX/RxSwift"
    
    fileprivate let events = Variable<[Event]>([])
    fileprivate let bag = DisposeBag()
    fileprivate let lastModified = Variable<NSString?>(nil)
    
    private var eventsFileURL: URL {
        return cashedFileURL("events.plist")
    }
    
    private var modifiedFileURL: URL {
        return cashedFileURL("modified.txt")
    }
    // ovo ce da bude tekstualni fajl, jer ce se cuvati samo string
    // server salje ovaj response zajedno sa ostalima u JSON-u
    // zato cu ovo iskoristiti da u istom obliku saljem header nazad serveru
    // na ovaj nacin server vidi koje sam evente zadnje pokupio i ima li novih od tada
    // ovako se stedi network saobracaj i sam procesor
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = repo
        
        self.refreshControl = UIRefreshControl()
        let refreshControl = self.refreshControl!
        
        refreshControl.backgroundColor = UIColor(white: 0.98, alpha: 1.0)
        refreshControl.tintColor = UIColor.darkGray
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        let eventsArray = (NSArray(contentsOf: eventsFileURL) as? [[String:Any]]) ?? []
        events.value = eventsArray.flatMap(Event.init)
        
        lastModified.value = try? NSString(contentsOf: modifiedFileURL, usedEncoding: nil)
        
        refresh()
    }
    
    func refresh() {
        DispatchQueue.global(qos: .background).async {
//            self.fetchEvents(repo: self.repo) // ovo nije bas tako sigurna varijanta zato cemo ovako
            [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.fetchEvents(repo: strongSelf.repo)
        }
        
    }
    
    func cashedFileURL(_ fileName: String) -> URL {
        return FileManager.default
            .urls(for: .cachesDirectory, in: .allDomainsMask)
            .first!
            .appendingPathComponent(fileName)
    }
    
    func fetchEvents(repo: String) {
        let response = Observable.from([repo])
            .map { (urlString) -> URL in // Response type ovog klozera je promenjen sa R na URL
                return URL(string: "https://api.github.com/repos/\(urlString)/events")!
            }
//            .map { (url) -> URLRequest in // Response type ovog klozera je promenjen sa R na URLRequest
//                return URLRequest(url: url)
//            }  zamenjeno
            .map({ [weak self] url -> URLRequest in
                // ako lastModified sadrzi vrednost, bez obzira da li je iz fajla ili iz jsona,
                // dodaj tu vrednost kao last-modified header requesta
                // ovim se govori serveru da nisam zainteresovan za bilo kakve evente starije od ovog header datuma
                var request = URLRequest(url: url)
                if let modifiedHeader = self?.lastModified.value {
                    request.addValue(modifiedHeader as String, forHTTPHeaderField: "Last-Modified")
                }
                return request
            })
            .flatMap { (request) -> Observable<(HTTPURLResponse, Data)> in // Response type ovog klozera je ObservableConvertibleType i promenjen je u Observable<(HTTPURLResponse, Data)>
                // FLATMAP OBAVLJA POSAO ASINHRONOG NETWORK POZIVA
                // pomocu njega to se cini bez protokola i delegata
                // omogucava naizgled linearni ali ipak asinhroni kod
                print("Is it main thread: \(Thread.isMainThread)")
                return URLSession.shared.rx.response(request: request) // ovde se prebacuje na background thread
            }
            .shareReplay(1) // vezuje se za poslednji emitovan event, i upotrebljava se zbog eliminsanja visetrukih potpisivanja
        
        response
            .filter { (response, _) -> Bool in
                return 200..<300 ~= response.statusCode // ovaj ~= proverava da li se u levoj strani sadrzi desna strana
            }
            .map { (_, data) -> [[String: Any]] in
                guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []), let result = jsonObject as? [[String: Any]] else {
                    return []
                }
                return result // ovim vracam samo podatke iz responsa ili prazan niz
            }
            .filter { (objects) -> Bool in
                print("Is it main thread: \(Thread.isMainThread)")
                return objects.count > 0 // ovim uklanjam error response-ove
            }
            .map { (objects) in // ovaj RX map se ponasa asinhrono na svakom emitovanom elementu
                return objects.flatMap(Event.init) // ovaj flatmap ce ukloniti sve nilove
            }
            .subscribe(onNext: { (newEvent) in
                self.processEvents(newEvent)
            }).disposed(by: bag)
        
        
        response
            .filter { response, _ in
                return 200..<400 ~= response.statusCode
            }
            .flatMap { response, _ -> Observable<NSString> in
                // ovim sam proveri da li response sadrzi HTTP header sa imenom "Last-Modified",
                // ako nema ne salji nikakve evente, ako ima, salji te vrednosti
                guard let value = response.allHeaderFields["Last-Modified"] as? NSString else {
                    return Observable.never()
                }
                return Observable.just(value)
            }
            .subscribe(onNext: { [weak self] modifiedHeader in // ovde se update-uje lastModified i cuva se ta nova vrednost
                guard let strongSelf = self else { return }
                strongSelf.lastModified.value = modifiedHeader
                try? modifiedHeader.write(to: strongSelf.modifiedFileURL, atomically: true, encoding: String.Encoding.utf8.rawValue)
            })
            .disposed(by: bag)

    }
    
    func processEvents(_ newEvents: [Event]) {
        var updatedEvents = newEvents + events.value
        if updatedEvents.count > 50 {
            updatedEvents = Array<Event>(updatedEvents.prefix(upTo: 50))
        }
        events.value = updatedEvents
        
        print("Is it main thread: \(Thread.isMainThread)")
        
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData() // reloadData() mora da se pozove na glavnom thread-u
            self?.refreshControl?.endRefreshing() // kao i sve sto je u viewDidLoad-u bilo kreirano
        }
        
        let eventsArray = updatedEvents.map { $0.dictionary } as NSArray
        eventsArray.write(to: eventsFileURL, atomically: true) // ovo je samo native metoda NSArray-a da se sadrzaj cuva direktno u fajlu
    }
    
    // MARK: - Table Data Source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.value.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event = events.value[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.textLabel?.text = event.name
        cell.detailTextLabel?.text = event.repo + ", " + event.action.replacingOccurrences(of: "Event", with: "").lowercased()
        cell.imageView?.kf.setImage(with: event.imageUrl, placeholder: UIImage(named: "blank-avatar"))
        return cell
    }
}
