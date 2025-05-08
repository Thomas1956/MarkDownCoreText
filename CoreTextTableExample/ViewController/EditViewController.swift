//
//  EditViewController.swift
//  CoreTextTableExample
//
//  Created by Thomas on 08.05.25.
//

import UIKit
import UsefulExtensions

class EditViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        self.extendedLayoutIncludesOpaqueBars = true
        self.navigationController?.navigationBar.prefersLargeTitles = true

        if #available(iOS 16, *) {
            navigationItem.style = .navigator
        }
        
        textView.textContainerInset.left = 8
        textView.textContainerInset.right = 8
        
        let addButton    = ImageBarButtonItem(systemName: "plus",  action: didPressAddButton(_:))
        let deleteButton = ImageBarButtonItem(systemName: "trash", action: didPressDeleteButton(_:))
        
        navigationItem.rightBarButtonItems = [deleteButton, addButton]
    }
    
    @objc func didPressAddButton(_ sender: Any) {
    }
    
    @objc func didPressDeleteButton(_ sender: Any) {
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
