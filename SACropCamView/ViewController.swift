//
//  ViewController.swift
//  SACropCamView
//
//  Created by Paresh Prajapati on 05/10/20.
//  Copyright © 2020 SolutionAnalysts. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    enum CardState {
        case expanded
        case collapsed
    }
    var cardViewController: CardViewController!
    var visualEffectView: UIVisualEffectView!
    var cardHeight: CGFloat = 700
    var cardHandleHeight: CGFloat = 80
    var isCardVisible: Bool = false
    var nextState: CardState {
        return isCardVisible ? .collapsed : .expanded
    }
    var runningAnimations = [UIViewPropertyAnimator]()
    var animationProgressWhenInterrupted:CGFloat = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpCard()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleViewTap))
        tapGesture.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapGesture)
    }
    
    @objc func handleViewTap() {
        cardHeight = 800
        cardHandleHeight = 200
        setUpCard()
    }
    
    func setUpCard() {
        if self.cardViewController != nil {
            self.cardViewController.view.removeFromSuperview()
        }
        visualEffectView = UIVisualEffectView()
        visualEffectView?.frame = self.view.frame
        self.view.addSubview(visualEffectView)
        
        self.cardViewController = CardViewController(nibName: "CardViewController", bundle: nil)
        self.addChild(self.cardViewController)
        self.view.addSubview(self.cardViewController.view)
        
        self.cardViewController.view.frame = CGRect(x: 0, y: self.view.frame.size.height - self.cardHandleHeight, width: self.view.bounds.width, height: cardHeight)
        self.cardViewController.view.clipsToBounds = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleCardTap))
        tapGesture.numberOfTapsRequired = 1
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleCardPan))
        self.cardViewController.handleView.addGestureRecognizer(panGesture)
        self.cardViewController.handleView.addGestureRecognizer(tapGesture)
    }
    
    
    @objc func handleCardTap(recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            self.animateTransitionIfNeeded(state: nextState, duration: 0.9)
        default: break
        }
    }
    
    @objc func handleCardPan(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            self.startInteractiveTransition(state: nextState, duration: 0.9)
        case .changed:
            let translation = recognizer.translation(in: self.cardViewController.handleView)
            var fractionCompleted = translation.y / cardHeight
            fractionCompleted = isCardVisible ? fractionCompleted : -fractionCompleted
            updateInteractiveTransition(fractionCompleted: fractionCompleted )
        case .ended:
            continueInteractiveTransition()
        default:
            break
        }
    }
    
    
    func animateTransitionIfNeeded(state: CardState, duration: TimeInterval) {
        if runningAnimations.isEmpty {
            let frameAnimation = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.cardViewController.view.frame.origin.y = (self.view.frame.height - self.cardHeight)
                case .collapsed:
                    self.cardViewController.view.frame.origin.y = (self.view.frame.height - self.cardHandleHeight)
                }
            }
            
            frameAnimation.addCompletion {_ in
                self.isCardVisible = !self.isCardVisible
                self.runningAnimations.removeAll()
            }
            frameAnimation.startAnimation()
            runningAnimations.append(frameAnimation)
        
            let cornerRadiusAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
                switch state {
                case .expanded:
                    self.cardViewController.view.layer.cornerRadius = 12
                case .collapsed:
                    self.cardViewController.view.layer.cornerRadius = 0
                }
            }
            cornerRadiusAnimator.startAnimation()
            runningAnimations.append(cornerRadiusAnimator)
            
            
            let blurAnimation = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.visualEffectView.effect = UIBlurEffect(style: .dark)
                case .collapsed:
                    self.visualEffectView.effect = nil
                }
            }
            
            blurAnimation.startAnimation()
            runningAnimations.append(blurAnimation)
        }
    }
    
    func startInteractiveTransition(state: CardState, duration: TimeInterval) {
        if runningAnimations.isEmpty {
            animateTransitionIfNeeded(state: state, duration: duration)
        }
        
        for animator in self.runningAnimations {
            animator.pauseAnimation()
            self.animationProgressWhenInterrupted = animator.fractionComplete
        }
    }
    
    func updateInteractiveTransition(fractionCompleted: CGFloat) {
        
        for animator in self.runningAnimations {
            animator.fractionComplete = fractionCompleted + animationProgressWhenInterrupted
        }
    }
    
    func continueInteractiveTransition() {
        for animator in self.runningAnimations {
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        }
    }

}
