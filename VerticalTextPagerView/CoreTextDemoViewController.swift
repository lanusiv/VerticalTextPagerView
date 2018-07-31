//
//  CoreTextDemoViewController.swift
//  VerticalTextPagerView
//
//  Created by Leray Lanusiv on 5/8/18.
//  Copyright © 2018 Leray Lanusiv. All rights reserved.
//

import UIKit

class CoreTextDemoViewController: UIViewController {

    @IBOutlet weak var ctSelectionView: CTSelectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        if let (attributedString, imageDict) = loadText() {
//            ctSelectionView.attrString = attributedString
//            ctSelectionView.imageDict = imageDict
//        }
        
        let share = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(displayShareSheet))
        navigationItem.rightBarButtonItem = share
    }

    @objc private func displayShareSheet() {
        
        let pdf = ctSelectionView.createAPDF()
//        guard let image = ctSelectionView.createImage() else {
//            return
//        }
        //        let title = "I wanna share you an awsome app!"
        //        let url = URL(string: "http://www.mtime.com/")
        let vc = UIActivityViewController(activityItems: [pdf], applicationActivities: [])
        present(vc, animated: true)
        vc.completionWithItemsHandler = { activity, success, items, error in
            print("activity", activity, "success", success, "items", items, "error", error)
            if !success {
                print("cancelled")
                return
            }
            
            if activity == UIActivityType.mail {
                print("mail")
            }
            else if activity == UIActivityType.message {
                print("message")
            }
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
