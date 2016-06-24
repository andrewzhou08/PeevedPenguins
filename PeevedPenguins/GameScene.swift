import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    /* Game object connections */
    var catapultArm: SKSpriteNode!
    var catapult: SKSpriteNode!
    var levelNode: SKNode!
    var cameraTarget: SKNode?
    var restartButton:MSButtonNode!
    var cantileverNode:SKSpriteNode!
    var touchNode: SKSpriteNode!
    /* Physics helpers */
    var touchJoint: SKPhysicsJointSpring?
    var penguinJoint: SKPhysicsJointPin?
    
    var waitingPenguins: SKNode!
    var timeBeforeReload = 0
    var penguin1: SKNode?
    var penguin2: SKNode?
    var penguin3: SKNode?
    
    var gameOver: SKLabelNode!
    var scoreLabel: SKLabelNode!
    var highScoreLabel: SKLabelNode!
    
    var numLives = 3
    var isGameOver = false
    var isPowerPenguin = false
    var score = 0
    var highScore = 0
    var numNeededSeals = 3
    var sealsKilled = 0
    var level = 1
    var scoreAfterLevelCompletion = 0
    
    
    override func didMoveToView(view: SKView) {
        /* Set reference to catapultArm node */
        catapultArm = childNodeWithName("catapultArm") as! SKSpriteNode
        catapult = childNodeWithName("catapult") as! SKSpriteNode
        levelNode = childNodeWithName("//levelNode")
        restartButton = childNodeWithName("//restartButton") as! MSButtonNode
        cantileverNode = childNodeWithName("cantileverNode") as! SKSpriteNode
        touchNode = childNodeWithName("touchNode") as! SKSpriteNode
        waitingPenguins = childNodeWithName("waitingPenguins")
        gameOver = childNodeWithName("//gameOver") as! SKLabelNode
        scoreLabel = childNodeWithName("//scoreLabel") as! SKLabelNode
        highScoreLabel = childNodeWithName("//highScoreLabel") as! SKLabelNode
        
        scoreLabel.text = String(score)
        highScoreLabel.text = "High Score: \(highScore)"
        
        penguin1 = waitingPenguins.childNodeWithName("waitingPenguin1")!
        penguin2 = waitingPenguins.childNodeWithName("waitingPenguin2")!
        penguin3 = waitingPenguins.childNodeWithName("waitingPenguin3")!
        
        
        physicsWorld.contactDelegate = self
        gameOver.removeFromParent()
        
        /* Load Level 1 */
        let resourcePath = NSBundle.mainBundle().pathForResource("Level1", ofType: "sks")
        let newLevel = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePath!))
        levelNode.addChild(newLevel)
        
        /* Create catapult arm physics body of type alpha */
        let catapultArmBody = SKPhysicsBody (texture: catapultArm!.texture!, size: catapultArm.size)
        
        /* Set mass, needs to be heavy enough to hit the penguin with solid force */
        catapultArmBody.mass = 0.5
        
        /* Apply gravity to catapultArm */
        catapultArmBody.affectedByGravity = false
        
        /* Improves physics collision handling of fast moving objects */
        catapultArmBody.usesPreciseCollisionDetection = true
        
        /* Assign the physics body to the catapult arm */
        catapultArm.physicsBody = catapultArmBody
        
        /* Pin joint catapult and catapult arm */
        let catapultPinJoint = SKPhysicsJointPin.jointWithBodyA(catapult.physicsBody!, bodyB: catapultArm.physicsBody!, anchor: CGPoint(x:210 ,y:105))
        physicsWorld.addJoint(catapultPinJoint)
        
        /* Spring joint catapult arm and cantilever node */
        let catapultSpringJoint = SKPhysicsJointSpring.jointWithBodyA(catapultArm.physicsBody!, bodyB: cantileverNode.physicsBody!, anchorA: catapultArm.position + CGPoint(x:15, y:30), anchorB: cantileverNode.position)
        physicsWorld.addJoint(catapultSpringJoint)
        
        /* Make this joint a bit more springy */
        catapultSpringJoint.frequency = 1.5
        
        restartButton.selectedHandler = {
            self.numLives = 3
            let skView = self.view as SKView!
            self.isGameOver = false
            let scene = GameScene(fileNamed:"GameScene") as GameScene!
            scene.scaleMode = .AspectFit
            skView.showsPhysics = true
            skView.showsDrawCount = true
            skView.showsFPS = false
            skView.presentScene(scene)
            self.gameOver.removeFromParent()
            scene.levelNode.removeAllChildren()
            let resourcePath = NSBundle.mainBundle().pathForResource("Level\(self.level)", ofType: "sks")
            let newLevel = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePath!))
            scene.levelNode.addChild(newLevel)
            scene.level = self.level
            scene.highScore = self.highScore
            scene.score = self.scoreAfterLevelCompletion
            scene.scoreAfterLevelCompletion = self.scoreAfterLevelCompletion
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if(isGameOver) { return }
        /* Add a new penguin to the scene */
        /* There will only be one touch as multi touch is not enabled by default */
        for touch in touches {
            let location = touch.locationInNode(self)
            let touchedNode = nodeAtPoint(location)
            if touchedNode.name == "catapultArm" {
                touchNode.position = location
                touchJoint = SKPhysicsJointSpring.jointWithBodyA(touchNode.physicsBody!, bodyB: catapultArm.physicsBody!, anchorA: location, anchorB: location)
                physicsWorld.addJoint(touchJoint!)
                
                
                
                /* Add a new penguin to the scene */
                var resourcePath = NSBundle.mainBundle().pathForResource("Penguin", ofType: "sks")
                var penguin = MSReferenceNode(URL: NSURL (fileURLWithPath: resourcePath!))
                isPowerPenguin = false
               
                if(numLives == 3) {
                    isPowerPenguin = true
                    resourcePath = NSBundle.mainBundle().pathForResource("PowerPenguin", ofType: "sks")
                    penguin = MSReferenceNode(URL: NSURL (fileURLWithPath: resourcePath!))
                }
                
                addChild(penguin)
                
                /* Position penguin in the catapult bucket area */
                penguin.avatar.position = catapultArm.position + CGPoint(x: 32, y: 50)
                
                /* Improves physics collision handling of fast moving objects */
                penguin.avatar.physicsBody?.usesPreciseCollisionDetection = true
                
                /* Setup pin joint between penguin and catapult arm */
                penguinJoint = SKPhysicsJointPin.jointWithBodyA(catapultArm.physicsBody!, bodyB: penguin.avatar.physicsBody!, anchor: penguin.avatar.position)
                physicsWorld.addJoint(penguinJoint!)
                
                camera?.removeAllActions()
                
                /* Set camera to follow penguin */
                cameraTarget = penguin.avatar
                
                if(numLives == 3) {
                    penguin1?.removeFromParent()
                } else if(numLives == 2) {
                    penguin2?.removeFromParent()
                } else {
                    penguin3?.removeFromParent()
                }
            }
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if(isGameOver) { return }
        /* Called when a touch moved */
        
        /* There will only be one touch as multi touch is not enabled by default */
        for touch in touches {
            let location = touch.locationInNode(self)
            touchNode.position = location
            
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if(isGameOver) { return }
        /* Called when a touch ended */
        if let touchJoint = touchJoint { physicsWorld.removeJoint(touchJoint) }
        if let penguinJoint = penguinJoint {physicsWorld.removeJoint(penguinJoint)}
        numLives -= 1
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        scoreLabel.text = String(score)
        highScoreLabel.text = "High Score: \(highScore)"
        
        if(score > highScore) { highScore = score }
        
        if let cameraTarget = cameraTarget {
            camera?.position = CGPoint(x: cameraTarget.position.x, y: camera!.position.y)
            
            camera?.position.x.clamp(283, 677)
            
            if cameraTarget.physicsBody?.joints.count == 0 && cameraTarget.physicsBody?.velocity.length() < 0.18 {
                
                cameraTarget.removeFromParent()
                
                /* Reset catapult arm */
                catapultArm.physicsBody?.velocity = CGVector(dx:0, dy:0)
                catapultArm.physicsBody?.angularVelocity = 0
                catapultArm.zRotation = 0
                
                /* Reset camera */
                let cameraReset = SKAction.moveTo(CGPoint(x:284, y:camera!.position.y), duration: 1.5)
                let cameraDelay = SKAction.waitForDuration(0.5)
                let cameraSequence = SKAction.sequence([cameraDelay,cameraReset])
                
                camera?.runAction(cameraSequence)
                
                if(numLives <= 0) {
                    numLives = 3
                    camera?.addChild(gameOver)
                    isGameOver = true
                }
            }
        }
        
        if(sealsKilled >= numNeededSeals) {
            level += 1
            if(level > 5) { //3 is max level
                level = 5
            }
            sealsKilled = 0
            cameraTarget?.removeFromParent()
            numLives = 3
            penguin1!.removeFromParent()
            penguin2!.removeFromParent()
            penguin3!.removeFromParent()
            
            addChild(penguin1!)
            addChild(penguin2!)
            addChild(penguin3!)
            loadNextLevel()
        }
        
        if(level == 1) {
            numNeededSeals = 3
        } else if(level == 2) {
            numNeededSeals = 4
        } else if(level == 3) {
            numNeededSeals = 5
        } else if(level == 4) {
            numNeededSeals = 6
        } else {
            numNeededSeals = 4
        }
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        /* Physics contact delegate implementation */
        
        /* Get references to the bodies involved in the collision */
        let contactA:SKPhysicsBody = contact.bodyA
        let contactB:SKPhysicsBody = contact.bodyB
        
        /* Get references to the physics body parent SKSpriteNode */
        let nodeA = contactA.node as! SKSpriteNode
        let nodeB = contactB.node as! SKSpriteNode
        
        /* Check if either physics bodies was a seal */
        if contactA.categoryBitMask == 2 || contactB.categoryBitMask == 2 || contactA.categoryBitMask == 4 || contactB.categoryBitMask == 4 {
            
            if(isPowerPenguin) {
                if(contactA.categoryBitMask == 1) {
                    nodeA.setScale(CGFloat(3))
                } else if(contactB.categoryBitMask == 1) {
                    nodeB.setScale(CGFloat(3))
                }
            }
            
            /* Was the collision more than a gentle nudge? */
            if contact.collisionImpulse > 0.8 {
                
                /* Kill Seal(s) */
                if contactA.categoryBitMask == 2 {
                    dieSeal(nodeA)
                    score += 5000
                    sealsKilled += 1
                }
                if contactB.categoryBitMask == 2 {
                    dieSeal(nodeB)
                    score += 5000
                    sealsKilled += 1
                }
            }
            if contact.collisionImpulse > 10.0 {
                /*Destroy Block(s)*/
                if contactA.categoryBitMask == 4
                {
                    destroyBlock(nodeA)
                    score += 1000
                }
                if contactB.categoryBitMask == 4
                {
                    destroyBlock(nodeB)
                    score += 1000
                }
            }
        }
    }
    
    func dieSeal(node: SKNode) {
        /* Seal death*/
        /* Load our particle effect */
        let particles = SKEmitterNode(fileNamed: "SealDeath")!
        
        /* Convert node location (currently inside Level 1, to scene space) */
        particles.position = convertPoint(node.position, fromNode: node)
        
        /* Restrict total particles to reduce runtime of particle */
        particles.numParticlesToEmit = 25
        
        /* Add particles to scene */
        addChild(particles)
        
        let sealDeath = SKAction.runBlock({
            node.removeFromParent()
        })
        self.runAction(sealDeath)
        
        let sealSFX = SKAction.playSoundFileNamed("sfx_seal", waitForCompletion: false)
        self.runAction(sealSFX)
        
    }
    
    func destroyBlock(node: SKNode) {
        let particles = SKEmitterNode(fileNamed: "BlockDestruction")!
        particles.position = convertPoint(node.position, fromNode: node)
        particles.numParticlesToEmit = 25
        addChild(particles)
        
        let blockDestruction = SKAction.runBlock({
            node.removeFromParent()
        })
        self.runAction(blockDestruction)
    }
    
    func loadNextLevel() {
        levelNode.removeAllChildren()
        let resourcePath = NSBundle.mainBundle().pathForResource("Level\(level)", ofType: "sks")
        let newLevel = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePath!))
        levelNode.addChild(newLevel)
        scoreAfterLevelCompletion = score
    }
}