//
//  ViewController.swift
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 12/09/2018.
//  Copyright © 2018 Bauman. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
//        NSString* imageToUse = [[NSBundle mainBundle] pathForResource:@"3group" ofType:@"jpg"];
        
        let imageToUse = Bundle.main.path(forResource: "3group", ofType: "jpg")
        
        let array = FacesExtractor.getFaceImagesFromImage(atPath: imageToUse!)
        
        self.imageView.image = array.first
    }


}

