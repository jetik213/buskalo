//
//  ProductsTableViewCell.swift
//  buskalo
//
//  Created by crizcode on 2/18/23.
//  Copyright © 2023 crizcode. All rights reserved.
//

import UIKit

class ProductsTableViewCell: UITableViewCell {

 
    @IBOutlet weak var nomprodLabel: UILabel!
    @IBOutlet weak var precprodLabel: UILabel!
    @IBOutlet weak var imgLabel: UIImageView!
    @IBOutlet weak var urlprodTextView: UITextView!
    @IBOutlet weak var descprodtextView: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
