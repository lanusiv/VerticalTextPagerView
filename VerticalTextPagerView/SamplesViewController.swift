//
//  SamplesViewController.swift
//  VerticalTextDemo2
//
//  Created by Leray Lanusiv on 5/6/18.
//  Copyright © 2018 Leray Lanusiv. All rights reserved.
//

import UIKit

protocol SamplesDelegate {
    func samplesController(_ controller: SamplesViewController, didSelectString fileName: String)
}

// MARK: - SamplesViewController

class SamplesViewController: UITableViewController, UIActionSheetDelegate {

    // MARK: - Properties
    var delegate: SamplesDelegate?
    var samplesForDisplay: [String]!
    var selectedSample: String!
    
    func copySamplesInBundle() -> [String] {
        var result = [String]()
        if let filesInBundle = try? FileManager.default.contentsOfDirectory(atPath: Bundle.main.bundlePath) {
            for fileName in filesInBundle {
                if fileName.hasSuffix(".xml") {
                    result.append((fileName as NSString).deletingPathExtension)
                }
            }
        }
        return result
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Samples"
        
        self.samplesForDisplay = self.copySamplesInBundle()
        self.selectedSample = ""
    }

    // MARK: - TableView methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.samplesForDisplay.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let CellIndentifier = "Cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: CellIndentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: CellIndentifier)
        }
        let cellSampleName = self.samplesForDisplay[indexPath.row]
        cell!.textLabel?.text = cellSampleName
        if self.selectedSample == cellSampleName {
            cell!.accessoryType = .checkmark
        } else {
            cell!.accessoryType = .none
        }
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellSampleName = self.samplesForDisplay[indexPath.row]
        if let delegate = self.delegate {
            delegate.samplesController(self, didSelectString: (cellSampleName as NSString).appendingPathExtension("xml")!)
        }
        self.selectedSample = cellSampleName
        self.tableView.reloadData()
    }

}
