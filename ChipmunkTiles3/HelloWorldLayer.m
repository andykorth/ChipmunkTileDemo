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

@interface ChipmunkTilemapSampler : ChipmunkBlockSampler


@end

@implementation ChipmunkTilemapSampler

/*
static cpFloat SampleFuncTileMap(cpVect point, ChipmunkBitmapSampler *self)
{    
    float tileW = self.tileMap.tileSize.width;
    float tileH = self.tileMap.tileSize.height;
    
    // Look up the tile to see if we set a Collidable property in the Tileset meta layer
    int tileGid = [_meta tileGIDAt:ccp(point.w / tileW, point.y/ tileH)];
    if (tileGid) {
        NSDictionary *properties = [_tileMap propertiesForGID:tileGid];
        if (properties) {
            NSString *collision = [properties valueForKey:@"Collidable"];
            if (collision && [collision compare:@"True"] == NSOrderedSame) {
                // This tile is collidable, add the point to Chipmunk's sampler:
                return 1.0f;
            }
        }
    }
    return 0.0f;
    
}


-(id)initWithTileMap:(CCTMXTiledMap*) tileMap
{
	if((self = [super initWithSamplingFunction:(cpMarchSampleFunc)SampleFuncTileMap])){
		// fill in some crap
	}
    
	return self;
}
*/
@end

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

// Much faster than (int)floor(f)
// Profiling showed floor() to be a sizable performance hog
static inline int
floor_int(cpFloat f)
{
	int i = (int)f;
	return (f < 0.0f && f != i ? i - 1 : i);
}

static CCTMXTiledMap *staticTileMap;
static CCTMXLayer *staticMetaMap;


static cpFloat SampleFuncTileMap(cpVect point, ChipmunkBitmapSampler *self)
{    
    
    int tileW = staticTileMap.tileSize.width;
    int tileH = staticTileMap.tileSize.height;
    
    int mapSizeWidth = staticMetaMap.layerSize.width * tileW;
    int mapSizeHeight = staticMetaMap.layerSize.height * tileH;
    
    float w = tileW/2.0f;
    float h = tileH/2.0f;
    
    // first clamp our sampling function.
    cpBB bb = cpBBNew(0, 0, mapSizeWidth,  mapSizeWidth);
    cpVect clamped = cpBBClampVect(bb, point);
    
    int x = floor_int((mapSizeWidth - tileW)*(clamped.x - bb.l )/(bb.r - bb.l));
    int y = floor_int((mapSizeHeight - tileH)*(clamped.y - bb.b)/(bb.t - bb.b));

    // now look up the value in the tile map:
    int tileX = x / tileW ;
    int tileY = staticMetaMap.layerSize.height - (y  / tileH) - 1 ; //we flip the y
    
    ///NSLog(@"Sampling at %f, %f to %d, %d", point.x, point.y, tileX, tileY );
    
    if( tileX >= staticMetaMap.layerSize.width || tileY >= staticMetaMap.layerSize.height || tileX < 0 || tileY <0){
        return 1.0f; //for spaces outside of the map, create collision geometry.
    }
    
    // Look up the tile to see if we set a Collidable property in the Tileset meta layer
    int tileGid = [staticMetaMap tileGIDAt:ccp(tileX, tileY)];
    if (tileGid) {
        NSDictionary *properties = [staticTileMap propertiesForGID:tileGid];
        if (properties) {
            NSString *collision = [properties valueForKey:@"Collidable"];
            if (collision && [collision compare:@"True"] == NSOrderedSame) {
                // This tile is collidable, add the point to Chipmunk's sampler:
                return 1.0f;
            }
        }
    }
    return 0.0f;
    
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
		
		
		// Add a ChipmunkDebugNode to draw the space.
		ChipmunkDebugNode *debugNode = [ChipmunkDebugNode debugNodeForChipmunkSpace:space];
		[self addChild:debugNode];
				
		{
				
				// set up the player body and shape
				float playerMass = 1.0f;
				float playerRadius = 13.0f;
				
				playerBody = [space add:[ChipmunkBody bodyWithMass:playerMass andMoment:cpMomentForCircle(playerMass, 0.0, playerRadius, cpvzero)]];
				
				self.player = [ChipmunkSprite spriteWithFile:@"chipmunkMan.png"];
				self.player.chipmunkBody = playerBody;
				playerBody.pos = ccp(x,y);
				_player.position = ccp(x,y);
			
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
				joint.maxBias = 200.0f;
				
				// limiting the force will prevent us from crazily pushing huge piles
				// of heavy things. and give us a sort of top-down friction.
				joint.maxForce = 3000.0f; 
				
				[space add: joint];
				
		}
        
        {            
            int tileW = _tileMap.tileSize.width;
            int tileH = _tileMap.tileSize.height;
            
            int tileCountW = _meta.layerSize.width;
            int tileCountH = _meta.layerSize.height;
            
            staticTileMap = _tileMap;
            staticMetaMap = _meta;

            
            ChipmunkBlockSampler* sampler = [[ChipmunkBlockSampler alloc] initWithSamplingFunction: (cpMarchSampleFunc) SampleFuncTileMap];
         
            // The output rectangle should be inset slightly so that we sample tile centers, not edges.
            // This along with the tileOffset below will make sure the tiles line up with the geometry perfectly.
            //sampler.outputRect = cpBBNew(tileW / 2.0f, tileH / 2.0f, tileW*tileCountW - tileW / 2.0f, tileH*tileCountH - tileH / 2.0f);
            
            ChipmunkPolylineSet * polylines = [sampler march:cpBBNew(0, 0, tileW*tileCountW, tileH*tileCountH) xSamples:tileH*tileCountH ySamples:tileH*tileCountH hard:TRUE];
            
            for(ChipmunkPolyline * line in polylines){
                // Simplify the line data to ignore details smaller than a tile (or part of one maybe).
                ChipmunkPolyline * simplified = [line simplifyCurves:1.0f];

                // separate line into segments.
                for(int i=0; i<simplified.count-1; i++){
                    cpVect a = simplified.verts[i];
                    cpVect b = simplified.verts[i+1];
                    
                    ChipmunkShape *seg = [ChipmunkSegmentShape segmentWithBody:space.staticBody from:a to:b radius:1.0f];
                    seg.friction = 1.0;
                    [space add:seg];
                }
            }

            
        }
		
		// add some crates, it's not a video game without crates!
		for(int i=0; i<16; i++){
			
			//ChipmunkBody* box = 
            [self makeBox:i y:y x:x];
			
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
