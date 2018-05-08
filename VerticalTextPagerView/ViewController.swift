//
//  ViewController.swift
//  VerticalTextDemo2
//
//  Created by Leray Lanusiv on 4/23/18.
//  Copyright © 2018 Leray Lanusiv. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIScrollViewDelegate, UIPopoverControllerDelegate, SamplesDelegate {
    
    //    @IBOutlet weak var ctView: CTSelectionView!
    
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var samplesBtn: UIBarButtonItem!
    
    @IBOutlet weak var nextPageBtn: UIButton!
    @IBOutlet weak var previousPageBtn: UIButton!
    
    @IBOutlet weak var pagerView: PagerView!
    
    var scrollFeedbackFromOtherControl: Bool!
    
    var selectedSampleName: String = "Article.xml"
    
    //    var samplesController: SamplesViewController!
    
    //    var samplesPopoverViewController: UIPopoverController!
    
    //
    //    @IBAction func samplesPopup(_ sender: UIBarButtonItem) {
    //        self.samplesPopoverViewController.present(from: self.samplesBtn, permittedArrowDirections: .any, animated: true)
    //    }
    
    @IBAction func nextPage(_ sender: UIButton) {
        pagerView.pageUp()
        previousPageBtn.isEnabled = true
        
        let page = pagerView.pageDisplayed
        let count = pagerView.pageCount
        if page >= count - 1 {
            nextPageBtn.isEnabled = false
        }
    }
    
    @IBAction func previousPage(_ sender: UIButton) {
        pagerView.pageDown()
        nextPageBtn.isEnabled = true
        
        let page = pagerView.pageDisplayed
        if page == 0 {
            previousPageBtn.isEnabled = false
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //        print("prepareForSegue: \(segue.identifier), destination: \(segue.destination)")
        if segue.identifier == "show samples", let naviCtl = segue.destination as? UINavigationController, let samplesCtl = naviCtl.topViewController as? SamplesViewController {
            samplesCtl.delegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //        if let (attrString, imageDict) = loadText() {
        //            ctView.attrString = attrString
        //            ctView.imageDict = imageDict
        //        }
        scrollFeedbackFromOtherControl = true
        
        //        previousPageBtn.isEnabled = false
        
        pagerView.reset(doc: AttributedStringDoc(withFileNameFromBundle: selectedSampleName), withDelegate: self)
        
        self.title = selectedSampleName.components(separatedBy: ".")[0]
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        //        pagerView.relayoutDoc()
    }
    
    // MARK: - Samples controller delegate methods
    
    func samplesController(_ controller: SamplesViewController, didSelectString fileName: String) {
        self.pagerView.reset(doc: AttributedStringDoc(withFileNameFromBundle: fileName), withDelegate: self)
        selectedSampleName = fileName
        self.title = selectedSampleName.components(separatedBy: ".")[0]
        controller.dismiss(animated: true)
    }
    
    // MARK: - PagerView ScrollView Delegate methods
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //        print("scrollViewDidScroll ")
        //        if scrollFeedbackFromOtherControl {
        //            return
        //        }
        
        let pageWidth = pagerView.frame.size.width
        let page = Int(floor((pagerView.contentOffset.x - pageWidth / 2) / pageWidth)) + 1
        pagerView.setPage(page)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        //        print("scrollViewDidEndScrollingAnimation ")
        let pageWidth = pagerView.frame.size.width
        let page = Int(floor((pagerView.contentOffset.x - pageWidth / 2) / pageWidth)) + 1
        pagerView.setPage(page)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        //        print("scrollViewWillBeginDragging")
        scrollFeedbackFromOtherControl = false
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        //        print("scrollViewWillBeginDragging")
        scrollFeedbackFromOtherControl = true
    }
}

