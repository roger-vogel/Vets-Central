//
//  VCAppointmentTableViewCell.swift
//  Vets-Central
//
//  Created by Roger Vogel on 3/4/21.
//  Copyright © 2021 Roger Vogel. All rights reserved.
//

import UIKit

class VCAppointmentTableViewCell : UITableViewCell {
    
    // MARK: OUTLETS
    
    @IBOutlet weak var appointmentTypeLabel: UILabel!
    @IBOutlet weak var petNameButton: UIButton!
    @IBOutlet weak var clinicNameLabel: UILabel!
    @IBOutlet weak var doctorNameLabel: UILabel!
    @IBOutlet weak var appointmentDateLabel: UILabel!
    @IBOutlet weak var appointmentTimeLabel: UILabel!
    @IBOutlet weak var petImageView: UIImageView!
   
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        petNameButton.roundCorners(corners: .top )
        petImageView.roundCorners(corners: .bottom )
    }
}

