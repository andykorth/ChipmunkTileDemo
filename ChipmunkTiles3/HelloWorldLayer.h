//
//  HelloWorldLayer.h
//  TiledChipmunk
//
//  Created by Andy Korth on 6/7/12.
//  Copyright Howling Moon Software 2012. All rights reserved.
//


// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "ObjectiveChipmunk.h"
#import "ChipmunkSprite.h"

// HelloWorldLayer
@interface HelloWorldLayer : CCLayer
{
    // Inside the HelloWorld class declaration
    CCTMXTiledMap *_tileMap;
    CCTMXLayer *_background;
    
    CCTMXLayer *_meta;
    
    ChipmunkSprite *_player;    
}

// After the class declaration
@property (nonatomic, retain) CCTMXTiledMap *tileMap;
@property (nonatomic, retain) CCTMXLayer *background;

@property (nonatomic, retain) ChipmunkSprite *player;

@property (nonatomic, retain) CCTMXLayer *meta;

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

@end
