//
//  CurrentSessionEventCell.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 20/03/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import UIKit

import RxSwift

class CurrentSessionEventCell: UITableViewCell
{
    static let identifier: String = "CurrentSessionEventCell"
    
    private var disposeBag: DisposeBag?
    
    @IBOutlet weak var eventNameLabel: UILabel!
    
    var item: CurrentSessionModelItemBox?
    {
        didSet
        {
            // cast the ProfileViewModelItem to appropriate item type
            guard let item = item as? CurrentSessionModelEventItem  else { return }
            
            eventNameLabel?.text = item.someEvent
            
            let disposeBag = DisposeBag()
            
            Api.sharedApi.editingAllowed.distinctUntilChanged().debug().observeOn(MainScheduler.instance).subscribe(
            onNext: { [weak self] event in
                
                self?.accessoryType = event ? UITableViewCell.AccessoryType.disclosureIndicator : UITableViewCell.AccessoryType.none
                
                
                
            }).disposed(by: disposeBag)
            
            self.disposeBag = disposeBag
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
    
    override func prepareForReuse()
    {
        pretty_function()
        
        item = nil
        disposeBag = nil
    }
}
