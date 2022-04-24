//
//  VCPetCollectionViewCell.swift
//  Vets-Central
//
//  Created by Roger Vogel on 3/4/21.
//  Copyright © 2021 Roger Vogel. All rights reserved.
//

import UIKit

class VCPetCollectionViewCell: UICollectionViewCell {
    
    // MARK: OUTLETS
    
    @IBOutlet weak var petImageView: UIImageView!
    @IBOutlet weak var petNameLabel: UILabel!
    
    // MARK: INITIALIZATION
    
    override func awakeFromNib() {
        
        self.layer.cornerRadius = 10.0
        
        petImageView.roundCorners(corners: .top, radius: 3)
        petNameLabel.roundCorners(corners: .bottom, radius: 3)
    }
    
}
  
