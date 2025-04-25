//
//  ViewController.swift
//  CoreTextTableExample
//
//  Created by Thomas on 24.04.25.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let sampleTable = Table(
//            headers: ["Name", "Description", "Notes"],
//            rows: [
//                ["Item 1", "This is a longer description that will wrap into multiple lines.", "Lorem ipsum dolor sit amet."],
//                ["Item 2", "Short desc.", "Another note here that also might wrap depending on width."]
//            ]
//        )

//        let tableView = CoreTextTableView(frame: view.bounds)
//        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        tableView.table = sampleTable
//        view.addSubview(tableView)
        
        let scrollView = MarkdownScrollView(frame: view.bounds)
        view.addSubview(scrollView)

//        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10).isActive = true
        scrollView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -10).isActive = true
        scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10).isActive = true
        
        scrollView.markdown(string: text1)
    }

    let text1 =
    """
    # Beispiel Blockquote
    
    Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. 
    Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. 
    Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    
    _______________
    > # Überschrift 2
    
    > Blockquote loorem ipsum dolor sit amet, **consectetur** adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut ~***aliquip***~ ex ea ^[commodo consequat](size:20, weight: 'bold', color: 'orange'). Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat
        0 1 2 3 4 5 6 7 8 9 
    
    > - Erstens
    > - Zweitens
    
    0 1 2 3 4
    Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. 
    _______________
    
    > Excepteur sint occaecat cupidatat non proident, sunt in ^[culpa](style: 'marked') qui officia deserunt mollit anim id est laborum.
    > klklklklkl
    
    ghggh
        
    """


}

