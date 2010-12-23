//
//  PinAnnotationView.m
//  VeloParis
//
//  Created by WANG Mengke on 10-4-3.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PinAnnotationView.h"

@implementation PinAnnotationView

- (BOOL)canShowCallout{
	return YES;
}

- (CGPoint)centerOffset{
	return CGPointMake(4, -10);
}

-(CGPoint)calloutOffset{
	return CGPointMake(-4, -1);
}

@end
