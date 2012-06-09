//
//  HelloWorldLayer.m
//  TiledChipmunk
//
//  Created by Andy Korth on 6/7/12.
//  Copyright Howling Moon Software 2012. All rights reserved.
//


// Import the interfaces
#import "HelloWorldLayer.h"

#import "ChipmunkAutoGeometry.h"
#import "ChipmunkGLRenderBufferSampler.h"
#import "ChipmunkDebugNode.h"

// HelloWorldLayer implementation
@implementation HelloWorldLayer{
    
    ChipmunkSpace *space;
    ChipmunkBody *targetPointBody;
    ChipmunkBody *playerBody;
	
		//NSMutableArray* chipmunkSprites;
}



@synthesize tileMap = _tileMap;
@synthesize background = _background;
@synthesize meta = _meta;

@synthesize player = _player;

-(void)spriteMoveFinished:(id)sender {
    CCSprite *sprite = (CCSprite *)sender;
    [self removeChild:sprite cleanup:YES];
}



-(void)setViewpointCenter:(CGPoint) position {
    
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    
    int x = MAX(position.x, winSize.width / 2);
    int y = MAX(position.y, winSize.height / 2);
    x = MIN(x, (_tileMap.mapSize.width * _tileMap.tileSize.width) 
            - winSize.width / 2);
    y = MIN(y, (_tileMap.mapSize.height * _tileMap.tileSize.height) 
            - winSize.height/2);
    // clamped to inset edges
    CGPoint actualPosition = ccp(x, y);
    
    CGPoint centerOfView = ccp(winSize.width/2, winSize.height/2);
    CGPoint viewPoint = ccpSub(centerOfView, actualPosition);
    self.position = viewPoint;
    
}



+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

-(void) registerWithTouchDispatcher
{
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self 
                                                     priority:0 swallowsTouches:YES];
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	return YES;
}

- (CGPoint)tileCoordForPosition:(CGPoint)position {
    int x = position.x / _tileMap.tileSize.width;
    int y = ((_tileMap.mapSize.height * _tileMap.tileSize.height) - position.y) / _tileMap.tileSize.height;
    return ccp(x, y);
}


-(void)setPlayerPosition:(CGPoint)position {
    CGPoint tileCoord = [self tileCoordForPosition:position];
    int tileGid = [_meta tileGIDAt:tileCoord];
    if (tileGid) {
        NSDictionary *properties = [_tileMap propertiesForGID:tileGid];
        if (properties) {
            NSString *collision = [properties valueForKey:@"Collidable"];
            if (collision && [collision compare:@"True"] == NSOrderedSame) {
                return;
            }
        }
    }
   
    //_player.position = position;
}

-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    
    CGPoint touchLocation = [touch locationInView: [touch view]];		
    touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];
    
    CGPoint playerPos = _player.position;
    CGPoint diff = ccpSub(touchLocation, playerPos);
    if (abs(diff.x) > abs(diff.y)) {
        if (diff.x > 0) {
            playerPos.x += _tileMap.tileSize.width;
        } else {
            playerPos.x -= _tileMap.tileSize.width; 
        }    
    } else {
        if (diff.y > 0) {
            playerPos.y += _tileMap.tileSize.height;
        } else {
            playerPos.y -= _tileMap.tileSize.height;
        }
    }
    
    if (playerPos.x <= (_tileMap.mapSize.width * _tileMap.tileSize.width) &&
        playerPos.y <= (_tileMap.mapSize.height * _tileMap.tileSize.height) &&
        playerPos.y >= 0 &&
        playerPos.x >= 0 ) 
    {
        [self setPlayerPosition:playerPos];
    }
    
    targetPointBody.pos = touchLocation;
}

- (ChipmunkBody*)makeBox:(int)i y:(int)y x:(int)x
{
    float mass = 0.3f;
    float size = 18.0f;
    float dist = 50.0f;
    
    ChipmunkBody* body = [ChipmunkBody bodyWithMass:mass andMoment:cpMomentForBox(mass, size, size)];
    ChipmunkShape* box = [ChipmunkPolyShape boxWithBody:body width: size height: size];
    box.friction = 1.0f;
    
    [space add:box];
    [space add:body];
    
    body.pos = cpv(x - (dist*2) + (i % 4) * dist, y - (dist*2) +( i / 4) * dist);
    
    //create joints to simulate a top-down linear friction
    // We'll need a set of joints like this on anything we want to have our top-down friction.
    ChipmunkPivotJoint* pj = [space add: [ChipmunkPivotJoint pivotJointWithBodyA:[space staticBody] bodyB:body anchr1:cpvzero anchr2:cpvzero]];
    pj.maxForce = 1000.0f; // emulate linear friction
    pj.maxBias = 0; // disable joint correction, don't pull it towards the anchor.
    
    // Then use a gear to fake an angular friction (slow rotating boxes)
    ChipmunkGearJoint* gj = [space add: [ChipmunkGearJoint gearJointWithBodyA:[space staticBody] bodyB:body phase:0.0f ratio:1.0f]];
    
    gj.maxForce = 5000.0f;
    gj.maxBias = 0.0f;
	return body;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {
		
		// Setup the space. We won't set a gravity vector since this is top-down
		space = [[ChipmunkSpace alloc] init];
		
		
		self.isTouchEnabled = YES;
		
		self.tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"andy.tmx"];
		self.background = [_tileMap layerNamed:@"Background"];
		
		[self addChild:_tileMap z:-1];
		
		CCTMXObjectGroup *objects = [_tileMap objectGroupNamed:@"Objects"];
		NSAssert(objects != nil, @"'Objects' object group not found");
		NSMutableDictionary *spawnPoint = [objects objectNamed:@"SpawnPoint"];        
		NSAssert(spawnPoint != nil, @"SpawnPoint object not found");
		int x = [[spawnPoint valueForKey:@"x"] intValue];
		int y = [[spawnPoint valueForKey:@"y"] intValue];
		
		self.meta = [_tileMap layerNamed:@"Meta"];
		_meta.visible = NO;
		
		self.player = [ChipmunkSprite spriteWithFile:@"chipmunkMan.png"];
		_player.position = ccp(x, y);
		[self addChild:_player]; 
		
		// Add a ChipmunkDebugNode to draw the space.
		ChipmunkDebugNode *debugNode = [ChipmunkDebugNode debugNodeForChipmunkSpace:space];
		[self addChild:debugNode];
				
		{
				
				// set up the player body and shape
				float playerMass = 1.0f;
				float playerRadius = 13.0f;
				
				playerBody = [space add:[ChipmunkBody bodyWithMass:playerMass andMoment:cpMomentForCircle(playerMass, 0.0, playerRadius, cpvzero)]];
				playerBody.pos = ccp(x,y);
				_player.chipmunkBody = playerBody;
				 
				ChipmunkShape *playerShape = [space add:[ChipmunkCircleShape circleWithBody:playerBody radius:playerRadius offset:cpvzero]];
				playerShape.friction = 1.0;

				// now create a control body. We'll move this around and use joints to do the actual player 
				// motion based on the control body
				
				targetPointBody = [[ChipmunkBody alloc] initStaticBody];
				targetPointBody.pos = ccp(x,y); // line them up so the initial position is right
				
				ChipmunkPivotJoint* joint = [ChipmunkPivotJoint pivotJointWithBodyA:targetPointBody bodyB:playerBody anchr1:cpvzero anchr2:cpvzero];

				// max bias controls the maximum speed that a joint can be corrected at. So that means 
				// the player body won't be forced towards the control at a speed higher than this.
				// Thus it's essentially the speed of the player's motion
				joint.maxBias = 85.0f;
				
				// limiting the force will prevent us from crazily pushing huge piles
				// of heavy things. and give us a sort of top-down friction.
				joint.maxForce = 3000.0f; 
				
				[space add: joint];
				
		}
		
		// add some crates, it's not a video game without crates!
		for(int i=0; i<16; i++){
			
			ChipmunkBody* box = [self makeBox:i y:y x:x];
			
		}
						
		[self setViewpointCenter:_player.position];
		
		// schedule updates, whihc also steps the physics space:
		[self scheduleUpdate];
	}
    
	return self;
}

-(void)update:(ccTime)dt
{
    
	// Update the physics
	ccTime fixed_dt = [CCDirector sharedDirector].animationInterval;
	[space step:fixed_dt];
    
    //update camera
    [self setViewpointCenter:playerBody.pos];
    
}


// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	self.tileMap = nil;
	self.background = nil;
	self.meta = nil;
	self.player = nil;
    
	// don't forget to call "super dealloc"
	[super dealloc];
}
@end
