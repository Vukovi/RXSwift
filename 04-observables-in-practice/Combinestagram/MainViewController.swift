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

class MainViewController: UIViewController {
    
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var buttonClear: UIButton!
    @IBOutlet weak var buttonSave: UIButton!
    @IBOutlet weak var itemAdd: UIBarButtonItem!
    
    private let bag = DisposeBag()
    private let images = Variable<[UIImage]>([])
    private var imageCache = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sharedImages = images.asObservable().share()
        
        sharedImages
            // OVO je resenje jednog od cestih PROBLEMA asinhronog programiranja - ako ima mnogo "brzih" dolazecih dogadjaja, uzmi samo poslednji
            // ovde je korisnik kliktao veoma brzo po fotografijama nasumicno, i to je dovelo do kolaza koji korisnik zapravo nije hteo, igrao se sa kliktanjem, tako da ako klikne na razlicite slike ispod o.5 sekundi, i napravi takav niz kliktanja, THROTTLE uzima samo poslednji klik
            .throttle(0.5, scheduler: MainScheduler.instance)
            // potpisao sam se na dogadjaje koje emituje IMAGES, tako da ce pri svakom novom dodavanju slike biti pravljen novi kolaz
            .subscribe { [weak self] photos in
            guard let preview = self?.imagePreview else { return }
            preview.image = UIImage.collage(images: photos.element!, size: preview.frame.size)
        }.disposed(by: bag)
        // Neke situacije za THROTTLE:
        // 1 - pretraga teksta u textFiledu, kojom se salje trenutni tekts serveru, throttleom je dozvoljen brz unos teksta, ono sto se salje je tek po zavrsetku unosa
        // 2 - treba prezentovato novi VC posto se klikne na button, throttle sprecava duplo kliktanje na button, tj visestruko prezentovanje VC-a i reaguje npr smao na poslednji klik
        // 3 - korisnik nesto prevlaci po ekranu, a nas interesuje samo mesto na ekranu gde prst zaustavi
        
        
        
        //opet sam se potpisao da bih dodao logiku ponasanja UI-ja, koja bi da nije RX-a bila pisana znatno drugacije
        sharedImages
            .subscribe { [weak self] photos in
            self?.updateUI(photos: photos.element!)
        }.disposed(by: bag)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("resources: \(RxSwift.Resources.total)")
    }
    
    @IBAction func actionClear() {
        images.value = []
        imageCache = []
    }
    
    @IBAction func actionSave() {
        // ovde koristim moj custom observable
        guard let image = imagePreview.image else {return}
        PhotoWriter.save(image).subscribe(onError: { (error) in
            self.showMessage("Error, \(error.localizedDescription)")
        }) {
            self.showMessage("Saved")
            self.actionClear()
        }.disposed(by: bag)
    }
    
    @IBAction func actionAdd() {
//        images.value.append(UIImage(named: "IMG_1907.jpg")!)
        
        let photosViewController = storyboard?.instantiateViewController(withIdentifier: "PhotosViewController") as! PhotosViewController
        
        let newPhotos = photosViewController.selectedPhotos.share()
        // Share() je objasnjeno u klasi ProblemVisestrukog.....,
        // a time je postignuto, umesto da svaki subscription kreira novi Obesrvable,
        // subscription-i koriste elemente koje im je jedinstveni Obervable pruzio
        
        newPhotos
            .takeWhile({ (newImage) -> Bool in // ovim se ne dozvoljava unosenje vise slika na PhotoVC nego sto je dozvoljeno, odnosno 6
                return self.images.value.count < 6
            })
            .filter({ (newImage) -> Bool in
                return newImage.size.width > newImage.size.height // ovim se eliminisu slike orijentacije portert
            })
            .filter({ (newImage) -> Bool in // ovim ne dozvoljam da se unosi ista slika - na osnovu njene velicine bajtova
                let imageByteLength = UIImagePNGRepresentation(newImage)?.count ?? 0
                guard self.imageCache.contains(imageByteLength) == false else {
                    return false
                }
                self.imageCache.append(imageByteLength)
                return true
            })
            .subscribe(onNext: { (newImage) in
                self.images.value.append(newImage) // OVDE SE SLUSA EMITOVANO SA PHOTOS VIEW CONTROLLERA
            }) {
                print("completed photo selection") // kad sam koristio BAG mainVC-a ovde nije ulazio nikad
            }
            .disposed(by: photosViewController.bag) // OVDE SAM UMESTO BAG-a MAIN VC-a korisito BAG PHOTOS VC-a ZATO STO SE MAIN VC NIKAD NE OTPUSTA - on je kao neki kontejner, navigacioni kontroler u ovoj aplikaciji - A POSTO SE NIKAD NE OTPUSTA NJEGOVOM BAG-u SE SAMO DODAJU POTPISIVANJA NA EVENTE I NJEGOV BAG SE NIKAD NE PRAZNI
        
        newPhotos
            .ignoreElements() // da sam stavio ignoreElements u gornji subscription ne bih dobijao slike u glavnom Kolazu, a ovde mi je potrebno da se to ponasanje ignorise i da se samo kaze kada je onCompleted da bi se azurirala navigaciona ikonica u levom uglu
            .subscribe {
                self.updateNavigationIcon()
            }
            .disposed(by: photosViewController.bag)
        
        navigationController?.pushViewController(photosViewController, animated: true)
    }
    
    func showMessage(_ title: String, description: String? = nil) {
//        let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "Close", style: .default, handler: { [weak self] _ in self?.dismiss(animated: true, completion: nil)}))
//        present(alert, animated: true, completion: nil)
        
        // Challenge
        alert(title: title, text: description).subscribe().disposed(by: bag)
    }
    
    private func updateUI(photos: [UIImage]) {
        buttonSave.isEnabled = photos.count > 0 && photos.count % 2 == 0
        buttonClear.isEnabled = photos.count > 0
        itemAdd.isEnabled = photos.count < 6
        title = photos.count > 0 ? "\(photos.count)" : "Collage"
    }
    
    private func updateNavigationIcon() {
        let icon = imagePreview.image?.scaled(CGSize(width: 22, height: 22)).withRenderingMode(.alwaysOriginal)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: icon, style: .done, target: nil, action: nil)
    }
}
