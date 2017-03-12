//
//  Copyright © 2017 Simon Kågedal Reimer. All rights reserved.
//

import UIKit
import SKRBatchUpdates

class RandomTableViewController: UITableViewController {

    let dataSource = DataSource<RandomSection, String>()

    @IBAction func cycleDataSource(_ sender: UIBarButtonItem) {
        let random = randomDataSource()
        dataSource.animate(to: random, in: tableView, with: .fade)
        printRandomDataSource(random)
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
}

