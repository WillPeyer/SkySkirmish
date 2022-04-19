//
//  GameScene.swift
//  SkySkirmish
//
//  Created by 90308346 on 2/11/22.
// hi

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    var enemies: [Enemy] = []
    var HelicopterOnScreen: SKSpriteNode = SKSpriteNode()
    
    var gamePaused:Bool = false
    var isPlayerAlive:Bool = true
    var lastUpdateTime: CFTimeInterval = 0
    var timer: Timer?
    var CooldownTimer: Timer?
    var MainWeaponTimer: Timer?
    var WingCannonsTimer: Timer?
    var EnemyTimer: Timer?
    var RandomTimer: Timer?
    var HeliTimer: Timer?
    var HeliWeaponTimer: Timer?
    var HeliSpriteTimer: Timer?
    
    var mainWeaponLevel = 0
    let mainWeaponIntervals = [0.425, 0.4, 0.375, 0.35, 0.325, 0.3, 0.275, 0.25, 0.225, 0.2]
    let mainWeaponDamage = [100, 125, 150, 175, 200, 225, 250, 275, 300, 325]
    var cooldown = false
    var randomPath = 0
    var enemyIdentifier = 0
    var isHeliAlive: Bool = false
    var score: Int = 0
    
    enum CollisionType: UInt32 {
        case none = 0
        case player = 1
        case item = 2
        case enemyBullet = 4
        case bullet = 6
        case enemy = 8
    }
    
    let spaceShipTexture = SKTexture(imageNamed: "small_dot")
    private var player = SKSpriteNode()
    private var testBox = SKSpriteNode()
    private var upgrade = SKSpriteNode()
    private var heli = SKSpriteNode()
    private var heliBullet = SKSpriteNode()
    private var heliBulletAdd = SKSpriteNode()
    private var heliBulletSub = SKSpriteNode()
    private var scoreboard = SKLabelNode()
    
    override func didMove(to view: SKView) {
        
        physicsWorld.contactDelegate = self
        
        scoreboard.position = CGPoint(x: -UIScreen.main.bounds.width + 100, y: UIScreen.main.bounds.height - 100)
        scoreboard.text = String(score)
        scoreboard.fontSize = 75
        scoreboard.fontColor = SKColor.white
        scoreboard.setScale(0.5)
        scoreboard.zPosition = 5
        self.addChild(scoreboard)
        
        //initializing player
        player = SKSpriteNode(imageNamed: "PlayerShip")
        player.name = "Player"
        player.position = CGPoint(x: 0, y: -400)
        player.zPosition = 2
        player.setScale(1)
        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.texture!.size())
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.categoryBitMask = CollisionType.player.rawValue
        player.physicsBody?.collisionBitMask = CollisionType.enemy.rawValue
        player.physicsBody?.contactTestBitMask = CollisionType.enemy.rawValue
        self.addChild(player)
        
        //test boxes for collsion testing
        //testBox.run(move2)
        
        timerMainWeapon(Level: mainWeaponLevel)
        timerHeliWeapon()
        //timerWingCannons()
        cooldownTimer()
        enemyTimer()
        getRandom()
        //heliTimer()
        helicopter()
        updateHeliWings()
        
        backgroundColor = SKColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1)
    }
    
    func didBegin (_ contact: SKPhysicsContact) {
        if(!cooldown){
            cooldown = true
            var body1 = SKPhysicsBody()
            var body2 = SKPhysicsBody()
            
            if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
                body1 = contact.bodyA
                body2 = contact.bodyB
            } else {
                body1 = contact.bodyB
                body2 = contact.bodyA
            }
            
            if body2.categoryBitMask == CollisionType.enemyBullet.rawValue && body1.categoryBitMask == CollisionType.player.rawValue {
                isHeliAlive = false
                body2.node?.removeFromParent()
                body1.node?.removeFromParent()
                isPlayerAlive = false
                runGameOver()
            }
            
            if body1.categoryBitMask == CollisionType.player.rawValue && body2.categoryBitMask == CollisionType.enemy.rawValue {
                if body1.node != nil {
                    //explosion
                }
                
                if body2.node != nil {
                    //explosion
                }
                
                body1.node?.removeFromParent()
                isPlayerAlive = false
                runGameOver()
            }
            
            if body1.categoryBitMask == CollisionType.bullet.rawValue && body2.categoryBitMask == CollisionType.enemy.rawValue {
                if body1.node != nil {
                    //explosion
                }
                
                if body2.node != nil {
                    //explosion
                }
                
                let index = findEnemy(body: body2)
                let tempEnemy = enemies[index]
                
                body1.node?.removeFromParent()
                
                if(tempEnemy.HP <= 0){
                    if body2.node?.name == "helicopter" {
                        isHeliAlive = false
                        upgradeObject()
                    }
                    score += tempEnemy.baseHP
                    scoreboard.text = String(score)
                    body2.node?.removeFromParent()
                    enemies.remove(at: index)
                }
                
                //runGameOver()
            }

            if body1.categoryBitMask == CollisionType.player.rawValue && body2.categoryBitMask == CollisionType.item.rawValue {
                body2.node?.removeFromParent()
                if(mainWeaponLevel < mainWeaponIntervals.count){
                    mainWeaponLevel += 4
                }
                MainWeaponTimer?.invalidate()
                MainWeaponTimer = Timer.scheduledTimer(timeInterval: mainWeaponIntervals[mainWeaponLevel], target: self, selector: #selector(self.mainWeapon), userInfo: nil, repeats: true)
            }
        }
    }
    
    func runGameOver(){
        let changeSceneAction = SKAction.run(changeScene)
        let waitAction = SKAction.wait(forDuration: 1)
        let changeSequence = SKAction.sequence([waitAction, changeSceneAction])
        self.run(changeSequence)
        changeScene()
    }
    
    func changeScene(){
        let sceneToMoveTo = MainMenuScene(size: self.size)
        sceneToMoveTo.scaleMode = .resizeFill
        let transition1 = SKTransition.fade(withDuration: 0.6)
        self.view!.presentScene(sceneToMoveTo, transition: transition1)
           
       }
    
    func findEnemy(body: SKPhysicsBody) -> Int {
        var isFound = false
        var count = 0
        while(!isFound){
            if(enemies[count].enemyNode == body.node!){
                enemies[count].HP -= mainWeaponDamage[mainWeaponLevel]
                return count
                isFound = true
            }
            count+=1
        }
        return 0
    }
    
    @objc func upgradeObject() {
        upgrade = SKSpriteNode(imageNamed: "upgradeCircle")
        upgrade.name = "upgrade"
        upgrade.position = CGPoint(x: 0, y: 0)
        upgrade.setScale(0.8)
        upgrade.zPosition = 1
        upgrade.physicsBody = SKPhysicsBody(texture: upgrade.texture!, size: upgrade.texture!.size())
        upgrade.physicsBody?.isDynamic = false
        upgrade.physicsBody?.isResting = true
        upgrade.physicsBody!.affectedByGravity = false
        upgrade.physicsBody?.categoryBitMask = CollisionType.item.rawValue
        upgrade.physicsBody?.collisionBitMask = CollisionType.player.rawValue
        upgrade.physicsBody?.contactTestBitMask = CollisionType.player.rawValue
        self.addChild(upgrade)
    }
    
    @objc func helicopter() {
        if isPlayerAlive && !gamePaused {
            
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            
            let helicopterPath = UIBezierPath()
            helicopterPath.move(to: CGPoint(x: 0, y: screenHeight + 10))
            helicopterPath.addLine(to: CGPoint(x: 0, y: screenHeight - 400))
            
            let heliPath2 = UIBezierPath()
            heliPath2.addArc(withCenter: CGPoint(x: 20, y: screenHeight - 400), radius: 20, startAngle: .pi, endAngle: 3 * .pi + 0.00000000000001, clockwise: true)
            heliPath2.addArc(withCenter: CGPoint(x: -20, y: screenHeight - 400), radius: 20, startAngle: 0, endAngle: 2 * .pi + 0.00000000000001, clockwise: false)
            
            let heliPath3 = UIBezierPath()
            heliPath3.move(to: CGPoint(x: 0, y: screenHeight - 400))
            heliPath3.addLine(to: CGPoint(x: screenWidth + 10, y: screenHeight - 400))
            isHeliAlive = true
            var tempHeli: Enemy = Enemy()
            let animate = SKAction.animate(with: [SKTexture(imageNamed: "helicopterPlus"), SKTexture(imageNamed: "helicopterCross")], timePerFrame: 2)
            let sequenceHelicopter = SKAction.sequence([animate])
            let helicopter = tempHeli.enemyNode
            tempHeli.HP = 1000
            tempHeli.baseHP = 1000
            helicopter.name = "helicopter"
            helicopter.setScale(0.8)
            helicopter.zPosition = 3
            helicopter.physicsBody = SKPhysicsBody(rectangleOf: helicopter.size)
            helicopter.physicsBody!.affectedByGravity = false
            helicopter.physicsBody!.allowsRotation = false
            helicopter.physicsBody!.categoryBitMask = CollisionType.enemy.rawValue
            helicopter.physicsBody!.collisionBitMask = CollisionType.player.rawValue
            helicopter.physicsBody!.contactTestBitMask = CollisionType.player.rawValue
            tempHeli.enemyNode = helicopter
            enemies.append(tempHeli)
            HelicopterOnScreen = helicopter
            self.addChild(helicopter)
            heli = helicopter
            helicopter.run(sequenceHelicopter, withKey: "moving")
            
            let movement = SKAction.follow(helicopterPath.cgPath, asOffset: false, orientToPath: false, speed: 75)
            let movement2 = SKAction.follow(heliPath2.cgPath, asOffset: false, orientToPath: false, speed: 75)
            let movement3 = SKAction.repeat(movement2, count: 3)
            let movement4 = SKAction.follow(heliPath3.cgPath, asOffset: false, orientToPath: false, speed: 75)
            let movementWait = SKAction.wait(forDuration: 0.5)
            //movement.timingMode = SKActionTimingMode.easeOut
            let deleteObj = SKAction.removeFromParent()
            let heliDead = SKAction.run({
                self.isHeliAlive = false
            })
            let sequence = SKAction.sequence([movement, movement3, movementWait, movement.reversed(), heliDead, deleteObj])
            helicopter.run(sequence)
        }
    }
    
    @objc func enemyBullet() {
        if isPlayerAlive && !gamePaused {
            heliBullet = SKSpriteNode(imageNamed: "sampleBullet")
            heliBullet.setScale(0.3)
            heliBullet.zPosition = 3
            heliBullet.physicsBody = SKPhysicsBody(rectangleOf: heliBullet.size)
            heliBullet.physicsBody!.affectedByGravity = false
            heliBullet.physicsBody?.isDynamic = false
            heliBullet.physicsBody!.categoryBitMask = CollisionType.enemyBullet.rawValue
            heliBullet.physicsBody!.collisionBitMask = CollisionType.player.rawValue
            heliBullet.physicsBody!.contactTestBitMask = CollisionType.player.rawValue
            self.addChild(heliBullet)
            
            heliBulletAdd = SKSpriteNode(imageNamed: "sampleBullet")
            heliBulletAdd.setScale(0.3)
            heliBulletAdd.zPosition = 3
            heliBulletAdd.physicsBody = SKPhysicsBody(rectangleOf: heliBulletAdd.size)
            heliBulletAdd.physicsBody!.affectedByGravity = false
            heliBulletAdd.physicsBody?.isDynamic = false
            heliBulletAdd.physicsBody!.categoryBitMask = CollisionType.enemyBullet.rawValue
            heliBulletAdd.physicsBody!.collisionBitMask = CollisionType.player.rawValue
            heliBulletAdd.physicsBody!.contactTestBitMask = CollisionType.player.rawValue
            self.addChild(heliBulletAdd)
            
            heliBulletSub = SKSpriteNode(imageNamed: "sampleBullet")
            heliBulletSub.setScale(0.3)
            heliBulletSub.zPosition = 3
            heliBulletSub.physicsBody = SKPhysicsBody(rectangleOf: heliBulletSub.size)
            heliBulletSub.physicsBody!.affectedByGravity = false
            heliBulletSub.physicsBody?.isDynamic = false
            heliBulletSub.physicsBody!.categoryBitMask = CollisionType.enemyBullet.rawValue
            heliBulletSub.physicsBody!.collisionBitMask = CollisionType.player.rawValue
            heliBulletSub.physicsBody!.contactTestBitMask = CollisionType.player.rawValue
            self.addChild(heliBulletSub)

            let slopeY = (HelicopterOnScreen.position.y - player.position.y)
            let slopeX = (HelicopterOnScreen.position.x - player.position.x)
            let slope = slopeY / slopeX
            
            //(y - player.position.y) = slope(x - player.position.x)
            //(y - py)/slope + px = x

            let theta = atan(HelicopterOnScreen.position.y / HelicopterOnScreen.position.x)
            let degreesToRadians = theta * (180 / .pi)
            let r = sqrt(pow(HelicopterOnScreen.position.x, 2) + pow(HelicopterOnScreen.position.y, 2))
            let tempAdd = (degreesToRadians + 20) * (.pi / 180)
            let tempSub = (degreesToRadians - 20) * (.pi / 180)
            let newX = r * cos(theta)
            let newY = r * sin(theta)
            let newXAdd = r * cos(tempAdd)
            let newYAdd = r * sin(tempAdd)
            let newXSub = r * cos(tempSub)
            let newYSub = r * sin(tempSub)
            
            let xGoal = ((-UIScreen.main.bounds.height - newY) / (slope)) + newX
            let addXGoal = ((-UIScreen.main.bounds.height - newYAdd) / (slope)) + newXAdd
            let subXGoal = ((-UIScreen.main.bounds.height - newYSub) / (slope)) + newXSub
            
            let heliBulletPath = UIBezierPath()
            let heliBulletPathAdd = UIBezierPath()
            let heliBulletPathSub = UIBezierPath()
            
            heliBulletPath.move(to: HelicopterOnScreen.position)
            heliBulletPath.addLine(to: CGPoint(x: xGoal, y: -UIScreen.main.bounds.height))
            
            heliBulletPathAdd.move(to: HelicopterOnScreen.position)
            heliBulletPathAdd.addLine(to: CGPoint(x: addXGoal, y: -UIScreen.main.bounds.height))
            
            heliBulletPathSub.move(to: HelicopterOnScreen.position)
            heliBulletPathSub.addLine(to: CGPoint(x: subXGoal, y: -UIScreen.main.bounds.height))
            
            let movement = SKAction.follow(heliBulletPath.cgPath, speed: 400)
            let movementAdd = SKAction.follow(heliBulletPathAdd.cgPath, speed: 400)
            let movementSub = SKAction.follow(heliBulletPathSub.cgPath, speed: 400)
            
            let deleteObj = SKAction.removeFromParent()
            let sequence = SKAction.sequence([movement, deleteObj])
            let sequenceAdd = SKAction.sequence([movementAdd, deleteObj])
            let sequenceSub = SKAction.sequence([movementSub, deleteObj])
            
            heliBullet.run(sequence)
            heliBulletAdd.run(sequenceAdd)
            heliBulletSub.run(sequenceSub)
        }
    }
    
    
    @objc func enemy() {
        if isPlayerAlive && !gamePaused {
            let enemyName = "enemy" + String(enemyIdentifier)
            var testEnemy: Enemy = Enemy()
            testEnemy.HP = 200
            testEnemy.baseHP = 200
            testBox = SKSpriteNode(imageNamed: "blueRectangle")
            testBox.name = enemyName
            testBox.setScale(0.2)
            testBox.zPosition = 2
            testBox.physicsBody = SKPhysicsBody(rectangleOf: testBox.size)
            testBox.physicsBody?.isDynamic = false
            testBox.physicsBody?.isResting = true
            testBox.physicsBody!.affectedByGravity = false
            testBox.physicsBody?.categoryBitMask = CollisionType.enemy.rawValue
            testBox.physicsBody?.collisionBitMask = CollisionType.player.rawValue
            testBox.physicsBody?.contactTestBitMask = CollisionType.player.rawValue
            testEnemy.enemyNode = testBox
            enemies.append(testEnemy)
            self.addChild(testEnemy.enemyNode)
            
            enemyIdentifier += 1
            
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            
            let testpath = UIBezierPath()
            testpath.move(to: CGPoint(x: screenWidth / 2, y: screenHeight + 100))
            testpath.addArc(withCenter: CGPoint(x: 0, y: 0), radius: screenWidth / 2, startAngle: 0, endAngle: (2 * .pi) + 0.00000000000001, clockwise: false)
            testpath.addLine(to: CGPoint(x: screenWidth / 2, y: -screenHeight - 100))

            let path = UIBezierPath()
            path.move(to: CGPoint(x: -screenWidth / 2, y: screenHeight + 100))
            //path.addCurve(to: CGPoint(x: screenWidth / 2, y: screenHeight + 100), controlPoint1: CGPoint(x: -screenWidth / 2, y: -500), controlPoint2: CGPoint(x: screenWidth / 2, y: -500))
            path.addCurve(to: CGPoint(x: 0, y: -screenHeight / 2), controlPoint1: CGPoint(x: -screenWidth / 2, y: -screenHeight / 2), controlPoint2: CGPoint(x: -screenWidth / 2, y: -screenHeight / 2))
            path.addCurve(to: CGPoint(x: screenWidth / 2, y: screenHeight + 100), controlPoint1: CGPoint(x: screenWidth / 2, y: -screenHeight / 2), controlPoint2: CGPoint(x: screenWidth / 2, y: -screenHeight / 2))
            
            let path1 = UIBezierPath()
            path1.move(to: CGPoint(x: -screenWidth * 2, y: screenHeight/2))
            path1.addCurve(to: CGPoint(x: -screenWidth/2, y: -screenHeight * 3), controlPoint1: CGPoint(x: -screenWidth/3, y: screenHeight/2), controlPoint2: CGPoint(x: -screenWidth/3, y: screenHeight/2))
            
            let path2 = UIBezierPath()
            path2.move(to: CGPoint(x: screenWidth * 2, y: screenHeight/2))
            path2.addCurve(to: CGPoint(x: screenWidth/2, y: -screenHeight * 3), controlPoint1: CGPoint(x: screenWidth/3, y: screenHeight/2), controlPoint2: CGPoint(x: screenWidth/3, y: screenHeight/2))
            
            let path3 = UIBezierPath()
            path3.move(to: CGPoint(x: -screenWidth / 2, y: screenHeight + 100))
            path3.addArc(withCenter: CGPoint(x: 0, y: 0), radius: screenWidth / 2, startAngle: .pi, endAngle: (3 * .pi), clockwise: true)
            path3.addLine(to: CGPoint(x: -screenWidth / 2, y: -screenHeight - 100))
            
            let path4 = UIBezierPath()
            path4.move(to: CGPoint(x: screenWidth / 2, y: screenHeight + 100))
            path4.addArc(withCenter: CGPoint(x: 0, y: 0), radius: screenWidth / 2, startAngle: 0, endAngle: (2 * .pi) + 0.00000000000001, clockwise: false)
            path4.addLine(to: CGPoint(x: screenWidth / 2, y: -screenHeight - 100))
            
            
            let move =  SKAction.follow(path.cgPath, speed: 400)
            let move1 = SKAction.follow(path1.cgPath, speed: 400)
            let move2 = SKAction.follow(path2.cgPath, speed: 400)
            let move3 = SKAction.follow(path3.cgPath, speed: 400)
            let move4 = SKAction.follow(path4.cgPath, speed: 400)
            let testmove = SKAction.follow(testpath.cgPath, speed: 300)
            
            let moves: [SKAction] = [move, move1, move2, move3, move4]
            
            let deleteObj = SKAction.removeFromParent()
            //moves[randomPath]
            let sequence = SKAction.sequence([moves[randomPath], deleteObj])
            testBox.run(sequence)
        }
    }
    
    @objc func mainWeapon() {
        if isPlayerAlive && !gamePaused {
            let mainPlayerBullet = SKSpriteNode(imageNamed: "sampleBullet")
            mainPlayerBullet.name = "Main Bullet"
            mainPlayerBullet.setScale(0.3)
            mainPlayerBullet.position = player.position
            mainPlayerBullet.zPosition = 1
            mainPlayerBullet.physicsBody = SKPhysicsBody(rectangleOf: mainPlayerBullet.size)
            mainPlayerBullet.physicsBody!.affectedByGravity = false
            mainPlayerBullet.physicsBody!.categoryBitMask = CollisionType.bullet.rawValue
            mainPlayerBullet.physicsBody!.collisionBitMask = CollisionType.enemy.rawValue
            mainPlayerBullet.physicsBody!.contactTestBitMask = CollisionType.enemy.rawValue
            self.addChild(mainPlayerBullet)
     
            let y = UIScreen.main.bounds.height - player.position.y
            // time = distance / speed
            let time = (y / 1000)
            let movement = SKAction.moveTo(y: UIScreen.main.bounds.height, duration: time)
            let deleteObj = SKAction.removeFromParent()
            let sequence = SKAction.sequence([movement, deleteObj])
            mainPlayerBullet.run(sequence)
        }
    }
    
    @objc func wingCannons() {
        if isPlayerAlive && !gamePaused {
            //left wing
            let wingBullet1 = SKSpriteNode(imageNamed: "sampleBullet")
            wingBullet1.name = "Left Wing Bullet"
            wingBullet1.setScale(0.2)
            wingBullet1.position = CGPoint(x: player.position.x - 40, y: player.position.y)
            wingBullet1.zPosition = 1
            wingBullet1.physicsBody = SKPhysicsBody(rectangleOf: wingBullet1.size)
            wingBullet1.physicsBody!.affectedByGravity = false
            wingBullet1.physicsBody!.categoryBitMask = CollisionType.bullet.rawValue
            wingBullet1.physicsBody!.collisionBitMask = CollisionType.enemy.rawValue
            wingBullet1.physicsBody!.contactTestBitMask = CollisionType.enemy.rawValue
            self.addChild(wingBullet1)
            
            //right wing
            let wingBullet2 = SKSpriteNode(imageNamed: "sampleBullet")
            wingBullet2.name = "Right Wing Bullet"
            wingBullet2.setScale(0.2)
            wingBullet2.position = CGPoint(x: player.position.x + 40, y: player.position.y)
            wingBullet2.zPosition = 1
            wingBullet2.physicsBody = SKPhysicsBody(rectangleOf: wingBullet2.size)
            wingBullet2.physicsBody!.affectedByGravity = false
            wingBullet2.physicsBody!.categoryBitMask = CollisionType.bullet.rawValue
            wingBullet2.physicsBody!.collisionBitMask = CollisionType.enemy.rawValue
            wingBullet2.physicsBody!.contactTestBitMask = CollisionType.enemy.rawValue
            self.addChild(wingBullet2)
            
            let movement = SKAction.moveTo(y: player.position.y + 1500, duration: 1.2)
            let deleteObj = SKAction.removeFromParent()
            let sequence = SKAction.sequence([movement, deleteObj])
            wingBullet1.run(sequence)
            wingBullet2.run(sequence)
        }
    }
    
    func touchDown(atPoint pos : CGPoint) {
        //movement code
        var tempPos : CGPoint = pos
        tempPos.y += 50
        let movementSpeed = 3000.0
        let x = tempPos.x - player.position.x
        let y = tempPos.y - player.position.y
        let distance = sqrt(x * x + y * y)
        
        player.run(SKAction.move(to: tempPos, duration: Double(distance) / movementSpeed))
    
    }
    
    func getRandom() {
        RandomTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { Timer in
            self.randomPath = Int.random(in: 0..<5) })
    }
    
    //timers for the player's weapons
    func timerMainWeapon(Level: Int) {
        MainWeaponTimer = Timer.scheduledTimer(timeInterval: mainWeaponIntervals[Level], target: self, selector: #selector(self.mainWeapon), userInfo: nil, repeats: true)
    }
    
    func heliTimer() {
        HeliTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.helicopter), userInfo: nil, repeats: true)
    }
    
    func timerHeliWeapon() {
        HeliWeaponTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { Timer in
            if (self.isHeliAlive){
                self.enemyBullet()
            }
        })
    }
    
    func timerWingCannons() {
        WingCannonsTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.wingCannons), userInfo: nil, repeats: true)
    }
    
    func cooldownTimer() {
        CooldownTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { Timer in
            self.cooldown = false })
    }
    
    func enemyTimer(){
        EnemyTimer = Timer.scheduledTimer(timeInterval: 0.6, target: self, selector: #selector(self.enemy), userInfo: nil, repeats: true)
    }
    
    func updateHeliWings(){
        HeliSpriteTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true, block: { Timer in
            let animate = SKAction.animate(with: [SKTexture(imageNamed: "helicopterPlus"), SKTexture(imageNamed: "helicopterCross")], timePerFrame: 0.15)
            let sequenceHelicopter = SKAction.sequence([animate])
            self.heli.run(sequenceHelicopter, withKey: "moving")
        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func update(_ currentTime: TimeInterval) {
    }
    
}

struct Enemy {
    var enemyNode: SKSpriteNode = SKSpriteNode(imageNamed: "blueRectangle")
    var HP: Int = 0
    var baseHP: Int = 0
}
