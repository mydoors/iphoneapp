//
//  VeloParisAppDelegate.m
//  VeloParis
//
//  Created by WANG Mengke on 10-4-1.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//
#define DEGREES_TO_RADIANS(__ANGLE) ((__ANGLE) * M_PI / 180.0)
#define RADIANS_TO_DEGREES(__RADIANS) ((__RADIANS) * 180 / M_PI)

#import "VeloParisAppDelegate.h"

@implementation VeloParisAppDelegate

@synthesize window,mFavoriteList;

- (void)awakeFromNib{
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(addAnnotationsNotification:)
												 name:@"addAnnotationsNotification" 
											   object:nil];
	mRequestCount = 0;
	mRequestCountForTable = 0;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	mLocationManager = [[CLLocationManager alloc] init];
	[mLocationManager setDelegate:self];
	[mLocationManager setHeadingFilter:1];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kLocateOnLaunch]){
		[self doLocateSelf:self];
	}
		
	[mLocateOnLaunchSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:kLocateOnLaunch]];
	
	self.mFavoriteList = [[self getFavorites] mutableCopy];
	if (!self.mFavoriteList) {
		self.mFavoriteList = [[NSMutableArray alloc] init];
	}
	
	double latitude = [[[NSUserDefaults standardUserDefaults] valueForKey:kLastLocationLatitude] doubleValue];
	double longitude = [[[NSUserDefaults standardUserDefaults] valueForKey:kLastLocationLongitude] doubleValue];
	
	CLLocationCoordinate2D coordinate;
	
	if (!(latitude && longitude)) {
		[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionary]];
		
		//Location Paris
		coordinate.latitude = 48.856660;
		coordinate.longitude = 2.350996;
	}
	else {
		coordinate.latitude = latitude;
		coordinate.longitude = longitude;
	}
	[self setMapLocation:coordinate distance:300 animated:NO];
	
	[mMapView setShowsUserLocation:YES];
	[mMapView setMapType:[[NSUserDefaults standardUserDefaults] integerForKey:kMapType]];

	[mMapTypeSwitch setSelectedSegmentIndex:[[NSUserDefaults standardUserDefaults] integerForKey:kMapType]];
	
	[mTableView setDataSource:self];
	[window makeKeyAndVisible];
	
	[self addAnnotations];
	
	return YES;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[mLocationManager release];
    [window release];
	[mPinGreen release];
	[mPinYellowGreen release];
	[mPinYellow release];
	[mPinOrange release];
	[mPinRed release];
	[mPinPurple release];
	[latestThreadTime release];
	[mAllStationAnnotationData release];
	[mUserHeadingView release];
    [super dealloc];
}


#pragma mark -
#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
	//[self setMapLocation:newLocation.coordinate distance:300 animated:NO];
	[mMapView setCenterCoordinate:newLocation.coordinate animated:YES	];
	[mLocationManager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
	[mLocationManager stopUpdatingLocation];
	[mLocationManager stopUpdatingHeading];
	mIsHeading = NO;
	[mUserHeadingView setHidden:YES];
	[[mMapView viewForAnnotation:[mMapView userLocation]] setTransform:CGAffineTransformIdentity];
	/*
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops" message:[NSString stringWithFormat:@"%@",NSLocalizedString(@"LocationManagerErrorMessage",nil)] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
	[alert release];
	 */
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading{
	float headingAccuracy = [newHeading trueHeading];
	if (headingAccuracy > 0) {
		//CGAffineTransform mapTransform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(headingAccuracy)*-1);//如果你想整个屏幕一起跟着旋转
		CGAffineTransform pinTransform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(headingAccuracy));
		//[mMapView viewForAnnotation:[mMapView userLocation]].transform = pinTransform;
		mUserHeadingView.transform = pinTransform;
		[mUserHeadingView setHidden:NO];
		
		/*如果你想整个屏幕一起跟着旋转
		for (UIView *subView in [mMapView subviews]) {
			//NSLog(@"%@",[subView description]);
			if(![[[subView class] description] isEqualToString:@"UIImageView"]){
				subView.transform = mapTransform;
			}
		}
		
		for (StationAnnotation *annotation in [mAllStationAnnotationData allValues]) {
			[mMapView viewForAnnotation:annotation].transform = pinTransform;
		}
		*/
	}
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager{//遇到电磁干扰时，是否弹出按8字形摆动iPhone校准指南针的界面。
	return YES;
}

#pragma mark -
#pragma mark Variables

- (UIImage *)pinGreen{
	if (!mPinGreen) {
		mPinGreen = [[UIImage alloc] initWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"pinGreen.png"]];
	}
	return mPinGreen;
}


- (UIImage *)pinYellowGreen{
	if (!mPinYellowGreen) {
		mPinYellowGreen = [[UIImage alloc] initWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"pinYellowGreen.png"]];
	}
	return mPinYellowGreen;
}


- (UIImage *)pinYellow{
	if (!mPinYellow) {
		mPinYellow = [[UIImage alloc] initWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"pinYellow.png"]];
	}
	return mPinYellow;
}


- (UIImage *)pinOrange{
	if (!mPinOrange) {
		mPinOrange = [[UIImage alloc] initWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"pinOrange.png"]];
	}
	return mPinOrange;
}


- (UIImage *)pinRed{
	if (!mPinRed) {
		mPinRed = [[UIImage alloc] initWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"pinRed.png"]];
	}
	return mPinRed;
}


- (UIImage *)pinPurple{
	if (!mPinPurple) {
		mPinPurple = [[UIImage alloc] initWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"pinPurple.png"]];
	}
	return mPinPurple;
}

- (UIImage *)favoriteOn{
	if (!mFavoriteOn) {
		mFavoriteOn = [[UIImage alloc] initWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"FavoriteOn.png"]];
	}
	return mFavoriteOn;
}

- (UIImage *)favoriteOff{
	if (!mFavoriteOff) {
		mFavoriteOff = [[UIImage alloc] initWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"FavoriteOff.png"]];
	}
	return mFavoriteOff;
}

- (UIImageView *)userHeadingView{
	if (!mUserHeadingView) {
		UIImage *imageUserHeading = [[UIImage alloc] initWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"UserHeading.png"]];
		mUserHeadingView = [[UIImageView alloc] initWithImage:imageUserHeading];
		[imageUserHeading release];
		[mUserHeadingView setHidden:YES];
	}
	return mUserHeadingView;
}

#pragma mark -
#pragma mark MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
	[self saveLocationLatitude:mapView.centerCoordinate.latitude Longitude:mapView.centerCoordinate.longitude];
	if (mDidAddAllAnnotations) {
		[NSThread detachNewThreadSelector:@selector(threadRequestVisibleAnnotations:) toTarget:self withObject:mapView];
	}
	/*如果你想整个屏幕都转动的话，需要在UserLocation离开屏幕中心时停止旋转屏幕……我找不到更好的算法了……
	CLLocationCoordinate2D centerCoordinate = [mMapView centerCoordinate];
	CLLocationCoordinate2D userCoordinate = [mMapView userLocation].coordinate;
	if (centerCoordinate.latitude != userCoordinate.latitude &&
		centerCoordinate.longitude != userCoordinate.longitude) {
		[mUserHeadingView setHidden:YES];
		[mLocationManager stopUpdatingHeading];
	}
	for (UIView *subView in [mMapView subviews]) {
		if(![[[subView class] description] isEqualToString:@"UIImageView"]){
			subView.transform = CGAffineTransformIdentity;
		}
	}
	
	for (StationAnnotation *annotation in [mAllStationAnnotationData allValues]) {
		[mMapView viewForAnnotation:annotation].transform = CGAffineTransformIdentity;
	}
	*/
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
	if([annotation isKindOfClass:[StationAnnotation class]]){//[annotation isKindOfClass:[StationAnnotation class]]//[annotation isKindOfClass:[MKUserLocation class]]
		StationAnnotation *oneStationAnnotation = (StationAnnotation *)annotation;
		PinAnnotationView *pinAnnotationView = [(PinAnnotationView *) [mMapView dequeueReusableAnnotationViewWithIdentifier:@"PinAnnotationView"] retain];
		if (!pinAnnotationView) {
			pinAnnotationView = [[PinAnnotationView alloc] initWithAnnotation:oneStationAnnotation reuseIdentifier:@"PinAnnotationView"];
			[pinAnnotationView setImage:[self pinPurple]];

			UIButton *leftCalloutAccessoryView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
			if ([self isInFavoriteList:[oneStationAnnotation stationID]]) {
				[leftCalloutAccessoryView setImage:[self favoriteOn] forState:UIControlStateNormal];
			}
			else {
				[leftCalloutAccessoryView setImage:[self favoriteOff] forState:UIControlStateNormal];
			}
			[leftCalloutAccessoryView addTarget:self action:@selector(doSwitchFavoriteButton:) forControlEvents:UIControlEventTouchUpInside];
			[pinAnnotationView setLeftCalloutAccessoryView:leftCalloutAccessoryView];
			[leftCalloutAccessoryView release];
		}
		else {
			[pinAnnotationView setAnnotation:oneStationAnnotation];
		}
		
		return [pinAnnotationView autorelease];
	}


	return nil;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control{
	NSString *stationID = [(StationAnnotation *)[view annotation] stationID];
	if ([self isInFavoriteList:stationID]) {
		[(UIButton *)control setImage:mFavoriteOn forState:UIControlStateNormal];
	}
	else {
		[(UIButton *)control setImage:mFavoriteOff forState:UIControlStateNormal];
	}
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views{
	if ([views count]>1) {
		mDidAddAllAnnotations = YES;
		if ([[mSuperView subviews]lastObject] == mTableView) {
			[NSThread detachNewThreadSelector:@selector(threadRequestAnnotationsForTable:) toTarget:self withObject:self.mFavoriteList];
		}
		else if ([[mSuperView subviews]lastObject] == mMapView) {
			[NSThread detachNewThreadSelector:@selector(threadRequestVisibleAnnotations:) toTarget:self withObject:mMapView];
		}
		
		[self reloadTable];
	}
	
	UIView *userLocationView = [mMapView viewForAnnotation:[mMapView userLocation]];
	if (userLocationView) {
		UIImageView *imageView = [self userHeadingView];
		[imageView setFrame:CGRectMake(userLocationView.frame.origin.x + (userLocationView.frame.size.width - imageView.frame.size.width)/2, userLocationView.frame.origin.y + (userLocationView.frame.size.height - imageView.frame.size.height)/2, imageView.frame.size.width, imageView.frame.size.height)];
		[userLocationView addSubview:imageView];
		mDidAddUserLocationAnnotation = YES;
	}
}

#pragma mark -
#pragma mark Actions

- (IBAction)doLocateSelf:(id)sender{
	CGPoint userLocationPoint = [mMapView convertCoordinate:[mMapView userLocation].coordinate toPointToView:mMapView];
	if ([mLocationManager locationServicesEnabled]) {
		[mLocationManager startUpdatingLocation];
	}
	if ([mLocationManager headingAvailable] && mDidAddUserLocationAnnotation) {
		if (userLocationPoint.x > 159.0f && userLocationPoint.x < 161.0f &&
				 userLocationPoint.y > 207.0f && userLocationPoint.y < 209.0f){
			if (!mIsHeading) {
				[mLocationManager startUpdatingHeading];
				mIsHeading = YES;
			}
			else {
				[mLocationManager stopUpdatingHeading];
				mIsHeading = NO;
				[mUserHeadingView setHidden:YES];
				[[mMapView viewForAnnotation:[mMapView userLocation]] setTransform:CGAffineTransformIdentity];
			}
		}
	}
}

- (IBAction)doZoomIn:(id)sender{
	MKCoordinateRegion region = mMapView.region;
	region.span.latitudeDelta=region.span.latitudeDelta * 0.4;
	region.span.longitudeDelta=region.span.longitudeDelta * 0.4;
	[mMapView setRegion:region animated:YES];
}

- (IBAction)doZoomOut:(id)sender{
	MKCoordinateRegion region = mMapView.region;
	region.span.latitudeDelta=region.span.latitudeDelta * 1.3;
	region.span.longitudeDelta=region.span.longitudeDelta * 1.3;
	[mMapView setRegion:region animated:YES];
}

- (IBAction)doSwitchView:(id)sender{
	[UIView beginAnimations:@"animationID" context:nil];
	[UIView setAnimationDuration:0.3f];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationRepeatAutoreverses:NO];
	if ([[mSuperView subviews]lastObject]!=mMapView) {
		[UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:mSuperView cache:YES];
		if (mDidAddAllAnnotations) {
			[NSThread detachNewThreadSelector:@selector(threadRequestVisibleAnnotations:) toTarget:self withObject:mMapView];
		}
		[mSuperView bringSubviewToFront:mMapView];
		[mZoomOutButton setEnabled:YES];
		[mZoomInButton setEnabled:YES];
		[mLocateSelfButton setEnabled:YES];
		[mSettingButton setEnabled:YES];
		[mFavoritesButton setEnabled:YES];
	}
	else if(![sender isKindOfClass:[VeloParisAppDelegate class]]){
		switch ([sender tag]) {
			case 0:
				[UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:mSuperView cache:YES];
				if (mDidAddAllAnnotations) {
					[NSThread detachNewThreadSelector:@selector(threadRequestAnnotationsForTable:) toTarget:self withObject:self.mFavoriteList];
				}
				[self reloadTable];
				[mSettingButton setEnabled:NO];
				[mFavoritesButton setEnabled:YES];
				[mSuperView bringSubviewToFront:mTableView];
				break;
			case 1:
				[UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:mSuperView cache:YES];
				[mSettingButton setEnabled:YES];
				[mFavoritesButton setEnabled:NO];
				[mLocateOnLaunchSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:kLocateOnLaunch]];
				[mSuperView bringSubviewToFront:mSettingView];
				break;
			default:
				break;
		}
		[mZoomOutButton setEnabled:NO];
		[mZoomInButton setEnabled:NO];
		[mLocateSelfButton setEnabled:NO];
	}

	[UIView commitAnimations];
}

- (IBAction)doSegmentedControlAction:(id)sender{
	if (sender == mMapTypeSwitch) {
		switch (((UISegmentedControl *)sender).selectedSegmentIndex)
		{
			case 0:
			{
				mMapView.mapType = MKMapTypeStandard;
				[[NSUserDefaults standardUserDefaults] setInteger:MKMapTypeStandard forKey:kMapType];
				break;
			} 
			case 1:
			{
				mMapView.mapType = MKMapTypeSatellite;
				[[NSUserDefaults standardUserDefaults] setInteger:MKMapTypeSatellite forKey:kMapType];
				break;
			} 
			default:
			{
				mMapView.mapType = MKMapTypeHybrid;
				[[NSUserDefaults standardUserDefaults] setInteger:MKMapTypeHybrid forKey:kMapType];
				break;
			} 
		}
	}
	else if(sender == mRefreshCacheButton){
		[mMapView removeAnnotations:[mMapView annotations]];
		[[ConnectionDelegate sharedConnectionDelegate] getAllStations];
	}
	[self doSwitchView:self];
}

- (IBAction)doSwitchFavoriteButton:(id)sender{
	PinAnnotationView *pinAnnotationView = (PinAnnotationView *)[[sender superview] superview];
	StationAnnotation *stationAnnotation = (StationAnnotation *)[pinAnnotationView annotation];
	NSString *stationID = [stationAnnotation stationID];

	if ([self isInFavoriteList:stationID]) {
		[self removeFavorite:stationID];
		[(UIButton *)sender setImage:[self favoriteOff] forState:UIControlStateNormal];
	}
	else {
		[self addFavorite:stationID];
		[(UIButton *)sender setImage:[self favoriteOn] forState:UIControlStateNormal];
	}
}

- (IBAction)doSwitchLocateOnLaunch:(id)sender{
	[[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:kLocateOnLaunch] forKey:kLocateOnLaunch];
}

#pragma mark -
#pragma mark Methods

- (void)addFavorite:(NSString *)stationID{
	if (![self.mFavoriteList containsObject:stationID]) {
		[self.mFavoriteList addObject:stationID];
		[self saveFavorites];
	}
}

- (void)removeFavorite:(NSString *)stationID{
	if ([self.mFavoriteList containsObject:stationID]) {
		[self.mFavoriteList removeObject:stationID];
		[self saveFavorites];
	}
}

- (BOOL)isInFavoriteList:(NSString *)stationID{
	return [self.mFavoriteList containsObject:stationID];
}

- (void)saveLocationLatitude:(double)latitude Longitude:(double)longitude{
	NSNumber *locationLatitude = [NSNumber numberWithDouble:latitude];
	NSNumber *locationLongitude = [NSNumber numberWithDouble:longitude];
	[[NSUserDefaults standardUserDefaults] setValue:locationLatitude forKey:kLastLocationLatitude];
	[[NSUserDefaults standardUserDefaults] setValue:locationLongitude forKey:kLastLocationLongitude];
}

- (void)setMapLocation:(CLLocationCoordinate2D)coordinate distance:(double)distance animated:(BOOL)animated{
	[self saveLocationLatitude:coordinate.latitude Longitude:coordinate.longitude ];
	MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(coordinate, distance, distance); 
    MKCoordinateRegion adjustedRegion = [mMapView regionThatFits:viewRegion];
	[mMapView setRegion:adjustedRegion animated:animated];
}

- (void)addAnnotations{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"AllStationAnnotationsDic.bin"];
	
	if (mAllStationAnnotationData) {
		[mAllStationAnnotationData release];
		mAllStationAnnotationData= nil;
	}
	
	mAllStationAnnotationData = [[NSKeyedUnarchiver unarchiveObjectWithFile:path] retain];

	if (mAllStationAnnotationData) {
		mDidAddAllAnnotations = NO;
		NSArray *oldAnnotations = [mMapView annotations];
		if (oldAnnotations) {
			[mMapView removeAnnotations:oldAnnotations];
		}
		
		[mMapView addAnnotations:[mAllStationAnnotationData allValues]];
	}
	else {
		[[ConnectionDelegate sharedConnectionDelegate] getAllStations];
	}

}

- (void)setAnnotationView:(StationAnnotation *)stationAnnotation strAvailable:(NSString *)strAvailable strFree:(NSString *)strFree strTotal:(NSString *)strTotal{
	[stationAnnotation setSubtitle:[NSString stringWithFormat:@"%@ %@ %@",strAvailable,strFree,strTotal]];
	
	PinAnnotationView *pinAnnotationView = (PinAnnotationView *)[mMapView viewForAnnotation:stationAnnotation];
	
	float numFree = [strFree floatValue];
	float numAvailable = [strAvailable floatValue];
	float ratio = numAvailable / (numAvailable + numFree);
	[stationAnnotation setRatio:ratio];
	[stationAnnotation setNumAvailable:numAvailable];
	if (pinAnnotationView) {
		if (numAvailable < 2) {
			[pinAnnotationView setImage:[self pinRed]];
		}
		else if(ratio < 0.25f) {
			[pinAnnotationView setImage:[self pinOrange]];
		}
		else if(ratio >= 0.25f && ratio < 0.50f) {
			[pinAnnotationView setImage:[self pinYellow]];
		}
		else if(ratio >= 0.50f && ratio < 1.0f) {
			[pinAnnotationView setImage:[self pinYellowGreen]];
		}
		else{
			[pinAnnotationView setImage:[self pinGreen]];
		}
	}
	else {
		NSLog(@"not created yet");
	}

}

- (void)threadSetAnnotationSubTitle:(StationAnnotation *)stationAnnotation{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSThread setThreadPriority:0.1];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	mRequestCount += 1;
	NSData *responseData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.velib.paris.fr/service/stationdetails/%@",[stationAnnotation stationID]]]];
	if (responseData) {
		ParseStation *parser = [[ParseStation alloc] init];
		NSDictionary *infoDic = [parser parseXMLFromData:responseData parseError:nil];
		[self setAnnotationView:stationAnnotation strAvailable:[infoDic valueForKey:@"available"] strFree:[infoDic valueForKey:@"free"] strTotal:[infoDic valueForKey:@"total"]];
		[stationAnnotation setIsRequested:YES];
		[parser release];
	}
	mRequestCount -= 1;
	
	if (mRequestCount == 0) {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
		[mMapView setNeedsDisplay];
	}
	[stationAnnotation setIsRunning:NO];
	[pool release];
	[NSThread exit];
}

- (void)threadRequestVisibleAnnotations:(MKMapView *)mapView{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSThread setThreadPriority:0.1];
	NSDate *selfDate = [NSDate date];
	if (latestThreadTime) {
		NSDate *oldDate = latestThreadTime;
		latestThreadTime = [selfDate retain];
		[oldDate release];
	}
	else {
		latestThreadTime = [selfDate retain];
	}

	
	MKCoordinateRegion currentRegion = mapView.region;
	CLLocationCoordinate2D currentCenter = currentRegion.center;
	MKCoordinateSpan currentSpan = currentRegion.span;
	
	double latitudeRadius = currentSpan.latitudeDelta/2;
	double longitudeRadius = currentSpan.longitudeDelta/2;
	
	NSArray *allAnnotations = [[NSArray alloc]initWithArray:[mMapView annotations]];
	for (StationAnnotation *stationAnnotation in allAnnotations)
	{
		if(![latestThreadTime isEqualToDate:selfDate]) {
			break;
		}

		if (![stationAnnotation isKindOfClass:[MKUserLocation class]] &&
			![stationAnnotation isRunning] &&
			![stationAnnotation isRequested] &&
			stationAnnotation.coordinate.latitude >= currentCenter.latitude - latitudeRadius&&
			stationAnnotation.coordinate.latitude <= currentCenter.latitude + latitudeRadius &&
			stationAnnotation.coordinate.longitude >= currentCenter.longitude - longitudeRadius&&
			stationAnnotation.coordinate.longitude <= currentCenter.longitude + longitudeRadius) {
			while (mRequestCount > 10) {
				[NSThread sleepForTimeInterval:0.2];
			}
			[stationAnnotation setIsRunning:YES];
			[NSThread detachNewThreadSelector:@selector(threadSetAnnotationSubTitle:) toTarget:self withObject:stationAnnotation];
		}
	}
	
	[allAnnotations release];
	[pool release];
	[NSThread exit];
}

- (void)threadSetAnnotationSubTitleForTable:(StationAnnotation *)stationAnnotation{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSThread setThreadPriority:0.1];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	mRequestCountForTable += 1;
	NSData *responseData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.velib.paris.fr/service/stationdetails/%@",[stationAnnotation stationID]]]];
	if (responseData) {
		ParseStation *parser = [[ParseStation alloc] init];
		NSDictionary *infoDic = [parser parseXMLFromData:responseData parseError:nil];
		[self setAnnotationView:stationAnnotation strAvailable:[infoDic valueForKey:@"available"] strFree:[infoDic valueForKey:@"free"] strTotal:[infoDic valueForKey:@"total"]];
		[stationAnnotation setIsRequested:YES];
		[parser release];
	}
	mRequestCountForTable -= 1;
	
	if (mRequestCountForTable == 0) {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
		[self reloadTable];
	}
	[stationAnnotation setIsRunning:NO];
	[pool release];
	[NSThread exit];
}

- (void)threadRequestAnnotationsForTable:(NSArray *)stationIDArray{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSThread setThreadPriority:0.1];
	NSDate *selfDate = [NSDate date];
	if (latestTableThreadTime) {
		[latestTableThreadTime release];
	}
	latestTableThreadTime = [selfDate retain];
	for (NSString *stationID in stationIDArray)
	{
		StationAnnotation *stationAnnotation = [mAllStationAnnotationData valueForKey:stationID];
		if(![latestTableThreadTime isEqualToDate:selfDate]) {
			break;
		}
		
		if (![stationAnnotation isKindOfClass:[MKUserLocation class]] &&
			![stationAnnotation isRunning] &&
			![stationAnnotation isRequested]) {
			while (mRequestCountForTable > 10) {
				[NSThread sleepForTimeInterval:0.2];
			}
			[stationAnnotation setIsRunning:YES];
			[NSThread detachNewThreadSelector:@selector(threadSetAnnotationSubTitleForTable:) toTarget:self withObject:stationAnnotation];
		}
	}
	[pool release];
	[NSThread exit];
}

- (NSArray *)getFavorites{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"favorites.plist"];
	return [NSArray arrayWithContentsOfFile:path];
}

- (void)saveFavorites{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"favorites.plist"];
	[self.mFavoriteList writeToFile:path atomically:YES];
}

- (void)reloadTable{
	[mTableView reloadData];
	[mTableView setNeedsDisplay];
}

#pragma mark -
#pragma mark Notifications

- (void)addAnnotationsNotification:(NSNotification *)notification{
	[self addAnnotations];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (mAllStationAnnotationData) {
		return [self.mFavoriteList count];
	}
	else {
		return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    CustomizedTableCell *cell = (CustomizedTableCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[CustomizedTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	else {
		[[cell mMiddleLabel] setHidden:NO];
		[[cell mRightLabel] setHidden:NO];
	}

	NSString *stationID = [self.mFavoriteList objectAtIndex:indexPath.row];
	StationAnnotation *stationAnnotation = [mAllStationAnnotationData valueForKey:stationID];
	NSString *subTitle = [stationAnnotation subtitle];
	cell.mLeftLabel.text = [NSString stringWithFormat:@"%@",[[[stationAnnotation title] componentsSeparatedByString:@" - "] lastObject]];
	cell.mMiddleLabel.text = subTitle?[NSString stringWithFormat:@" %@",subTitle]:@"";
    cell.mRightLabel.text = [NSString stringWithFormat:@"  %@",stationID];
	CLLocation *location = [[CLLocation alloc] initWithLatitude:stationAnnotation.coordinate.latitude longitude:stationAnnotation.coordinate.longitude];
	CLLocation *userLocation = [mLocationManager location];
	cell.mDistanceLabel.text = userLocation?[NSString stringWithFormat:@"Distance %0.2f km",[userLocation getDistanceFrom:location]/1000]:@"";
	[location release];
    
    return cell;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		NSString *stationID = [self.mFavoriteList objectAtIndex:indexPath.row];
		StationAnnotation *stationAnnotation = [mAllStationAnnotationData valueForKey:stationID];
		PinAnnotationView *pinAnnotationView = (PinAnnotationView *)[mMapView viewForAnnotation:stationAnnotation];
		[(UIButton *)[pinAnnotationView leftCalloutAccessoryView] setImage:[self favoriteOff] forState:UIControlStateNormal];
		[self.mFavoriteList removeObjectAtIndex:indexPath.row];
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
		[self saveFavorites];
	} 
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *stationID = [self.mFavoriteList objectAtIndex:indexPath.row];
	StationAnnotation *stationAnnotation = [mAllStationAnnotationData valueForKey:stationID];
	[self setMapLocation:stationAnnotation.coordinate distance:200 animated:NO];
	[self doSwitchView:self];
	[mMapView selectAnnotation:stationAnnotation animated:YES];
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath{
//- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
	CustomizedTableCell *tableCell = (CustomizedTableCell *)[tableView cellForRowAtIndexPath:indexPath];
	[[tableCell mMiddleLabel] setHidden:YES];
	[[tableCell mRightLabel] setHidden:YES];
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath{
	CustomizedTableCell *tableCell = (CustomizedTableCell *)[tableView cellForRowAtIndexPath:indexPath];
	[[tableCell mMiddleLabel] setHidden:NO];
	[[tableCell mRightLabel] setHidden:NO];
}
@end
