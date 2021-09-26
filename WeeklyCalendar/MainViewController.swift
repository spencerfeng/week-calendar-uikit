//
//  MainViewController.swift
//  WeeklyCalendar
//
//  Created by Spencer Feng on 2/9/21.
//

import UIKit

class MainViewController: UIViewController {
    
    // MARK: - typealiases
    typealias DataSource = UICollectionViewDiffableDataSource<Int, Day>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Int, Day>
    
    // MARK: - Properties
    private let SPACING: CGFloat = 10
    private let calendar = Calendar(identifier: .gregorian)
    
    private let viewModel: CalendarViewModel
    
    private lazy var dataSource = makeDataSource()
    
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
            width: (calendarContainerSize.width - CGFloat(viewModel.NUMBER_OF_DAYS_IN_WEEK + 1) * self.SPACING) / CGFloat(7),
            height: calendarContainerSize.height - 2 * self.SPACING
        )
    }
    
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
        collectionView.delegate = self
        
        collectionView.register(CalendarDateCollectionViewCell.self, forCellWithReuseIdentifier: CalendarDateCollectionViewCell.reuseIdentifier)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        return collectionView
    }()
    
    // MARK: - Initialisers
    init(viewModel: CalendarViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life cycles
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        layoutViews()
        applySnapshot()
        
        DispatchQueue.main.async {
            self.weeklyCalendarCollectionView.setContentOffset(CGPoint(x: CGFloat(self.viewModel.NUMBER_OF_DAYS_IN_WEEK) * (self.cellSize.width + self.SPACING), y: 0), animated: false)
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
    
    // MARK: - Functions
    func makeDataSource() -> DataSource {
        let dataSource = DataSource(collectionView: weeklyCalendarCollectionView, cellProvider: { (collectionView, indexPath, day) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CalendarDateCollectionViewCell.reuseIdentifier, for: indexPath) as? CalendarDateCollectionViewCell
            cell?.configureCell(day: day, isSelected: day.date == self.viewModel.selectedDay.date)
            return cell
        })
        return dataSource
    }
    
    func applySnapshot() {
        var snapshot = Snapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(viewModel.days)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
}

extension MainViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: cellSize.width, height: cellSize.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let indexPathOfSelectedDay = viewModel.getIndexPathOfSelectedDay(),
              let oldSelectedDay = dataSource.itemIdentifier(for: indexPathOfSelectedDay),
              let newSelectedDay = dataSource.itemIdentifier(for: indexPath)
        else {
            return
        }
        
        if indexPathOfSelectedDay == indexPath {
            return
        }
        
        var newSnapshot = dataSource.snapshot()
        newSnapshot.reloadItems([oldSelectedDay, newSelectedDay])
        
        viewModel.selectedDay = viewModel.days[indexPath.row]
        
        dataSource.apply(newSnapshot)
       
    }
}

extension MainViewController: UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool) {
        let groupIndex = Int(scrollView.contentOffset.x / fullScrollDistanceBase)
        let isLeft = scrollView.panGestureRecognizer.translation(in: scrollView.superview).x > 0

        if scrollView.contentOffset.x.truncatingRemainder(dividingBy: fullScrollDistanceBase) <= 0.5 * (fullScrollDistanceBase) {
            if isLeft {
                viewModel.updateSelectedDayByAdding(numberOfDays: -viewModel.NUMBER_OF_DAYS_IN_WEEK)
            }
            DispatchQueue.main.async {
                let updatedContentOffsetX = CGFloat(groupIndex * self.viewModel.NUMBER_OF_DAYS_IN_WEEK) * (self.cellSize.width + self.SPACING)
                scrollView.setContentOffset(CGPoint(x: updatedContentOffsetX, y: 0), animated: true)
            }
        } else {
            if !isLeft {
                viewModel.updateSelectedDayByAdding(numberOfDays: viewModel.NUMBER_OF_DAYS_IN_WEEK)
            }
            DispatchQueue.main.async {
                let updatedContentOffsetX = CGFloat((groupIndex + 1) * self.viewModel.NUMBER_OF_DAYS_IN_WEEK) * (self.cellSize.width + self.SPACING)
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
                viewModel.prependANewWeek()
                
                DispatchQueue.main.async {
                    self.weeklyCalendarCollectionView.setContentOffset(CGPoint(x: CGFloat(self.viewModel.NUMBER_OF_DAYS_IN_WEEK) * (self.cellSize.width + self.SPACING), y: 0), animated: false)
                }
            }
        } else {
            // last week in data source
            if groupIndex + 1 == viewModel.days.count / viewModel.NUMBER_OF_DAYS_IN_WEEK {
                viewModel.appendANewWeek()
            }
        }
        
        applySnapshot()
    }
}
