//
//  Copyright © 2017 Simon Kågedal Reimer. All rights reserved.
//

import UIKit
import SKRBatchUpdates

enum Section {
    case one
    case two
    case three
    case four
    case five
}

extension Section: CustomStringConvertible {
    var description: String {
        switch self {
        case .one:      return "Section One"
        case .two:      return "Section Two"
        case .three:    return "Section Three"
        case .four:     return "Section Four"
        case .five:     return "Section Five"
        }
    }
}

class RandomTableViewController: UITableViewController {

    let dataSource = DataSource<Section, String>()

    @IBAction func cycleDataSource(_ sender: UIBarButtonItem) {
        dataSource.animate(to: randomDataSource(), in: tableView, with: .fade)
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.numberOfSections()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.numberOfRows(in: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let itemString = dataSource.itemForRow(at: indexPath)

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") else {
            fatalError("could not dequeue cell")
        }
        cell.textLabel?.text = itemString
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "\(dataSource.section(at: section))"
    }

    // MARK: - Building a random data source

    func randomDataSource() -> [(Section, [String])] {
        var sections: [Section] = [.one, .two, .three, .four, .five]
        var items: [String] = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T"]
        let maxItemsInSection = items.count / sections.count
        
        let numSections = sections.count.random()
    
        return (0..<numSections).map { _ in
            let section = sections.removeRandom()
            let numItems = maxItemsInSection.random()
            let items = (0..<numItems).map({ _ in items.removeRandom() })
            return (section, items)
        }
    }
}

private extension Array {
    mutating func removeRandom() -> Element {
        return remove(at: count.random())
    }
}

private extension Int {
    func random() -> Int {
        return Int(arc4random_uniform(UInt32(self)))
    }
}
