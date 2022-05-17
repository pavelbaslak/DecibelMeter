//
//  Image.swift
//  DecibelMet
//
//  Created by Stas Dashkevich on 16.05.22.
//

import Foundation
import UIKit

class ImageView: UIImageView {
    
    enum Image {
        case lock
        case faq
        case rate
        case support
        case privacy
        case terms
        case share
    }
    
    init(image: Image) {
        super.init(frame: .zero)
        
        contentMode = .scaleAspectFit
        clipsToBounds = true
        
        switch image {
        case .lock:
            self.image = UIImage(named: "lock")
        case .faq:
            self.image = UIImage(named: "faq")
        case .rate:
            self.image = UIImage(named: "rate")
        case .support:
            self.image = UIImage(named: "support")
        case .privacy:
            self.image = UIImage(named: "privacy")
        case .terms:
            self.image = UIImage(named: "terms")
        case .share:
            self.image = UIImage(named: "share")
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

//import UIKit
//
//class ImageView: UIImageView {
//
//    enum Image {
//        case progressCircle
//        case human
//        case rating
//        case soundLevels
//        case soundMeter
//        case chevron
//        case timeIcon
//        case feedbackIcon
//        case privacyIcon
//        case documentIcon
//        case playIcon
//        case shareIcon
//        case ratingBack
//    }
//
//    init(image: Image) {
//        super.init(frame: .zero)
//
//        contentMode = .scaleAspectFit
//        clipsToBounds = true
//
//        switch image {
//        case .progressCircle:
//            self.image = UIImage(named: "ProgressCircle")
//        case .human:
//            self.image = UIImage(named: "Human")
//        case .rating:
//            self.image = UIImage(named: "Rating")
//        case .soundLevels:
//            self.image = UIImage(named: "SoundLevels")
//        case .soundMeter:
//            self.image = UIImage(named: "SoundMeter")
//        case .chevron:
//            self.image = UIImage(named: "Chevron")
//        case .timeIcon:
//            self.image = UIImage(named: "Clock")
//        case .feedbackIcon:
//            self.image = UIImage(named: "Feedback")
//        case .privacyIcon:
//            self.image = UIImage(named: "Privacy")
//        case .documentIcon:
//            self.image = UIImage(named: "Document")
//        case .playIcon:
//            self.image = UIImage(named: "Play")
//        case .shareIcon:
//            self.image = UIImage(named: "Share")
//        case .ratingBack:
//            self.image = UIImage(named: "RatingBack")
//        }
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//}
