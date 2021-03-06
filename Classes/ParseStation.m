//
//  ParseStation.m
//  VeloParis
//
//  Created by Mengke WANG on 4/2/10.
//  Copyright 2010 ABVENT. All rights reserved.
//

#import "ParseStation.h"
//#import "SynthesizeSingleton.h"

@implementation ParseStation

//SYNTHESIZE_SINGLETON_FOR_CLASS(ParseStation);

- (NSDictionary *)parseXMLFromData:(NSData *)data parseError:(NSError **)error;
{
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
	[parser setDelegate:self];
	[parser parse];
	[parser release];
	
	return mStation;
}

- (void)parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
	attributes:(NSDictionary *)attributeDict{
	if([elementName isEqualToString:@"station"]) {
		mStation = [[NSMutableDictionary alloc]init];
	}
	else{
		mKey = elementName;
	}

}

- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName{
	if([elementName isEqualToString:@"station"]) {
	}
	else {
		if ([mValue length]>0) {
			[mStation setValue:mValue forKey:mKey];
		}
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	mValue = string;
}

- (void)dealloc
{
	[mStation release];
	[super dealloc];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	/*
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops" message:[NSString stringWithFormat:@"%@\n%@",NSLocalizedString(@"ParseErrorMessage",nil),[parseError localizedDescription]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
	[alert release];
	*/
}

@end
