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

        if let (attributedString, imageDict) = loadText() {
            ctSelectionView.attrString = attributedString
            ctSelectionView.imageDict = imageDict
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
