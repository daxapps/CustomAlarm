//
//  ViewController.swift
//  CustomAlarm
//
//  Created by Jason Crawford on 3/10/17.
//  Copyright © 2017 Jason Crawford. All rights reserved.
//

import UIKit
import UserNotifications

class ViewController: UITableViewController {
    
    var groups = [Group]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let titleAttributes = [NSFontAttributeName: UIFont(name: "Arial Rounded MT Bold", size: 20)!]
        
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
        
        title = "Custom Alarm"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addGroup))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Groups", style: .plain, target: nil, action: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(save), name: Notification.Name("save"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        load()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
            return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        groups.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        
        save()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Group", for: indexPath)
        let group = groups[indexPath.row]
        
        cell.textLabel?.text = group.name
        
        if group.enabled {
            cell.textLabel?.textColor = UIColor.black
        } else {
            cell.textLabel?.textColor = UIColor.red
        }
        
        if group.alarms.count == 1 {
            cell.detailTextLabel?.text = "1 alarm"
        } else {
            cell.detailTextLabel?.text = "\(group.alarms.count) alarms"
        }
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let groupToEdit: Group
        
        if sender is Group {
            // we were called from addGroup(); use what it sent us
            groupToEdit = sender as! Group
        } else {
            // we were called by a table view cell; figure out which group we're attached to send
            guard let selectedIndexPath = tableView.indexPathForSelectedRow else { return }
            groupToEdit = groups[selectedIndexPath.row]
        }
        
        // unwrap our destination from the segue
        if let groupViewController = segue.destination as? GroupViewController {
            
            // give it whatever group we decided above
            groupViewController.group = groupToEdit
        }
    }
    
    func addGroup() {
        
        let newGroup = Group(name: "Name", playSound: true, enabled: false, alarms: [])
        
        groups.append(newGroup)
        
        performSegue(withIdentifier: "EditGroup", sender: newGroup)
        
        save()
    }
    
    func save() {
        
        do {
            
            let path = Helper.getDocumentsDirectory().appendingPathComponent("groups")
            let data = NSKeyedArchiver.archivedData(withRootObject: groups)
            
            try data.write(to: path)
            
        } catch {
            
            print("Failed to save")
        }
        
        updateNotifications()
    }
    
    func updateNotifications() {
        
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .sound]) { [unowned self] (granted, error) in
            
            if granted {
                
                self.createNotifications()
            }
        }
    }
    
    func createNotifications() {
        
        let center = UNUserNotificationCenter.current()
        
        //1: remove any pending notifications
        center.removeAllPendingNotificationRequests()
        
        //2: ignore disabled groups
        for group in groups {
            
            guard group.enabled == true else { continue }
            
            for alarm in group.alarms {
                
                //3: create a notification request for each alarm
                
                let notification = createNotificationRequest(group: group, alarm: alarm)
                
                //4: schedule that notification for delivery
                center.add(notification) { error in
                    
                    if let error = error {
                        print("Error scheduling notifications: \(error)")
                    }
                }
            }
        }
    }
    
    func createNotificationRequest(group: Group, alarm: Alarm)-> UNNotificationRequest {
        
        //start by creating the content for the notification
        let content = UNMutableNotificationContent()
        
        //assign the users name and caption
        content.title = alarm.name
        content.body = alarm.caption
        
        //give it an identifier we can attach to custom buttons later on
        content.categoryIdentifier = "alarm"
        
        //attach the group ID and alarm ID for this alarm
        content.userInfo = ["group": group.id, "alarm": alarm.id]
        
        //if the user requested a sound for this group, attach their default alert sound
        if group.playSound {
            
            content.sound = UNNotificationSound.default()
        }
        //use createNotificationAttachments to attach a picture for this alert if there is one
        content.attachments = createNotificationAttachments(alarm: alarm)
        
        //get a calendar ready to pull out date components
        let cal = Calendar.current
        
        //pull out the hour and minute from this alarm's date
        var dateComponents = DateComponents()
        dateComponents.hour = cal.component(.hour, from: alarm.time)
        dateComponents.minute = cal.component(.minute, from: alarm.time)
        
        //create a trigger matching those date components, set to repeat
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        //testing trigger
        //let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: true)
        
        //combine the content and the trigger to create a notification request
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        //pass that object back to createNotifications() for scheduling
        return request
    }
    
    func createNotificationAttachments(alarm: Alarm) -> [UNNotificationAttachment] {
        
        //1 - return if there is no image to attach
        guard alarm.image.characters.count > 0 else { return [] }
        
        let fm = FileManager.default
        
        do {
            //2 - get the full path to the alarm image
            let imageURL = Helper.getDocumentsDirectory().appendingPathComponent(alarm.image)
            
            //3 - create a full path to a temporary filename
            let copyURL = Helper.getDocumentsDirectory().appendingPathComponent("(UUID().uuidString).jpg")
            
            //4 - copy the alarm image to the temporary filename
            try fm.copyItem(at: imageURL, to: copyURL)
            
            //5 - create an attachment from the temporary filename, giving it a random identifier
            let attachment = try UNNotificationAttachment(identifier: UUID().uuidString, url: copyURL)
            
            //6 - return the attachment back to the createNotificationRequest()
            return [attachment]
            
        } catch {
            print("Failed to attach alarm image: \(error)")
            return []
        }
    }
    
    func load() {
        
        do {
            
            let path = Helper.getDocumentsDirectory().appendingPathComponent("groups")
            let data = try Data(contentsOf: path)
            
            groups = NSKeyedUnarchiver.unarchiveObject(with: data) as? [Group] ?? [Group]()
            
        } catch {
            
            print("Failed to load")
        }
        
        tableView.reloadData()
    }


}








