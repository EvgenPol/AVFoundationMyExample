//
//  MainViewController.swift
//  AVFoundationMyExample
//
//  Created by Евгений Полюбин on 24.08.2021.
//

import UIKit

class MainViewController: UIViewController {

    @IBOutlet weak var cameraButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraButton.layer.cornerRadius = cameraButton.bounds.height / 2
    }
    
    @IBAction func tappedCamera(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "RecordViewController") as! RecordViewController
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true, completion: nil)
    }
    

}

