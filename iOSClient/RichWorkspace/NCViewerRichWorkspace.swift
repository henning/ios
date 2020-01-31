//
//  NCViewerRichWorkspace.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 14/01/2020.
//  Copyright © 2020 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
import NCCommunication
import MarkdownKit

@objc class NCViewerRichWorkspace: UIViewController, UIAdaptivePresentationControllerDelegate {

    @IBOutlet weak var textView: UITextView!
    
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    private let richWorkspaceCommon = NCRichWorkspaceCommon()
    private let markdownParser = MarkdownParser(font: UIFont.systemFont(ofSize: 15))
    @objc public var richWorkspaceText: String = ""
    @objc public var serverUrl: String = ""
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presentationController?.delegate = self
        markdownParser.header.font = UIFont.systemFont(ofSize: 25)
        
        let closeItem = UIBarButtonItem(title: NSLocalizedString("_back_", comment: ""), style: .plain, target: self, action: #selector(closeItemTapped(_:)))
        self.navigationItem.leftBarButtonItem = closeItem
                
        let editItem = UIBarButtonItem(image: UIImage(named: "actionSheetModify"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(editItemAction(_:)))
        self.navigationItem.rightBarButtonItem = editItem

        textView.attributedText = markdownParser.parse(richWorkspaceText)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.changeTheming), name: NSNotification.Name(rawValue: "changeTheming"), object: nil)
        changeTheming()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NCCommunication.sharedInstance.readFileOrFolder(serverUrlFileName: serverUrl, depth: "0", account: appDelegate.activeAccount) { (account, files, errorCode, errorMessage) in
            
            if errorCode == 0 && account == self.appDelegate.activeAccount {
                
                var metadataFolder = tableMetadata()
                _ = NCNetworking.sharedInstance.convertFiles(files!, urlString: self.appDelegate.activeUrl, serverUrl: self.serverUrl, user: self.appDelegate.activeUser, metadataFolder: &metadataFolder)
                NCManageDatabase.sharedInstance.setDirectory(ocId: metadataFolder.ocId, serverUrl: metadataFolder.serverUrl, richWorkspace: metadataFolder.richWorkspace, account: account)
                self.richWorkspaceText = metadataFolder.richWorkspace
                self.appDelegate.activeMain.richWorkspaceText = self.richWorkspaceText
                self.textView.attributedText = self.markdownParser.parse(self.richWorkspaceText)
            }
        }
    }
    
    public func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        self.viewWillAppear(true)
    }
    
    @objc func changeTheming() {
        appDelegate.changeTheming(self, tableView: nil, collectionView: nil, form: false)
        textView.attributedText = markdownParser.parse(richWorkspaceText)
    }
    
    @objc func closeItemTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func editItemAction(_ sender: Any) {
        
        richWorkspaceCommon.openViewerNextcloudText(serverUrl: serverUrl, viewController: self)
    }
}
