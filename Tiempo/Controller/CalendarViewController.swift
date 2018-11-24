//
//  ViewController.swift
//  Tiempo
//
//  Created by Adam Zemmoura on 21/11/2018.
//  Copyright © 2018 Adam Zemmoura. All rights reserved.
//

import UIKit

class CalendarViewController: UIViewController {
    
    private var numberOfDaysInMonth = [31,28,31,30,31,30,31,31,30,31,30,31]
    private var currentMonth : Month = .jan
    private var currentYear = 0
    private var day = 0
    private var firstWeekdayOfMonth = 0
    private var weeklyWeatherForecast : [Int : WeatherDataToday] = [:] { // contains the weather for the next 7 days, key is the day in this month ie. 3 for 3rd
        didSet {
            collectionView.reloadData()
        }
    }
    
    private let weatherData : WeatherDataServiceProtocol = DarkSkyWeatherAPIClient.shared
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.allowsMultipleSelection = false
            collectionView.register(UINib(nibName: "DateCollectionViewCell", bundle: Bundle.main), forCellWithReuseIdentifier: "dateCell")
        }
    }
    
    @IBOutlet weak var monthSelectionView: MonthSelectionView! {
        didSet {
            monthSelectionView.delegate = self
        }
    }
    
    
    @IBOutlet weak var weatherForecaseTitleLabel: UILabel!
    @IBOutlet weak var weatherForecastInfoLabel: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let now = Date()
        let calendar = Calendar.current
        currentMonth = Month(rawValue: calendar.component(.month, from: now))!
        currentYear = calendar.component(.year, from: now)
        day = calendar.component(.day, from: now)
        firstWeekdayOfMonth = getFirstWeekdayOfMonth()
    
        // code to test the DarkSkyWeatherAPI module
        DarkSkyWeatherAPIClient.shared.getWeeklyForecastForLocation(lat: 41.3851, long: 2.1734) { (weeklyWeatherData) in
            
            // make sure we're on the main thread for UI updates
            DispatchQueue.main.async {
                let days = weeklyWeatherData.data
                
                for day in days {
                    print(day.time)
                    
                    // get the current day (as an int) to use as a key
                    let key = Calendar.current.component(.day, from: day.time)
                    self.weeklyWeatherForecast[key] = day
                    
                    print("Key is :", key)
                    
                    if let iconDesc = day.icon {
                        if let icon = WeatherIcon(rawValue: iconDesc)?.image {
                            print(icon)
                        }
                    }
                }
                
                // get the weekly weather summary text if there is any
                if let weeklyWeatherSummary = weeklyWeatherData.summary {
                    self.weatherForecastInfoLabel.text = weeklyWeatherSummary
                }
            }
    
        }
    }
    
    private func getFirstWeekdayOfMonth() -> Int {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let firstDayOfMonth = Calendar.current.firstWeekday
        //let firstDayOfMonth = formatter.date(from: "\(currentYear)-\(currentMonth.rawValue)-01")!
        print("first day of the month : \(firstDayOfMonth)")
        
        print("current month : \(currentMonth.rawValue)")
        let firstWeekdayOfMonth = ("\(currentYear)-\(currentMonth.rawValue)-01".date?.firstDayOfTheMonth.weekday)!
        print("First weekday of the month : \(firstWeekdayOfMonth)")
        return firstWeekdayOfMonth
    }

}

extension CalendarViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfDaysInMonth[currentMonth.rawValue - 1] + (firstWeekdayOfMonth - 1)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "dateCell", for: indexPath) as! DateCollectionViewCell
        
        if indexPath.item <= firstWeekdayOfMonth - 2 {
            cell.isHidden = true
        } else {
            let calculatedDate = indexPath.row - (firstWeekdayOfMonth - 2)
            cell.isHidden = false
            
            // check whether it's this month in which case pass current weather icon for next 7 days
            let thisMonth = Month(rawValue: Calendar.current.component(.month, from: Date()))!
            if currentMonth == thisMonth  {
                if weeklyWeatherForecast[calculatedDate] != nil {
                    
                    // check if there is weather icon description and if so attempt to create a weather icon for it
                    if let iconDesc = weeklyWeatherForecast[calculatedDate]!.icon {
                        if let icon = WeatherIcon(rawValue: iconDesc)?.image {
                            cell.configureForDay(day: calculatedDate, month: currentMonth, weatherIcon: icon)
                        }
                    }
                    // no weather icon data so just configure the date cell normally
                    else {
                        cell.configureForDay(day: calculatedDate, month: currentMonth)
                    }
                }
            }
            else {
                cell.configureForDay(day: calculatedDate, month: currentMonth)
            }
        }
        
        return cell
    }
    
    
    
    
}

extension CalendarViewController : UICollectionViewDelegate {
    
    
    
}

extension CalendarViewController : UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width/7 - 8
        let height: CGFloat = width
        return CGSize(width: width, height: height)
    }
    
}

extension CalendarViewController : MonthSelectionViewDelegate {
    
    func monthSelectionViewDidChange(month: Month, year: Int) {
        currentMonth = month
        currentYear = year
        
        // allow for leap years
        if month == .feb {
            if currentYear % 4 == 0 {
                numberOfDaysInMonth[month.rawValue - 1] = 29
            } else {
                numberOfDaysInMonth[month.rawValue - 1] = 28
            }
        }
        
        firstWeekdayOfMonth = getFirstWeekdayOfMonth()
        collectionView.reloadData()
    }
}