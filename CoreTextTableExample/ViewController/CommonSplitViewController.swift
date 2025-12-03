//
//  CommonSplitViewController.swift
//  CoreTextTableExample
//
//  Created by Thomas on 08.05.25.
//

import UIKit

//--------------------------------------------------------------------------------------------
// MARK: - CommonSplitViewController

/// Kann für alle Split View Controller genutzt werden, wenn Liste und Detail im Storyboard definiert sind.
/// Als Parameter muss 'Double Column' gesetzt sein.

class CommonSplitViewController : UISplitViewController, UISplitViewControllerDelegate
{
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Screensize:", view.frame.width, " x ", view.frame.height)
        self.delegate = self
        
        preferredDisplayMode = .oneBesideSecondary
        preferredSplitBehavior = .tile
        
        minimumPrimaryColumnWidth = 300
        maximumPrimaryColumnWidth = 1500
        preferredPrimaryColumnWidthFraction = 0.50
    }
    
    func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
        return .primary
    }
    
}

//--------------------------------------------------------------------------------------------
