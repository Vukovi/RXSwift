//
//  TVCell.swift
//  OurPlanet
//
//  Created by Vuk Knežević on 7/5/18.
//  Copyright © 2018 Florent Pillet. All rights reserved.
//

import UIKit

class TVCell: UITableViewCell {
    
    static func identifier() -> String {
        return String(describing: self)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
}
