//
//  Copyright © 2017 Simon Kågedal Reimer. All rights reserved.
//

import UIKit
import SKRBatchUpdates

class TetrisCollectionViewController: UICollectionViewController {
    
    let dataSource = DataSource<TetrisRow, TetrisBlock>()
    var game = TetrisGame()
    var timer: Timer?
    
    // MARK: Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource.sections = game.currentBoard.dataSource
    }

    // MARK: Actions
    
    @IBAction func newGame(_ sender: Any) {
        startGame()
        let timer = Timer(fire: Date(), interval: 0.5, repeats: true) {_ in
            self.tick()
        }
        RunLoop.current.add(timer, forMode: .defaultRunLoopMode)
        self.timer = timer
    }
    
    // MARK: - UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.numberOfSections()
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.numberOfRows(in: section)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let block = dataSource.itemForRow(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        cell.configure(with: block)
        
        return cell
    }

    func startGame() {
        if game.spawn() {
            update()
        } else {
            print("game over!")
        }
    }
    
    func tick() {
        if game.tick() {
            update()
        }
    }

    func update() {
        dataSource.animate(to: game.currentBoard.dataSource, in: collectionView!)
    }
}

extension UICollectionViewCell {
    func configure(with block: TetrisBlock) {
        switch block.type {
        case .empty:
            backgroundColor = .clear
            
        case .occupied(let color):
            backgroundColor = color
        }
    }
}

extension TetrisBoard {
    var dataSource: [(TetrisRow, [TetrisBlock])] {
        return rows.map { ($0, $0.blocks) }
    }
}
