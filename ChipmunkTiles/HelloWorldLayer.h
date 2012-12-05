//
//  HelloWorldLayer.h
//  TiledChipmunk
//
//  Created by Andy Korth on 6/7/12.
//  Copyright Howling Moon Software 2012. All rights reserved.
//


// First import ObjectiveChipmunk to prevent crazy bad header things from happening
#import "ObjectiveChipmunk.h"
// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

// HelloWorldLayer
@interface HelloWorldLayer : CCLayer
{
    // Inside the HelloWorld class declaration
    CCTMXTiledMap *_tileMap;
    CCTMXLayer *_background;
    
    CCTMXLayer *_meta;
    
    CCPhysicsSprite *_player;
}

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

@end
