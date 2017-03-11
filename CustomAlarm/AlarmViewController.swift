//
//  AlarmViewController.swift
//  CustomAlarm
//
//  Created by Jason Crawford on 3/10/17.
//  Copyright © 2017 Jason Crawford. All rights reserved.
//

import UIKit

class AlarmViewController: UITableViewController, UITextFieldDelegate {
    
    var alarm: Alarm!

    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var caption: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var tapToSelectImage: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func datePickerChanged(_ sender: Any) {
    }

    @IBAction func imageViewTapped(_ sender: Any) {
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        alarm.name = name.text!
        title = alarm.name
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true 
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
