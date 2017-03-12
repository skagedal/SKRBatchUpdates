//
//  Copyright © 2017 Simon Kågedal Reimer. All rights reserved.
//

import UIKit
import SKRBatchUpdates

class LetterCollectionViewCell: UICollectionViewCell {
    @IBOutlet var letterLabel: UILabel!
}

class RandomCollectionViewController: UICollectionViewController {

    let dataSource = DataSource<RandomSection, String>()

    @IBAction func cycleDataSource(_ sender: UIBarButtonItem) {
        dataSource.animate(to: randomDataSource(), in: collectionView!)
    }

    // MARK: - UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.numberOfSections()
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.numberOfRows(in: section)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let itemString = dataSource.itemForRow(at: indexPath)
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? LetterCollectionViewCell else {
            fatalError("could not dequeue cell")
        }
        
        cell.letterLabel.text = itemString
        return cell
    }
    

}
