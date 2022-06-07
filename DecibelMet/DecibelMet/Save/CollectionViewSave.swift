//
//  CollectionViewSave.swift
//  DecibelMet
//
//  Created by Stas Dashkevich on 27.05.22.
//

import Foundation
import UIKit
import AVFAudio
import SwipeCellKit

class SaveController: UIViewController {
    
    private var collection: UICollectionView?
    
        let persist = Persist()
        var recordings: [Record]?
        var player: Player!
        var isPlaying: Bool = false
        var tagPlaying: Int?
        var tags: [Int] = []
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        buttonToogler()
    }
    
    func buttonToogler() {
        for tag in tags {
            let tmp = self.collection?.cellForItem(at: [0, tag]) as! CustomSaveCell
            
            if tmp.isPlaying {
                if let tagPlaying = tagPlaying {
                    if tmp.tag == 0 {
                        if tmp.isPlaying {
                            print("wrong")
                            tmp.isPlaying = false
                            tmp.playButton.setImage(UIImage(named: "png"), for: .normal)
                            if player.player.isPlaying {
                                player.player.stop()
                            }
                        } else {
                            print("true")
                            tmp.isPlaying = true
                            tmp.playButton.setImage(UIImage(named: "button3"), for: .normal)
                        }
                    } else if tmp.tag == tagPlaying {
                        print("true")
                        tmp.isPlaying = true
                        tmp.playButton.setImage(UIImage(named: "button3"), for: .normal)
                    } else {
                        print("wrong")
                        tmp.isPlaying = false
                        tmp.playButton.setImage(UIImage(named: "png"), for: .normal)
                        if player.player.isPlaying {
                            player.player.stop()
                        }
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let result = persist.fetch() else { return }
        recordings = result
        
        collection?.reloadData()
        tabBarController?.tabBar.isHidden = false
//        self.tabBarController?.tabBar.tintColor = UIColor.white
//        self.tabBarController?.tabBar.barTintColor = UIColor.black
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: (view.frame.size.width) - 30, height: 80)
        layout.minimumLineSpacing = 10
        collection = UICollectionView(frame: view.frame, collectionViewLayout: layout)
        
        guard let collection = collection else {
            return
        }
        collection.register(CustomSaveCell.self, forCellWithReuseIdentifier: CustomSaveCell.id)
        collection.delegate = self
        collection.dataSource = self
        collection.backgroundColor = .black
//        collectionView.frame = view.bounds
        collection.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(collection)
        NSLayoutConstraint.activate([
            collection.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collection.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collection.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collection.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30)
        ])
        buttonToogler()

    }
    
}

extension SaveController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 9
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CustomSaveCell.id, for: indexPath) as! CustomSaveCell
        cell.layer.cornerRadius = 10
        cell.layer.masksToBounds = true
        cell.contentView.backgroundColor = #colorLiteral(red: 0.1490753889, green: 0.1489614546, blue: 0.1533248723, alpha: 1)
        cell.delegate = self
        
        
        return cell
    }
    
   
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedItem = collectionView.cellForItem(at: indexPath)
        
        selectedItem?.layer.borderColor = UIColor.red.cgColor
        
        print(1)
    }
}

extension SaveController: SwipeCollectionViewCellDelegate {
    func collectionView(_ collectionView: UICollectionView, editActionsForItemAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }

            let deleteAction = SwipeAction(style: .destructive, title: nil) { action, indexPath in
                // handle action by updating model with deletion
            }
        
        let editAction = SwipeAction(style: .default, title: nil) { action, indexPath in
            // handle action by updating model with deletion
        }
        
        let shareAction = SwipeAction(style: .destructive, title: nil) { action, indexPath in
            // handle action by updating model with deletion
        }

            // customize the action appearance
//            deleteAction.image = UIImage(named: "deleteIcon")
//            editAction.image = UIImage(named: "deleteIcon")
//            shareAction.image = UIImage(named: "deleteIcon")
            deleteAction.backgroundColor = #colorLiteral(red: 0.979583323, green: 0.004220267292, blue: 1, alpha: 1)
            editAction.backgroundColor = #colorLiteral(red: 0.07074324042, green: 0.8220555186, blue: 0.6004908681, alpha: 1)
            shareAction.backgroundColor = #colorLiteral(red: 0.137247622, green: 0, blue: 0.956287086, alpha: 1)
            deleteAction.image = UIImage(named: "delete")
            editAction.image = UIImage(named: "edit")
            shareAction.image = UIImage(named: "icons")
            return [deleteAction,shareAction,editAction]
    }
    
    func collectionView(_ collectionView: UICollectionView, editActionsOptionsForItemAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = .destructive
        options.transitionStyle = .border
        return options
    }
    
    
}


