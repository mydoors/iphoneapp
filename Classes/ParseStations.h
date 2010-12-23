//
//  ParseStations.h
//  VeloParis
//
//  Created by Mengke WANG on 4/2/10.
//  Copyright 2010 ABVENT. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ParseStations : NSObject {
	NSMutableArray		*mStations;
	NSDictionary		*mStation;
    NSMutableString		*mNodeName;

}
- (NSArray *)parseXMLFromData:(NSData *)data parseError:(NSError **)error;
+ (ParseStations *)sharedParseStations;
@end
