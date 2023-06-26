//
//  ProjectsTableViewCell.swift
//  HallMorgan_RenoReady
//
//  Created by Morgan Hall on 6/25/23.
//

import UIKit

class ProjectsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var categoryIcon: UIImageView!
    
    @IBOutlet weak var projectName_label: UILabel!
    
    @IBOutlet weak var deadline_label: UILabel!
    
    @IBOutlet weak var remainingBudget_label: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
