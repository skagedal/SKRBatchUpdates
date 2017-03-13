//
//  Copyright © 2017 Simon Kågedal Reimer. All rights reserved.
//

import UIKit
import SKRBatchUpdates

class TetrisViewController: UIViewController, UICollectionViewDataSource {
    
    @IBOutlet var collectionView: UICollectionView!
    
    let dataSource = DataSource<TetrisRow, TetrisBlock>()
    var game = TetrisGame()
    var timer: Timer?
    
    // MARK: Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource.sections = game.currentBoard.dataSource
        collectionView.dataSource = self
    }

    // MARK: Actions
    
    @IBAction func play(_ sender: Any) {
        startGame()
        startTimer()
    }
    
    @IBAction func moveLeft(_ sender: UIBarButtonItem) {
        if game.left() {
            update()
        }
    }
    
    @IBAction func moveRight(_ sender: UIBarButtonItem) {
        if game.right() {
            update()
        }
    }
    
    @IBAction func rotateLeft(_ sender: UIBarButtonItem) {
        if game.rotateLeft() {
            update()
        }
    }
    
    @IBAction func rotateRight(_ sender: UIBarButtonItem) {
        if game.rotateRight() {
            update()
        }
    }
    
    @IBAction func drop(_ sender: UIBarButtonItem) {
        if game.drop() {
            stopTimer()
            update(completion: { _ in
                self.startTimer()
            })
        }
    }
    
    // Game logic
    
    func startGame() {
        spawnOrGameOver()
    }
    
    func tick() {
        if game.down() {
            update()
        } else {
            game.fixBlock()
            if game.removeLines() {
                update()
            }
            spawnOrGameOver()
        }
    }

    func spawnOrGameOver() {
        if game.spawn() {
            update()
        } else {
            print("game over!")
        }
    }
    
    func update(completion: ((Bool) -> Swift.Void)? = nil) {
        dataSource.animate(to: game.currentBoard.dataSource, in: collectionView, completion: completion)
    }

    func startTimer() {
        let timer = Timer(fire: Date(), interval: 0.5, repeats: true) {_ in
            self.tick()
        }
        RunLoop.current.add(timer, forMode: .defaultRunLoopMode)
        self.timer = timer
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.numberOfSections()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.numberOfRows(in: section)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let block = dataSource.itemForRow(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        cell.configure(with: block)
        
        return cell
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
