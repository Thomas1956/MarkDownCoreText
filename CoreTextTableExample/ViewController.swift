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

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10).isActive = true
        scrollView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -10).isActive = true
        scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10).isActive = true
        
        scrollView.markdown(string: text1)
    }

    let text1 =
    """
    > # Beispiel Blockquote
    
    Duis  ^[dynamisches Blau](color: 'blue') aecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. 
    Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    
    _______________
    > ## Überschrift 2
    
    > Blockquote loorem ipsum dolor sit amet, **consectetur** adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut ~***aliquip***~ ex ea ^[commodo consequat](size:20, weight: 'bold', color: 'orange'). Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat
        0 1 2 3 4 5 6 7 8 9 
    
    > - Erstens
    > - Zweitens
    
    0 1 2 3 4
    Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. 
    _______________
    
    # Headline 1 ![Circle](person.circle:50)
    ## ![Circle](person.circle:35) Headline 2 

    Here is an [Example Link](https://example.com).

    --------
    
    ^[Lorem ipsum **bold** dolor sit _italic_ amet, ![Trash](trash:22) consectetur **adipisicing** elit.](size:22, color: 'orange')

    - List item 1 lorem ipsum dolor sit amet lorem ipsum dolor
    - List item 2 ![Circle](circle)

    ![AppIcon](AppIcon1024:50)
    
    1. List item 1
    1. List item 2
    1. List item 3

    ### Tabelle
    | Name      | Datum    | Preis       |
    | :--       | :--:     |  ---:       |
    | Socken    | 01.02.24 |     12,34 € |
    | Hose      | 14.06.23 |    654,78 € |
    | Stehlampe | 12.12.21 | 10.543,98 € |

    ### Headline 3

    Ut enim ad `inline code` minim ***bold italic*** veniam, ~strikethrough~ quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.

    > Blockquote loorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea ^[commodo consequat](style: 'marked'). Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    
    > Zweite Zeile
    
    jkjkjk

    ```
    5 LET S = 0
    10 MAT INPUT V
    20 LET N = NUM
    30 IF N = 0 ^[THEN](style: 'marked') 99
    
    
    40 FOR I = 1 TO N
    45 LET S = S + V(I)
    50 NEXT I
    60 PRINT S/N
    70 GO TO 5
    99 END
    ```

    
    # Beispiel: Farbe und Liste

    Excepteur sint occaecat cupidatat non proident,\
    sunt in culpa qui officia deserunt mollit anim id est laborum. Zeilenende.
    Zeilenanfang. Excepteur sint occaecat cupidatat non proident,\
    sunt in culpa qui officia deserunt mollit anim id est laborum.
    
    ^[Farbe!!! Lorem ipsum bold dolor sit italic amet, consectetur adipisicing elit.](size:22, color: 'orange')

    - List item 1 lorem ipsum dolor sit amet lorem ipsum dolor
    - List item 2 sdd
    - 1986^[.]() Jahreszahl
    - List item 2 sdd

    """


}

