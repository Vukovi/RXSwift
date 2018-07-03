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
import Photos
import RxSwift

class PhotosViewController: UICollectionViewController {
    
    // da ne koristim RxSwift morao bih da delegate pattern-om prosledim informaciju MainVC-u
    // koju sliku sam odabrao, umesto toga postavljam PublishSubject, koji ce biti private
    // jer ne zelim da druge klase mogu pozivom onNext() da emituju vrednosti odavde
    fileprivate let selectedPhotosSubject = PublishSubject<UIImage>()
    // dakle selectedPhotosSubject emituje vrednostu, a selectedPhotos emituje ovaj dogadjaj npr drugom kontroleru i upravo ce se MainVC potpisati na selectedPhotos observer
    var selectedPhotos: Observable<UIImage> {
        return selectedPhotosSubject.asObservable()
    }
    
    let bag = DisposeBag()
    
    private lazy var photos = PhotosViewController.loadPhotos()
    private lazy var imageManager = PHCachingImageManager()
    
    private lazy var thumbnailSize: CGSize = {
        let cellSize = (self.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
        return CGSize(width: cellSize.width * UIScreen.main.scale,
                      height: cellSize.height * UIScreen.main.scale)
    }()
    
    static func loadPhotos() -> PHFetchResult<PHAsset> {
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        return PHAsset.fetchAssets(with: allPhotosOptions)
    }
    
    // MARK: View Controller
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ovo dodajem da bi svaki put pitao za dozvolu kad ulazim u fotografije
        let authorized = PHPhotoLibrary.authorized.share()
        
        authorized
            .skipWhile { $0 == false } // ako se ne dozvoli ulazak u Photos, preskace
            .take(1) // ovim uzima samo prvi element iz observera, iako je to u ovom slucaju uvek true, ovim je naglasena namera da samo sa prvim true-om hocu da radim
            .subscribe { [weak self] in
                self?.photos = PhotosViewController.loadPhotos()
                // zasto GCD, jer u PHPhotoLibrary+Rx, kad promenim status na "dozvoljen pristup"
                // requestAuthorization({ (newStatus) in ... }) ovaj deo tog koda ne garantuje
                // na kom threadu ce se njegov klozer izvrsiti, tako da ako nisam gurnuo collectionView?.reloadData()
                // na main thread onda puca aplikacija
                DispatchQueue.main.async {
                    self?.collectionView?.reloadData()
                }
            }.disposed(by: bag)
        
        authorized
            // ova tri filtera deluju prenatrpano, jer observer koji daej dozvolu za ulazak u fotografije
            // ima sequencu od dva emitovanja, true i false, ne znamo kojim redom
            // pa ako se preskoci prvi, a zatim uzme  jedan poslednji dogadjaj, a zatim proveri da li je on true
            // sve deluje prenatrpano, li zbog mogucih promena u iOS, UIKit-u, ovim prenatrpanim kodom
            // se postize preciznost onoga sto nam treba, tj da izbaci poruku kad nije dozvoljen pristup
            .skip(1)
            .takeLast(1)
            .filter { $0 == false }
            .subscribe { [weak self] in
                guard let errorMessage = self?.errorMessage else { return }
                DispatchQueue.main.async(execute: errorMessage)
            }.disposed(by: bag)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        selectedPhotosSubject.onCompleted() // nije neophodno, ali pomaze sa automatskim disposal-om, jer govori svim observerima da je potpisivanje gotovo
    }
    
    private func errorMessage() {
        alert(title: "NIJE DOZVOLJEN PRISTUP FOTOGRAFIJAMA", text: "Dozvoli pristup iz Settings-a aplikacije")
            .take(5.0, scheduler: MainScheduler.instance) // ovim ce alert postojati tokom 5 sekundi
            .subscribe {
                self.dismiss(animated: true, completion: nil)
                _ = self.navigationController?.popViewController(animated: true)
            }.disposed(by: bag)
    }
    
    // MARK: UICollectionView
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let asset = photos.object(at: indexPath.item)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PhotoCell
        
        cell.representedAssetIdentifier = asset.localIdentifier
        imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
            if cell.representedAssetIdentifier == asset.localIdentifier {
                cell.imageView.image = image
            }
        })
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = photos.object(at: indexPath.item)
        
        if let cell = collectionView.cellForItem(at: indexPath) as? PhotoCell {
            cell.flash()
        }
        
        imageManager.requestImage(for: asset, targetSize: view.frame.size, contentMode: .aspectFill, options: nil, resultHandler: { [weak self] image, info in
            
            guard let image = image, let info = info else { return }
            
            if let isThumbnail = info[PHImageResultIsDegradedKey as NSString] as? Bool, !isThumbnail {
                self?.selectedPhotosSubject.onNext(image) // evo emitovanja
            }
            
        })
    }
}
