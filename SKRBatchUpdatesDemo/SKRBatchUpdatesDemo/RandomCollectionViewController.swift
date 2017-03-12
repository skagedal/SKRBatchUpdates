//
//  Copyright © 2017 Simon Kågedal Reimer. All rights reserved.
//

import UIKit
import SKRBatchUpdates

class LetterCollectionViewCell: UICollectionViewCell {
    @IBOutlet var letterLabel: UILabel!
}

class CollectionViewHeader: UICollectionReusableView {
    @IBOutlet var headerLabel: UILabel!
}

class RandomCollectionViewController: UICollectionViewController {

    let dataSource = DataSource<RandomSection, String>()

    @IBAction func cycleDataSource(_ sender: UIBarButtonItem) {
        let random = randomDataSource()
        dataSource.animate(to: random, in: collectionView!)
        printRandomDataSource(random)
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
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath) as? CollectionViewHeader else {
            fatalError("bad header cell")
        }
        header.headerLabel.text = "\(dataSource.section(at: indexPath.section))"
        return header
    }
}
