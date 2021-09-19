//
//  CalendarViewModel.swift
//  WeeklyCalendar
//
//  Created by Spencer Feng on 19/9/21.
//

import Foundation

class CalendarViewModel {
    
    var days: [Day] = []
    
    let NUMBER_OF_DAYS_IN_WEEK = 7
    
    var selectedDay = Day(date: Date())
    
    private let calendar = Calendar(identifier: .gregorian)
    
    
    init() {
        prepareInitialDays()
    }
    
    private func prepareInitialDays() {
        guard let todayLastWeek = calendar.date(byAdding: .day, value: -NUMBER_OF_DAYS_IN_WEEK, to: selectedDay.date),
              let todayNextWeek = calendar.date(byAdding: .day, value: NUMBER_OF_DAYS_IN_WEEK, to: selectedDay.date)
        else {
            fatalError("Calendar data can not be initialised")
        }
        
        let daysInThisWeek = generateDaysInWeek(for: selectedDay.date)
        let daysInLastWeek = generateDaysInWeek(for: todayLastWeek)
        let daysInNextWeek = generateDaysInWeek(for: todayNextWeek)
        
        self.days = daysInLastWeek + daysInThisWeek + daysInNextWeek
    }
    
    func generateDay(offsetBy dayOffset: Int, for baseDate: Date) -> Day {
        let date = calendar.date(byAdding: .day, value: dayOffset, to: baseDate) ?? baseDate
        return Day(date: date)
    }
    
    func generateDaysInWeek(for baseDate: Date) -> [Day] {
        let weekdayOfBaseDate = calendar.component(.weekday, from: baseDate)
        
        let days: [Day] = (1...NUMBER_OF_DAYS_IN_WEEK)
            .map { day in
                return generateDay(offsetBy: day - weekdayOfBaseDate, for: baseDate)
            }
        return days
    }
    
    func getIndexPathOfSelectedDay() -> IndexPath? {
        if let indexOfCurrentSelectedDay = days.firstIndex(where: {$0.date == selectedDay.date}) {
            return IndexPath(row: indexOfCurrentSelectedDay, section: 0)
        }
        return nil
    }
    
    func updateSelectedDayByAdding(numberOfDays: Int) {
        guard let upcomingSelectedDate = calendar.date(byAdding: .day, value: numberOfDays, to: selectedDay.date) else {
            fatalError("Failed to update the selected day")
        }
        selectedDay = Day(date: upcomingSelectedDate)
    }
    
    func prependANewWeek() {
        let firstDayInDataSource = days[0]

        // create days for the previous week
        guard let lastDayOfThePreviousWeek = calendar.date(byAdding: .day, value: -1, to: firstDayInDataSource.date) else {
            fatalError("Days in the previous week can not be created")
        }
        let daysInThePreviousWeek = generateDaysInWeek(for: lastDayOfThePreviousWeek)

        // update data source
        days = daysInThePreviousWeek + days
    }
    
    func appendANewWeek() {
        let lastDayInDataSource = days[days.count - 1]

        // create days for the next week
        guard let firstDayOfTheNextWeek = calendar.date(byAdding: .day, value: 1, to: lastDayInDataSource.date) else {
            fatalError("Days in the next week can not be created")
        }
        let daysInTheNextWeek = generateDaysInWeek(for: firstDayOfTheNextWeek)
        
        // update data source
        days += daysInTheNextWeek
    }
    
}
