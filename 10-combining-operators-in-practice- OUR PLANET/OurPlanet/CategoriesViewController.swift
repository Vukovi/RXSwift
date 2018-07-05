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

class CategoriesViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    // Potpisivanje na Variablu, okinuce azuriranje tabele svaki put kad novi podaci stignu
    let categories = Variable<[EOCategory]>([])
    let disposeBag = DisposeBag()
    
    // Challenge 1
    var activityIndicator = UIActivityIndicatorView()
    //
    
    // Challenge 2
    var downloadView = DownloadView()
    //
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Challenge 1
        activityIndicator.color = .black
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        activityIndicator.startAnimating()
        //
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(TVCell.self, forCellReuseIdentifier: TVCell.identifier())
        
        
        categories // ovde sam potpisao tabelu na categories, tako da slusa njene promen i reloaduje se
            .asObservable()
            .subscribe { [weak self] in
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }
            .disposed(by: disposeBag)
        
        startDownload()
    }
    
    func startDownload() {
        
        // Challenge 2
        downloadView.progress.progress = 0.0
        downloadView.label.text = "Download: 0%"
        //
        
        let eoCategories = EONET.categories
        
        // uzmi sve kategorije, flatMap ih pretvara u observable koji emituje jedan observable evenata iz svake kategorije, i na kraju sve mergujem u jedan stream nizova eventa
        let downloadedEvents = eoCategories.flatMap { categories in
            return Observable.from(categories.map({ category in
                EONET.events(forLast: 360, category: category)
            }))
        }.merge(maxConcurrent: 2) // ovim se ogranicava broj poziva koji se salje serveru, da se ne bi zagusio
        
        let updatedCategories = eoCategories.flatMap { categories in
            downloadedEvents.scan((0,categories)) { tuple, events in // Challenge 2
                return (tuple.0 + 1, tuple.1.map { category in // Challenge 2
                    let eventsForCategory = EONET.filteredEvents(events: events, forCategory: category)
                    if !eventsForCategory.isEmpty {
                        var cat = category
                        cat.events = cat.events + eventsForCategory
                        return cat
                    }
                    return category
                })
            }
        }
//        let updatedCategories = eoCategories.flatMap { categories in
//            downloadedEvents.scan(categories, accumulator: { updated, events in
//                return updated.map({ category in
//                    let eventsForCategory = EONET.filteredEvents(events: events, forCategory: category)
//                    if !eventsForCategory.isEmpty {
//                        var cat = category
//                        cat.events = cat.events + eventsForCategory
//                        return cat
//                    }
//                    return category
//                })
//            })
//            }

            // Challenge 2
            .do(onNext: { [weak self] tuple in
                DispatchQueue.main.async {
                    let progress = Float(tuple.0) / Float(tuple.1.count)
                    self?.downloadView.progress.progress = progress
                    let percent = Int(progress * 100.0)
                    self?.downloadView.label.text = "Download: \(percent)"
                }
            })
            // Challenge 1
            .do(onCompleted: { [weak self] in
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                    self?.downloadView.isHidden = true
                }
            }) //
        
        eoCategories
        //  .concat(updatedCategories) // korisniku se prikazuju objedinjano open i close eventi
            .concat(updatedCategories.map({ $0.1 })) // Challenge 2
            .bind(to: categories) // categories postaju listener na EONET.categories
            .disposed(by: disposeBag)
    }
    
    
    
    
}


extension CategoriesViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // zbog koriscenja Variable, bezbedni smo iako podaci stignu sa background thread-a
        return categories.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell")!
        let cell: TVCell = tableView.dequeueReusableCell(withIdentifier: TVCell.identifier()) as! TVCell
        let category = categories.value[indexPath.row]
        cell.textLabel?.text = "\(category.name) \(category.events.count)"
        cell.detailTextLabel?.text = category.description
        cell.accessoryType = (category.events.count > 0) ? .disclosureIndicator : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let category = categories.value[indexPath.row]
        if !category.events.isEmpty {
            let eventsController = storyboard!.instantiateViewController(withIdentifier: "events") as! EventsViewController
            eventsController.title = category.name
            eventsController.events.value = category.events
            navigationController!.pushViewController(eventsController, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
