//
//  CurrentSessionEventCell.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 20/03/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import UIKit

class CurrentSessionEventCell: UITableViewCell
{
    static let identifier: String = "CurrentSessionEventCell"
    
    @IBOutlet weak var eventNameLabel: UILabel!
    
    var item: CurrentSessionModelItem?
    {
        didSet
        {
            // cast the ProfileViewModelItem to appropriate item type
            guard let item = item as? CurrentSessionModelEventItem  else
            {
                return
            }
            
            eventNameLabel?.text = item.someEvent
            
//            pictureImageView?.image = UIImage(named: item.pictureUrl)
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
    }
}
