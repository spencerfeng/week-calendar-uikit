//
//  CalendarDateCollectionViewCell.swift
//  WeeklyCalendar
//
//  Created by Spencer Feng on 2/9/21.
//

import UIKit

class CalendarDateCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = String(describing: CalendarDateCollectionViewCell.self)
    
    var day: Day?
    
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d"
        return dateFormatter
    }()
    
    private let numberLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.layer.cornerRadius = 5
        contentView.addSubview(numberLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        NSLayoutConstraint.activate([
            numberLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            numberLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configureCell(day d: Day, isSelected: Bool) {
        day = d
        numberLabel.text = dateFormatter.string(from: d.date)
        
        updateStyle(isSelected: isSelected)
    }
    
    func updateStyle(isSelected: Bool) {
        let contentBackgroundColor: UIColor = isSelected ? .brown : .white
        let numberLabelColor: UIColor = isSelected ? .white : .black
        
        contentView.backgroundColor = contentBackgroundColor
        numberLabel.textColor = numberLabelColor
    }
}
