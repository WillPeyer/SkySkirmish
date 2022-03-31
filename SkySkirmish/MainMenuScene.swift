//
//  MainMenuScene.swift
//  SkySkirmish
//
//  Created by 90309333 on 3/16/22.
//

import Foundation
import UIKit
import SpriteKit
import GameplayKit

class MainMenuScene: SKScene{
    override func didMove(to view: SKView) {
//        let background = SKSpriteNode(imageNamed: "background")
//        background.size = self.size
//        background.zPosition = 0
//        background.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
//        self.addChild(background)
        
        let title1 = SKLabelNode()
        title1.fontSize = 150
        title1.fontColor = SKColor.white
        title1.text = "Sky Skirmish"
        title1.zPosition = 1
        title1.setScale(0.5)
        title1.position = CGPoint(x: self.size.width/2, y: self.size.height * 0.65)
        self.addChild(title1)
        
        let startGame = SKLabelNode()
        startGame.fontSize = 75
        startGame.fontColor = SKColor.white
        startGame.text = "Start Game"
        startGame.zPosition = 1
        startGame.name = "Start Button"
        startGame.setScale(0.5)
        startGame.position = CGPoint(x: self.size.width/2, y: self.size.height * 0.4)
        self.addChild(startGame)
        
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch: AnyObject in touches{
            let pointOfTouch = touch.location(in: self)
            let nodeITapped = atPoint(pointOfTouch)
            if nodeITapped.name == "Start Button"{
                let scene = GKScene(fileNamed: "GameScene")
                let sceneToMoveTo = scene!.rootNode as! GameScene
                sceneToMoveTo.scaleMode = .fill
                sceneToMoveTo.entities = scene!.entities
                sceneToMoveTo.graphs = scene!.graphs
                //let myTransition = SKTransition.fade(withDuration: 0.5)
                self.view!.presentScene(sceneToMoveTo)
                //transition: myTransition
            }
            
        }
        
        
        
    }
}
