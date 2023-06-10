
//

import UIKit

class ClientsProductsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var imgprod: UIImageView!
    @IBOutlet weak var nomprod: UILabel!
    @IBOutlet weak var descprod: UITextView!
    @IBOutlet weak var precprod: UILabel!
    @IBOutlet weak var urlprod: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
