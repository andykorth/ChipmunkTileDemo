/* Copyright (c) 2012 Scott Lembcke and Howling Moon Software
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#import "ChipmunkSprite.h"


@interface ChipmunkBody : NSObject
-(cpBody *)body;
@end


@implementation ChipmunkSprite {
	cpBody *_body;
}

@synthesize ignoreBodyRotation = _ignoreBodyRotation;
@synthesize body = _body;

-(ChipmunkBody *)chipmunkBody
{
	return _body->data;
}

-(void)setChipmunkBody:(ChipmunkBody *)chipmunkBody
{
	_body = chipmunkBody.body;
}

// this method will only get called if the sprite is batched.
// return YES if the physic's values (angles, position ) changed.
// If you return NO, then nodeToParentTransform won't be called.
-(BOOL) dirty
{
	return YES;
}

// Override the setters and getters to always reflect the body's properties.
-(CGPoint)position
{
	return cpBodyGetPos(_body);
}

-(void)setPosition:(CGPoint)position
{
	cpBodySetPos(_body, position);
}

-(float)rotation
{
	return (_ignoreBodyRotation ? super.rotation : -CC_RADIANS_TO_DEGREES(cpBodyGetAngle(_body)));
}

-(void)setRotation:(float)rotation
{
	if(_ignoreBodyRotation){
		super.rotation = rotation;
	} else {
		cpBodySetAngle(_body, -CC_DEGREES_TO_RADIANS(rotation));
	}
}

// returns the transform matrix according the Chipmunk Body values
-(CGAffineTransform) nodeToParentTransform
{	
	cpVect rot = (_ignoreBodyRotation ? cpvforangle(-CC_DEGREES_TO_RADIANS(rotation_)) : _body->rot);
	CGFloat x = _body->p.x + rot.x*-anchorPointInPoints_.x - rot.y*-anchorPointInPoints_.y;
	CGFloat y = _body->p.y + rot.y*-anchorPointInPoints_.x + rot.x*-anchorPointInPoints_.y;
	
	if(ignoreAnchorPointForPosition_){
		x += anchorPointInPoints_.x;
		y += anchorPointInPoints_.y;
	}
	
	return (transform_ = CGAffineTransformMake(rot.x, rot.y, -rot.y,	rot.x, x,	y));
}


@end
