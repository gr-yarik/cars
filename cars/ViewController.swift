//
//  ViewController.swift
//  cars
//
//  Created by Yaroslav Hrytsun on 22.09.2020.
//

import UIKit
import CoreData

class ViewController: UIViewController {

    var car: Car!
    var context: NSManagedObjectContext!
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        return dateFormatter
    }()
    
    @IBOutlet weak var carImage: UIImageView!
    @IBOutlet weak var modelLabel: UILabel!
    @IBOutlet weak var makeLabel: UILabel!
    @IBOutlet weak var lastStartedLabel: UILabel!
    @IBOutlet weak var timesDriven: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var myChoice: UIImageView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBAction func ratePressed(_ sender: Any) {
        let rateAlertController = UIAlertController(title: "Set Rating", message: nil, preferredStyle: .alert)
        rateAlertController.addTextField(configurationHandler: nil)
        rateAlertController.textFields?.first?.keyboardType = .decimalPad
        
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            guard let rating = Double(rateAlertController.textFields?.first?.text ?? "") else { return }
            if rating < 0 || rating > 10 {
                self.dismiss(animated: true, completion: nil)
                let errorAlertContoller = UIAlertController(title: "Error", message: "Wrong rating", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                errorAlertContoller.addAction(okAction)
                self.present(errorAlertContoller, animated: true, completion: nil)
            } else { self.car.rating = rating }
            do {
                try self.context.save()
            } catch let error {
                print(error)
            }
            self.presentCar()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        rateAlertController.addAction(okAction)
        rateAlertController.addAction(cancelAction)
        present(rateAlertController, animated: true, completion: nil)
        
    }
    
    @IBAction func startEnginePressed(_ sender: Any) {
        car.timesDriven += 1
        do {
            try context.save()
        } catch let error {
            print(error)
        }
        presentCar()
    }
    
    @IBAction func segmentedControlSelected(_ sender: Any) {
        guard let selectedMake = segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex) else { return }
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "make == %@", selectedMake)
        do {
            car = try context.fetch(fetchRequest).first
        } catch let error {
            print(error)
        }
        presentCar()
        UserDefaults.standard.set(segmentedControl.selectedSegmentIndex, forKey: "selectedIndex")
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        if !UserDefaults.standard.bool(forKey: "firstLaunch") {
            loadData()
            print("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$      FIRST              $$$$$$$$$$$$$$$$")
        }
        UserDefaults.standard.set(true, forKey: "firstLaunch")
        segmentedControl.selectedSegmentIndex = UserDefaults.standard.integer(forKey: "selectedIndex")
        
        segmentedControlSelected(Int())
        // Do any additional setup after loading the view.
    }
    
    func presentCar(){
//        segmentedControl.backgroundColor = car.color as! UIColor
        makeLabel.text = car.make
        modelLabel.text = car.model
        lastStartedLabel.text = dateFormatter.string(from: car.lastDriven ?? Date())
        timesDriven.text = "\(car.timesDriven)"
        myChoice.isHidden = !car.isFavorite
        carImage.image = UIImage(data: car.imageData ?? Data())
        ratingLabel.text = "\(car.rating) / 10"
    }

    func loadData() {
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        do {
            let results = try context.fetch(fetchRequest)
            if results.isEmpty {
                print("isEmpty")
            } else {
                return
            }
        } catch let error {
            print(error)
        }
        guard let path = Bundle.main.path(forResource: "data", ofType: "plist"), let arrayOfDictionaries = NSArray(contentsOfFile: path) else { return }
        for dictionary in arrayOfDictionaries {
            guard let entity = NSEntityDescription.entity(forEntityName: "Car", in: context) else { return }
            car = Car.init(entity: entity, insertInto: context)
            let contents = dictionary as! [String : AnyObject]
            car.make = contents["mark"] as? String
            car.model = contents["model"] as? String
            car.isFavorite = contents["myChoice"] as! Bool
            car.lastDriven = contents["lastStarted"] as? Date
            car.timesDriven = contents["timesDriven"] as! Int16
            car.rating = contents["rating"] as! Double
            car.imageData = UIImage(named: contents["imageName"] as! String)?.pngData()
            car.color = getColor(dictionary: contents["tintColor"] as! [String : Int])
        }
        do {
            try context.save()
        } catch let error {
            print(error)
        }
        
    }
    
    func getColor(dictionary: [String : Int]) -> UIColor {
        guard let red = dictionary["red"], let green = dictionary["green"], let blue = dictionary["blue"] else { return UIColor()}
        return UIColor(red: CGFloat(red/255), green: CGFloat(green/255), blue: CGFloat(blue/255), alpha: 1)
    }
    
    
}

