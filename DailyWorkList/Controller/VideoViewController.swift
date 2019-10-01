//
//  VideoViewController.swift
//  DailyWorkList
//
//  Created by poyuchen on 2018/10/21.
//  Copyright © 2018年 poyu. All rights reserved.
//

import Foundation
import UIKit
import AVKit

class VideoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UISearchBarDelegate, UITextFieldDelegate, UITextViewDelegate {
    
    let sqlManager = (UIApplication.shared.delegate as! AppDelegate).sqlManager
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var videoTableView: UITableView!
    
    var videoList: [Media] = [Media]()
    var searchList: [Media] = [Media]()
    let cellIdentifier: String = "VideoTableViewCell"
    var refreshControl: UIRefreshControl!
    var event_id: Int64!
    let type: Int = 1
    let path: String = "Video/"
    let formatter = DateFormatter()
    let videoPiker = UIImagePickerController()
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        formatter.dateFormat = "yyyyMMddHHmmssSSSS"
        
        // Refresh Control
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(reloadTableView), for: UIControlEvents.valueChanged)
        videoTableView.addSubview(refreshControl)
        
        reloadTableView()
    }
    
    @objc func reloadTableView() {
        videoList.removeAll()
        videoList.append(contentsOf: sqlManager.queryMediaByEventIdAndType(event_id: event_id, type: type))
        searchList.removeAll()
        searchList.append(contentsOf: self.videoList)
        
        self.videoTableView.reloadData()
        self.refreshControl.endRefreshing()
    }
    
    // get the count of elements you are going to display in your tableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchList.count
    }
    
    // assign the values in your array variable to a cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! VideoTableViewCell
        cell.id = self.searchList[indexPath.row].id
        cell.title.text = self.searchList[indexPath.row].title
        cell.title.tag = Int(self.searchList[indexPath.row].id)
        cell.detail.text = self.searchList[indexPath.row].detail
        cell.detail.tag = Int(self.searchList[indexPath.row].id)
        cell.playButton.tag = indexPath.row
        cell.playButton.addTarget(self, action: #selector(openVideoPlayer), for: .touchUpInside)
        
        do {
            let filePath = documentsURL.appendingPathComponent(self.searchList[indexPath.row].path)
            let asset = AVURLAsset(url: filePath, options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
            cell.videoImage.image = UIImage(cgImage: cgImage)
        } catch {
            // TODO
        }
        return cell
    }
    
    @objc func openVideoPlayer(_ sender: UIButton) {
        let filePath = documentsURL.appendingPathComponent(self.searchList[sender.tag].path)
        if FileManager.default.fileExists(atPath: filePath.path) {
            let player = AVPlayer(url: filePath)
            let playerController = AVPlayerViewController()
            playerController.player = player
            present(playerController, animated: true) {
                player.play()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .normal, title: "Delete") { action, indexPath in
            do {
                let filePath = self.documentsURL.appendingPathComponent(self.searchList[indexPath.row].path).path
                try FileManager.default.removeItem(atPath: filePath)
                self.sqlManager.deleteMediaById(id: self.searchList[indexPath.row].id)
                self.reloadTableView()
            } catch {
                // TODO
                print("\(error)")
            }
        }
        delete.backgroundColor = UIColor.red
        
        return [delete]
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        do {
            // 檢查dictionary是否正存在
            let documentsDirectory = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
            let dataPath = documentsDirectory.appendingPathComponent(path)!
            try FileManager.default.createDirectory(atPath: dataPath.path, withIntermediateDirectories: true)
            
            // 取得此影片
            let videoURL: URL = info[UIImagePickerControllerMediaURL] as! URL
            // 新檔檔名，依照檔案副檔名儲存檔案類型
            let fileName = "\(formatter.string(from: Date())).\(videoURL.pathExtension)"
            let fileURL = documentsURL.appendingPathComponent(path + fileName)
            print(fileURL)
            
            let myVideoVarData = try! Data(contentsOf: videoURL)
            try myVideoVarData.write(to: fileURL, options: .atomic)
            
            sqlManager.insertMedia(event_id: event_id, type: type, title: fileName, detail: nil, path: path + fileName)

        } catch {
            // TODO
            print("\(error)")
        }
        
        // update the button label text
        self.reloadTableView()
        
        videoPiker.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func add(_ sender: UIBarButtonItem) {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            videoPiker.sourceType = .savedPhotosAlbum
            videoPiker.delegate = self
            videoPiker.mediaTypes = ["public.movie"]
            self.present(videoPiker, animated: true, completion: nil)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            // 當搜尋匡內容為空時，查詢全部
            self.searchList.append(contentsOf: self.videoList)
        } else {
            // 清空搜尋陣列
            self.searchList.removeAll()
            for video in self.videoList {
                // 將title的名稱起始相同的資料加入
                if video.title.hasPrefix(searchText) {
                    self.searchList.append(video)
                }
            }
        }
        // 刷新tableView 数据显示
        self.videoTableView.reloadData()
    }
    
    // when search bar button be clicked
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // when user click the cancel button
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // 清空查詢匡文字
        searchBar.text = ""
        searchBar.endEditing(true)
        // 查詢陣列為全部
        self.searchList.removeAll()
        self.searchList.append(contentsOf: self.videoList)
        self.videoTableView.reloadData()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.text! == "" {
            confirmAlert("title cannot be null!")
            return false
        } else {
            self.view.endEditing(true)
            sqlManager.updateMediaTitleById(id: Int64(textField.tag), title: textField.text!)
            return true
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            sqlManager.updateMediaDetailById(id: Int64(textView.tag), detail: textView.text)
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    @objc func confirmAlert(_ message: String) {
        let alertViewController = UIAlertController(title: "Warn!", message: message, preferredStyle: .alert)
        alertViewController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
        }))
        self.present(alertViewController, animated: true, completion: nil)
    }
}

