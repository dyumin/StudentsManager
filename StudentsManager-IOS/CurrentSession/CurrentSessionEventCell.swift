//
//  CurrentSessionEventCell.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 20/03/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import UIKit

import RxSwift
import Firebase

class CurrentSessionEventCell: UITableViewCell
{
    enum Mode
    {
        case CurrentSession
        case History
    }
    
    static let identifier: String = "CurrentSessionEventCell"
    
    private var disposeBag: DisposeBag?
    
    @IBOutlet weak var eventNameLabel: UILabel!
    
    @IBOutlet weak var eventTimeLabel: UILabel!
    
    @IBOutlet weak var eventPlaceLabel: UILabel!
    
    @IBOutlet weak var eventImage: UIImageView!
    
    var mode: Mode = .CurrentSession
    
    var item: DocumentSnapshot?
    {
        didSet
        {
            guard let item = item else
            {
                self.disposeBag = nil
                return
            }
            
            if item == oldValue { return }
            
            let disposeBag = DisposeBag()
            
            if mode == .CurrentSession
            {
                Api.sharedApi.editingAllowed.distinctUntilChanged()
                .debug("CurrentSessionEventCell.editingAllowed").observeOn(MainScheduler.instance).subscribe(
                onNext: { [weak self] event in
                    
                    self?.accessoryType = event ? UITableViewCell.AccessoryType.disclosureIndicator : UITableViewCell.AccessoryType.none
                    
                }).disposed(by: disposeBag)
            }
            else
            {
                // there is no action for now...
                self.accessoryType = .detailButton
            }
            
            DispatchQueue.main.async
            {
                // rewrite using rx?
                if let name = item.get(Session.name) as? String
                {
                    self.eventNameLabel.isHidden = false
                    self.eventNameLabel.text = name
                }
                else
                {
                    self.eventNameLabel.isHidden = true
                }
                
                if let startTime = item.get(Session.startTime) as? Timestamp
                {
                    self.eventTimeLabel.isHidden = false  
                    self.eventTimeLabel.text = (startTime.dateValue() as NSDate).toLocalDate()
                }
                else
                {
                    self.eventTimeLabel.isHidden = true
                }
                
                if let room = item.get(Session.room) as? String
                {
                    self.eventPlaceLabel.isHidden = false
                    self.eventPlaceLabel.text = room
                }
                else
                {
                    self.eventPlaceLabel.isHidden = true
                }

                self.disposeBag = disposeBag
            }
        }
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        // Initialization code
        
    }

    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    // NOTE: called not only while new data is set
    override func prepareForReuse()
    {
        super.prepareForReuse()
    }
}
