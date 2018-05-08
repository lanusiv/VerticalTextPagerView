//
//  ViewController.swift
//  VerticalTextDemo2
//
//  Created by Leray Lanusiv on 4/23/18.
//  Copyright © 2018 Leray Lanusiv. All rights reserved.
//

import UIKit

class ViewController: UIViewController, SamplesDelegate {
    
    
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var samplesBtn: UIBarButtonItem!
    
    @IBOutlet weak var pagerView: PagerView!
    
//    var scrollFeedbackFromOtherControl: Bool!
    
    var selectedSampleName: String = "Article.xml"
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //        print("prepareForSegue: \(segue.identifier), destination: \(segue.destination)")
        if segue.identifier == "show samples", let naviCtl = segue.destination as? UINavigationController, let samplesCtl = naviCtl.topViewController as? SamplesViewController {
            samplesCtl.delegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pagerView.reset(doc: AttributedStringDoc(withFileNameFromBundle: selectedSampleName))
        
        self.title = selectedSampleName.components(separatedBy: ".")[0]
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        //        pagerView.relayoutDoc()
    }
    
    // MARK: - Samples controller delegate methods
    
    func samplesController(_ controller: SamplesViewController, didSelectString fileName: String) {
        self.pagerView.reset(doc: AttributedStringDoc(withFileNameFromBundle: fileName))
        selectedSampleName = fileName
        self.title = selectedSampleName.components(separatedBy: ".")[0]
        controller.dismiss(animated: true)
    }
    
}

