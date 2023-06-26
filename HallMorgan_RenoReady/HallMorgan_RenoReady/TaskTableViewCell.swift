//
//  TaskTableViewCell.swift
//  HallMorgan_RenoReady
//
//  Created by Morgan Hall on 6/25/23.
//

import UIKit

class TaskTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var taskCircle_imageView: UIImageView!
    
    @IBOutlet weak var taskTitle_label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
