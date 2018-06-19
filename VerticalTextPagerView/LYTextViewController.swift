//
//  LYTextViewController.swift
//  VerticalTextPagerView
//
//  Created by Leray Lanusiv on 5/22/18.
//  Copyright © 2018 Leray Lanusiv. All rights reserved.
//

import UIKit

class LYTextViewController: UIViewController {

    @IBOutlet weak var textView: LYTextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let (attrString, imageDict) = loadText() {
//            textView.isVerticalLayout = false
            textView.imageDict = imageDict
            textView.attrString = attrString
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
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
