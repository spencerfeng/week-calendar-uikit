//
//  MainViewController.swift
//  WeeklyCalendar
//
//  Created by Spencer Feng on 2/9/21.
//

import UIKit

class MainViewController: UIViewController {
    
    // MARK: - Properties
    private let SPACING: CGFloat = 10
    private let NUMBER_OF_DAYS_IN_WEEK: Int = 7
    private let calendar = Calendar(identifier: .gregorian)
    
    private var selectedDay = Day(date: Date())
    
    private var fullScrollDistanceBase: CGFloat {
        return calendarContainerSize.width - self.SPACING
    }
    
    private var calendarContainerSize: CGSize {
        return CGSize(
            width: weeklyCalendarCollectionView.bounds.width,
            height: weeklyCalendarCollectionView.bounds.height
        )
    }
    
    private var cellSize: CGSize {
        return CGSize(
            width: (calendarContainerSize.width - CGFloat(NUMBER_OF_DAYS_IN_WEEK + 1) * self.SPACING) / CGFloat(7),
            height: calendarContainerSize.height - 2 * self.SPACING
        )
    }
    
    private lazy var dataSource: [Day] = {
        guard let todayLastWeek = calendar.date(byAdding: .day, value: -NUMBER_OF_DAYS_IN_WEEK, to: selectedDay.date),
              let todayNextWeek = calendar.date(byAdding: .day, value: NUMBER_OF_DAYS_IN_WEEK, to: selectedDay.date)
        else {
            fatalError("Calendar data can not be initialised")
        }
        
        let daysInThisWeek = generateDaysInWeek(for: selectedDay.date)
        let daysInLastWeek = generateDaysInWeek(for: todayLastWeek)
        let daysInNextWeek = generateDaysInWeek(for: todayNextWeek)
        
        return daysInLastWeek + daysInThisWeek + daysInNextWeek
    }()
    
    private lazy var weeklyCalendarCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = self.SPACING
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: self.SPACING, left: self.SPACING, bottom: self.SPACING, right: self.SPACING)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isScrollEnabled = true
        collectionView.alwaysBounceHorizontal = false
        collectionView.backgroundColor = .systemTeal
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.layer.cornerRadius = 10
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(CalendarDateCollectionViewCell.self, forCellWithReuseIdentifier: CalendarDateCollectionViewCell.reuseIdentifier)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        return collectionView
    }()
    
    // MARK: - Life cycles
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        layoutViews()
        
        DispatchQueue.main.async {
            self.weeklyCalendarCollectionView.setContentOffset(CGPoint(x: CGFloat(self.NUMBER_OF_DAYS_IN_WEEK) * (self.cellSize.width + self.SPACING), y: 0), animated: false)
        }
    }
    
    private func layoutViews() {
        view.addSubview(weeklyCalendarCollectionView)
        
        NSLayoutConstraint.activate([
            weeklyCalendarCollectionView.heightAnchor.constraint(equalToConstant: 60),
            weeklyCalendarCollectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            weeklyCalendarCollectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            weeklyCalendarCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])
    }
    
    // MARK: - Helpers
    private func generateDaysInWeek(for baseDate: Date) -> [Day] {
        let weekdayOfBaseDate = calendar.component(.weekday, from: baseDate)
        
        let days: [Day] = (1...NUMBER_OF_DAYS_IN_WEEK)
            .map { day in
                return generateDay(offsetBy: day - weekdayOfBaseDate, for: baseDate)
            }
        return days
    }
    
    private func generateDay(offsetBy dayOffset: Int, for baseDate: Date) -> Day {
        let date = calendar.date(byAdding: .day, value: dayOffset, to: baseDate) ?? baseDate
        return Day(date: date)
    }
    
    private func getIndexPathOfSelectedDay() -> IndexPath? {
        if let indexOfCurrentSelectedDay = dataSource.firstIndex(where: {$0.date == selectedDay.date}) {
            return IndexPath(row: indexOfCurrentSelectedDay, section: 0)
        }
        return nil
    }
    
    private func updateSelectedDayByAdding(numberOfDays: Int) {
        guard let upcomingSelectedDate = calendar.date(byAdding: .day, value: numberOfDays, to: selectedDay.date) else {
            fatalError("Failed to update the selected day")
        }
        selectedDay = Day(date: upcomingSelectedDate)
    }
    
}

extension MainViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let day = dataSource[indexPath.row]
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CalendarDateCollectionViewCell.reuseIdentifier, for: indexPath) as? CalendarDateCollectionViewCell else {
            fatalError("CalendarDateCollectionViewCell not found")
        }
        cell.configureCell(day: day, isSelected: day.date == selectedDay.date)
        
        return cell
    }
}

extension MainViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: cellSize.width, height: cellSize.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var itemsToReload = [indexPath]
        
        // find the indexPath of the current selected day
        if let indexPathOfSelectedDay = getIndexPathOfSelectedDay() {
            itemsToReload.append(indexPathOfSelectedDay)
        }
        
        selectedDay = dataSource[indexPath.row]
        weeklyCalendarCollectionView.reloadItems(at: itemsToReload)
    }
}

extension MainViewController: UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool) {
        let groupIndex = Int(scrollView.contentOffset.x / fullScrollDistanceBase)
        let isLeft = scrollView.panGestureRecognizer.translation(in: scrollView.superview).x > 0

        if scrollView.contentOffset.x.truncatingRemainder(dividingBy: fullScrollDistanceBase) <= 0.5 * (fullScrollDistanceBase) {
            if isLeft {
                updateSelectedDayByAdding(numberOfDays: -NUMBER_OF_DAYS_IN_WEEK)
            }
            DispatchQueue.main.async {
                let updatedContentOffsetX = CGFloat(groupIndex * self.NUMBER_OF_DAYS_IN_WEEK) * (self.cellSize.width + self.SPACING)
                scrollView.setContentOffset(CGPoint(x: updatedContentOffsetX, y: 0), animated: true)
            }
        } else {
            if !isLeft {
                updateSelectedDayByAdding(numberOfDays: NUMBER_OF_DAYS_IN_WEEK)
            }
            DispatchQueue.main.async {
                let updatedContentOffsetX = CGFloat((groupIndex + 1) * self.NUMBER_OF_DAYS_IN_WEEK) * (self.cellSize.width + self.SPACING)
                scrollView.setContentOffset(CGPoint(x: updatedContentOffsetX, y: 0), animated: true)
            }
        }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        let groupIndex = Int(scrollView.contentOffset.x / fullScrollDistanceBase)
        let isLeft = scrollView.panGestureRecognizer.translation(in: scrollView.superview).x > 0

        if isLeft {
            // first week in data source
            if groupIndex == 0 {
                let firstDayInDataSource = self.dataSource[0]

                // create days for the previous week
                guard let lastDayOfThePreviousWeek = calendar.date(byAdding: .day, value: -1, to: firstDayInDataSource.date) else {
                    fatalError("Days in the previous week can not be created")
                }
                let daysInThePreviousWeek = generateDaysInWeek(for: lastDayOfThePreviousWeek)

                // update data source
                dataSource = daysInThePreviousWeek + dataSource
                
                DispatchQueue.main.async {
                    self.weeklyCalendarCollectionView.setContentOffset(CGPoint(x: CGFloat(self.NUMBER_OF_DAYS_IN_WEEK) * (self.cellSize.width + self.SPACING), y: 0), animated: false)
                }
            }
        } else {
            // last week in data source
            if groupIndex + 1 == dataSource.count / NUMBER_OF_DAYS_IN_WEEK {
                let lastDayInDataSource = self.dataSource[self.dataSource.count - 1]

                // create days for the next week
                guard let firstDayOfTheNextWeek = calendar.date(byAdding: .day, value: 1, to: lastDayInDataSource.date) else {
                    fatalError("Days in the next week can not be created")
                }
                let daysInTheNextWeek = generateDaysInWeek(for: firstDayOfTheNextWeek)
                
                // update data source
                dataSource = dataSource + daysInTheNextWeek
            }
        }

        weeklyCalendarCollectionView.reloadData()
    }
}
