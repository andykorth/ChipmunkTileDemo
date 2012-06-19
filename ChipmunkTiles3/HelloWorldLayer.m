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
#import "ChipmunkPointCloudSampler.h"

// HelloWorldLayer implementation
@implementation HelloWorldLayer{
    
    ChipmunkSpace *space;
    ChipmunkBody *targetPointBody;
    ChipmunkBody *playerBody;
	
	//NSMutableArray* chipmunkSprites;
}

bool isTouching;
CGPoint _lastTouchLocation;

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
    
    // clamp the position with MIN and MAX to be within inset edges of the map boundary
    int x = MAX(position.x, winSize.width / 2);
    int y = MAX(position.y, winSize.height / 2);
    x = MIN(x, (_tileMap.mapSize.width * _tileMap.tileSize.width) - winSize.width / 2);
    y = MIN(y, (_tileMap.mapSize.height * _tileMap.tileSize.height)  - winSize.height/2);
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

- (CGPoint)tileCoordForPosition:(CGPoint)position {
    int x = position.x / _tileMap.tileSize.width;
    int y = ((_tileMap.mapSize.height * _tileMap.tileSize.height) - position.y) / _tileMap.tileSize.height;
    return ccp(x, y);
}



-(void) registerWithTouchDispatcher
{
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self 
                                                     priority:0 swallowsTouches:YES];
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    isTouching = true;
    _lastTouchLocation = [touch locationInView: [touch view]];
	return YES;
}

-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    // touch ended, so stop updating the targetPointBody position.
    isTouching = false;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
     _lastTouchLocation = [touch locationInView: [touch view]];
}

- (ChipmunkBody*)makeBoxAtX:(int)x y:(int)y
{
    float mass = 0.3f;
    float size = 27.0f;
    
    ChipmunkBody* body = [ChipmunkBody bodyWithMass:mass andMoment:cpMomentForBox(mass, size, size)];
     
    ChipmunkSprite * boxSprite = [ChipmunkSprite spriteWithFile:@"crate.png"];
    boxSprite.chipmunkBody = body;
    boxSprite.position = cpv(x,y);
    
    ChipmunkShape* boxShape = [ChipmunkPolyShape boxWithBody:body width: size height: size];
    boxShape.friction = 1.0f;
    
    [space add:boxShape];
    [space add:body];
    [self addChild:boxSprite];
    
    //create joints to simulate a top-down linear friction
    // We'll need a set of joints like this on anything we want to have our top-down friction.
    ChipmunkPivotJoint* pj = [space add: [ChipmunkPivotJoint pivotJointWithBodyA:
                                          [space staticBody] bodyB:body anchr1:cpvzero anchr2:cpvzero]];
    
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
		
        isTouching = false;
		
		self.isTouchEnabled = YES;
		
		self.tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"TileMap.tmx"];
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
		
		
		// Add a ChipmunkDebugNode to draw the space.
		ChipmunkDebugNode *debugNode = [ChipmunkDebugNode debugNodeForChipmunkSpace:space];
		[self addChild:debugNode];
				
		{
				
				// set up the player body and shape
				float playerMass = 1.0f;
				float playerRadius = 13.0f;
				
				playerBody = [space add:[ChipmunkBody bodyWithMass:playerMass andMoment:INFINITY]];
				
				self.player = [ChipmunkSprite spriteWithFile:@"chipmunkMan.png"];
				self.player.chipmunkBody = playerBody;
				playerBody.pos = ccp(x,y);
            
                [self addChild:self.player];
				
				ChipmunkShape *playerShape = [space add:[ChipmunkCircleShape circleWithBody:playerBody radius:playerRadius offset:cpvzero]];
				playerShape.friction = 0.1;

				// now create a control body. We'll move this around and use joints to do the actual player 
				// motion based on the control body
				
				targetPointBody = [[ChipmunkBody alloc] initStaticBody];
				targetPointBody.pos = ccp(x,y); // make the player's target destination start at the same place the player.
				
				ChipmunkPivotJoint* joint = [space add:[ChipmunkPivotJoint pivotJointWithBodyA:targetPointBody bodyB:playerBody anchr1:cpvzero anchr2:cpvzero]];

				// max bias controls the maximum speed that a joint can be corrected at. So that means 
				// the player body won't be forced towards the control at a speed higher than this.
				// Thus it's essentially the speed of the player's motion
				joint.maxBias = 200.0f;
				
				// limiting the force will prevent us from crazily pushing huge piles
				// of heavy things. and give us a sort of top-down friction.
				joint.maxForce = 3000.0f; 
		}
        
        {            
            int tileCountW = _meta.layerSize.width;
            int tileCountH = _meta.layerSize.height;
			
			// Create a sampler using a block that samples the tilemap in tile coordinates.
			ChipmunkBlockSampler *sampler = [[ChipmunkBlockSampler alloc] initWithBlock:^(cpVect point){
				// Clamp the point so that samples outside the tilemap bounds will sample the edges.
				// See below for why 0.5 is used here.
				point = cpBBClampVect(cpBBNew(0.5, 0.5, tileCountW - 0.5, tileCountH - 0.5), point);
				
				// Alternatively, you could wrap the coordinates around, or have a constant border value.
				
				// The samples will always be at tile centers.
				// So we just need to truncate to an integer to convert to tile coordinates.
				int x = point.x;
				int y = point.y;
				
				// Flip the y-coord (Cocos2D tilemap coords are flipped this way)
				y = tileCountH - 1 - y;
				
				// Look up the tile to see if we set a Collidable property in the Tileset meta layer
				NSDictionary *properties = [_tileMap propertiesForGID:[_meta tileGIDAt:ccp(x, y)]];
				BOOL collidable = [[properties valueForKey:@"Collidable"] isEqualToString:@"True"];
				
				// If the tile is collidable, return a density of 1.0 (meaning solid)
				// Otherwise return a density of 0.0 meaning completely open.
				return (collidable ? 1.0f : 0.0f);
			}];
			
			// So now what is up with the 0.5 above and below?
			// So the sampler outputs geometry that fits between samples.
			// So in order to make the lines Chipmunk spits out line up with the tile edges,
			// You need to tell the sampler to sample at the pixel centers.
			
			// So, what rect do we ask it to sample?
			// Let's look at an example on just the x-axis first:
			// Say we want to sample 4 tile centers: 0.5, 1.5, 2.5, 3.5
			// So the rect would be cpBBNew(0.5, ..., 3.5, ...) and would use 4 x-samples.
			// So for a tilemap that is tileCountW wide, you'd use cpBBNew(0.5, ..., tileCountW - 0.5, ...).
			
			// BUT! There is one last thing to take care of. If you go from 0.5 to tileCountW - 0.5,
			// there will be a half tile gap in the geometry at the edge of the screen.
			// This is fixed easily enough by adding an extra sample on each edge and clamping the tile coordinates in the sample function.
			cpBB sampleRect = cpBBNew(-0.5, -0.5, tileCountW + 0.5, tileCountH + 0.5);
			
			// Whew! So now we have our rect, and we just need to ask it to march (trace around) our tiles using that rect,
			// and the number of samples in each direction to make which is tileCountW + 2 (because of the two extra samples at the edge).
            ChipmunkPolylineSet * polylines = [sampler march:sampleRect xSamples:tileCountH + 2 ySamples:tileCountH + 2 hard:TRUE];
            
            cpFloat tileW = _tileMap.tileSize.width;
            cpFloat tileH = _tileMap.tileSize.height;
            for(ChipmunkPolyline * line in polylines){
				// Each polyline represents a chain of segments or a loop of segments found in the tileset.
                // Run an exact simplification on the polyline to remove extra vertexes,
				// but otherwise leave the geometry unchanged.
                ChipmunkPolyline * simplified = [line simplifyCurves:0.0f];

                // Separate polyline into segments.
                for(int i=0; i<simplified.count-1; i++){
					// The sampler coordinates were in tile coordinates.
					// Convert them to pixel coordinates by multiplying by the tile size.
                    cpVect a = cpvmult(simplified.verts[  i], tileW);
                    cpVect b = cpvmult(simplified.verts[i+1], tileH);
                    
					// Add the shape and set some properties.
                    ChipmunkShape *seg = [space add:[ChipmunkSegmentShape segmentWithBody:space.staticBody from:a to:b radius:1.0f]];
                    seg.friction = 1.0;
                }
            }

            
        }
        
		// add some crates, it's not a video game without crates!
		for(int i=0; i<16; i++){
			
            float dist = 50.0f;

			//ChipmunkBody* box = 
            [self makeBoxAtX:x - (dist*2) + (i % 4) * dist + 200 y:y - (dist*2) +( i / 4) * dist];
			
		}
						
		[self setViewpointCenter:_player.position];
		
		// schedule updates, whihc also steps the physics space:
		[self scheduleUpdate];
	}
    
	return self;
}

-(void)update:(ccTime)dt
{
    
    // update player motion based on last touch, if we have our finger down:
    if(isTouching){
        // the screen may have moved, so convert the screen space touch location to one in world (node) space.
        CGPoint touchLocation = [self convertToNodeSpace: [[CCDirector sharedDirector] convertToGL: _lastTouchLocation]];
        targetPointBody.pos = touchLocation;
    }
    
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
