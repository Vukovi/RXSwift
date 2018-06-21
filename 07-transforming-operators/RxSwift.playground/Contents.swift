import RxSwift
import RxSwiftExt

example(of: "toArray") {
    let disposeBag = DisposeBag()
    Observable.of("A","B","C")
        .toArray()
        .subscribe(onNext: {
            print($0)                       // ["A", "B", "C"]
        }).disposed(by: disposeBag)
}

example(of: "map") {
    let disposeBag = DisposeBag()
    let formatter = NumberFormatter()
    formatter.numberStyle = .spellOut
    
    Observable<NSNumber>.of(123, 4, 56)
        .map({
            formatter.string(from: $0) ?? ""
        })
        .subscribe(onNext: {
            print($0) // one hundred twenty-three     four     fifty-six
        }).disposed(by: disposeBag)
}

example(of: "mapWithIndex") {
    let disposeBag = DisposeBag()
    Observable.of(1,2,3,4,5,6)
        .mapWithIndex({ integer, index in
            index > 2 ? integer * 2 : integer
        })
        .subscribe(onNext: {
            print($0)    // 1  2  3  8  10  12
        }).disposed(by: disposeBag)
}




struct Student {
    var score: Variable<Int>
}

example(of: "flatMap") {
    let disposeBag = DisposeBag()
    
    let ryan = Student(score: Variable(80))
    let charlotte = Student(score: Variable(90))
    
    let student = PublishSubject<Student>()
    student.asObservable()
        .flatMap({
            $0.score.asObservable()
        })
        .subscribe(onNext: {
            print($0)
        }).disposed(by: disposeBag)
    
    student.onNext(ryan) // 80
    ryan.score.value = 85
    // sad se rezultat ryan scora stampa kao 85
    
    student.onNext(charlotte) // 90
    ryan.score.value = 95
    // sad se rezultat ryan scora stampa kao 95
    charlotte.score.value = 100
    // sad se rezultat charlotte scora stampa kao 100
    
    //FLATMAP pamti i projektuje sve promene svakog observable-a
}




example(of: "flatMapLatest") {
    let disposeBag = DisposeBag()
   
    let ryan = Student(score: Variable(80))
    let charlotte = Student(score: Variable(90))
    
    let student = PublishSubject<Student>()
    student.asObservable()
        .flatMapLatest({
            $0.score.asObservable()
        })
        .subscribe(onNext: {
            print($0)
        }).disposed(by: disposeBag)
    
    student.onNext(ryan)
    // 80
    ryan.score.value = 85
    // 85
    student.onNext(charlotte)
    // 90
    ryan.score.value = 95
    // ova promena na ryan-u nece biti stamapana jer je flatMapLatest vec presao na charlotte-u
    charlotte.score.value = 100
    //100
    
    //FLATMAPLATEST se najcesce koristi kod network operacija
}



example(of: "Challenge 1") {
    let disposeBag = DisposeBag()
    
    let contacts = [
        "603-555-1212": "Florent",
        "212-555-1212": "Junior",
        "408-555-1212": "Marin",
        "617-555-1212": "Scott"
    ]
    
    let convert: (String) -> UInt? = { value in
        if let number = UInt(value),
            number < 10 {
            return number
        }
        
        let convert: [String: UInt] = [
            "abc": 2, "def": 3, "ghi": 4,
            "jkl": 5, "mno": 6, "pqrs": 7,
            "tuv": 8, "wxyz": 9
        ]
        
        var converted: UInt? = nil
        
        convert.keys.forEach {
            if $0.contains(value.lowercased()) {
                converted = convert[$0]
            }
        }
        
        return converted
    }
    
    let format: ([UInt]) -> String = {
        var phone = $0.map(String.init).joined()
        
        phone.insert("-", at: phone.index(
            phone.startIndex,
            offsetBy: 3)
        )
        
        phone.insert("-", at: phone.index(
            phone.startIndex,
            offsetBy: 7)
        )
        
        return phone
    }
    
    let dial: (String) -> String = {
        if let contact = contacts[$0] {
            return "Dialing \(contact) (\($0))..."
        } else {
            return "Contact not found"
        }
    }
    
    let input = Variable<String>("")
    
    // Add your code here
//    input
//        .skipWhile { $0 == 0 }
//        .filter { $0 < 10 }
//        .take(10)
//        .toArray()
//        .subscribe(onNext: {
//            let phone = phoneNumber(from: $0)
//            if let contact = contacts[phone] {
//                print("Dialing \(contact) (\(phone))...")
//            } else {
//                print("Contact not found")
//            }
//        })
//        .disposed(by: disposeBag)
    
    //Digresija
    //RxSwiftExt nije deo RxSwift-a i tu se mogu naci neke dodatne helper metode, npr
    // Observable.of(1, 2, nil, 3)
    //      .flatmap { $0 == nil ? Observable.empty() : Observable.just($0!) }
    //      .subscribe(onNext: { print($0) })
    //      .disposed(by: disposeBag)
    //Kod iznad je standardni RxSwift, a RxSwiftExt bi olaksao ovako
    // Observable.of(1, 2, nil, 3)
    //      .unwrap()
    //      .subscribe(onNext: { print($0) })
    //      .disposed(by: disposeBag)
    
    input.asObservable()
        .map(convert) // ovaj je dodat da bi slova pretvarao u brojeve
        .unwrap()  // objasnjen u digresiji
        .skipWhile { $0 == 0 } // vec postoji
        .take(10) // vec postoji
        .toArray() // vec postoji
        .map(format)
        .map(dial)
        .subscribe(onNext: { print($0) })
        .disposed(by: disposeBag)
    
    
    input.value = ""
    input.value = "0"
    input.value = "408"
    
    input.value = "6"
    input.value = ""
    input.value = "0"
    input.value = "3"
    
    "JKL1A1B".characters.forEach {
        input.value = "\($0)"
    }
    
    input.value = "9"
}
