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
    
    var gamePaused:Bool = false
    var isPlayerAlive:Bool = true
    var lastUpdateTime: CFTimeInterval = 0
    var timer: Timer?
    var CooldownTimer: Timer?
    var MainWeaponTimer: Timer?
    var WingCannonsTimer: Timer?
    var EnemyTimer: Timer?
    var RandomTimer: Timer?
    
    var mainWeaponLevel = 0
    let mainWeaponIntervals = [0.425, 0.4, 0.375, 0.35, 0.325, 0.3, 0.275, 0.25, 0.225, 0.2]
    let mainWeaponDamage = [100, 125, 150, 175, 200, 225, 250, 275, 300, 325]
    var cooldown = false
    var randomPath = 0
    var enemyIdentifier = 0
    
    enum CollisionType: UInt32 {
        case none = 0
        case player = 1
        case item = 2
        case bullet = 4
        case enemy = 8
    }
    
    let spaceShipTexture = SKTexture(imageNamed: "small_dot")
    private var player = SKSpriteNode()
    private var testBox = SKSpriteNode()
    private var upgrade = SKSpriteNode()
    
    override func didMove(to view: SKView) {
        
        physicsWorld.contactDelegate = self
        
        
        //initializing player
        player = SKSpriteNode(imageNamed: "small_dot")
        player.name = "Player"
        player.position = CGPoint(x: 0, y: -400)
        player.zPosition = 2
        player.setScale(0.8)
        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.texture!.size())
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.categoryBitMask = CollisionType.player.rawValue
        player.physicsBody?.collisionBitMask = CollisionType.enemy.rawValue
        player.physicsBody?.contactTestBitMask = CollisionType.enemy.rawValue
        self.addChild(player)
        
        //test boxes for collsion testing
        //testBox.run(move2)
        
        upgrade = SKSpriteNode(imageNamed: "upgradeCircle")
        upgrade.name = "upgrade"
        upgrade.position = CGPoint(x: 200, y: 400)
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
        
        timerMainWeapon(Level: mainWeaponLevel)
        //timerWingCannons()
        cooldownTimer()
        enemyTimer()
        getRandom()
        
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
            
            if body1.categoryBitMask == CollisionType.player.rawValue && body2.categoryBitMask == CollisionType.enemy.rawValue {
                if body1.node != nil {
                    //explosion
                }
                
                if body2.node != nil {
                    //explosion
                }
                
                //body1.node?.removeFromParent()
                //body2.node?.removeFromParent()
                //runGameOver()
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
                    body2.node?.removeFromParent()
                    enemies.remove(at: index)
                }
                //body2.node?.removeFromParent()
                //runGameOver()
            }

            if body1.categoryBitMask == CollisionType.player.rawValue && body2.categoryBitMask == CollisionType.item.rawValue {
                body2.node?.removeFromParent()
                if(mainWeaponLevel < mainWeaponIntervals.count){
                    mainWeaponLevel += 8
                }
                MainWeaponTimer?.invalidate()
                MainWeaponTimer = Timer.scheduledTimer(timeInterval: mainWeaponIntervals[mainWeaponLevel], target: self, selector: #selector(self.mainWeapon), userInfo: nil, repeats: true)
            }
        }
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
    
    @objc func enemy(){
        if isPlayerAlive && !gamePaused {
            let enemyName = "enemy" + String(enemyIdentifier)
            var testEnemy: Enemy = Enemy()
            testEnemy.HP = 200
            testBox = SKSpriteNode(imageNamed: "blueRectangle")
            testBox.name = enemyName
            testBox.position = CGPoint(x: 100, y: 300)
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
            
            let screenWidth = UIScreen.main.bounds.width/2
            let screenHeight = UIScreen.main.bounds.height/2

            let path = UIBezierPath()
            path.move(to: CGPoint(x: -screenWidth * 2, y: -screenHeight * 2))
            path.addLine(to: CGPoint(x: screenWidth * 2, y: screenHeight * 2))
            
            let path1 = UIBezierPath()
            path1.move(to: CGPoint(x: -screenWidth, y: screenHeight/2))
            path1.addCurve(to: CGPoint(x: -screenWidth/2, y: -screenHeight * 3), controlPoint1: CGPoint(x: -screenWidth/3, y: screenHeight/2), controlPoint2: CGPoint(x: -screenWidth/3, y: screenHeight/2))
            
            let path2 = UIBezierPath()
            path2.move(to: CGPoint(x: screenWidth, y: screenHeight/2))
            path2.addCurve(to: CGPoint(x: screenWidth/2, y: -screenHeight * 3), controlPoint1: CGPoint(x: screenWidth/3, y: screenHeight/2), controlPoint2: CGPoint(x: screenWidth/3, y: screenHeight/2))
            
            let move =  SKAction.follow(path.cgPath, speed: 300)
            let move1 = SKAction.follow(path1.cgPath, speed: 300)
            let move2 = SKAction.follow(path2.cgPath, speed: 300)
            
            let moves: [SKAction] = [move, move1, move2]
            
            let deleteObj = SKAction.removeFromParent()
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
            
            let movement = SKAction.moveTo(y: player.position.y + 1500, duration: 1)
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
            self.randomPath = Int.random(in: 0..<3) })
    }
    
    //timers for the player's weapons
    func timerMainWeapon(Level: Int) {
        MainWeaponTimer = Timer.scheduledTimer(timeInterval: mainWeaponIntervals[Level], target: self, selector: #selector(self.mainWeapon), userInfo: nil, repeats: true)
    }
    
    func timerWingCannons() {
        WingCannonsTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.wingCannons), userInfo: nil, repeats: true)
    }
    
    func cooldownTimer() {
        CooldownTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { Timer in
            self.cooldown = false })
    }
    
    func enemyTimer(){
        EnemyTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.enemy), userInfo: nil, repeats: true)
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

struct Enemy{
    var enemyNode: SKSpriteNode = SKSpriteNode(imageNamed: "blueRectangle")
    var HP: Int = 0
}


