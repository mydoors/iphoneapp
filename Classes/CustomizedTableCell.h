//
//  CustomizedTableCell.h
//  VeloParis
//
//  Created by WANG Mengke on 10-4-6.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CustomizedTableCell : UITableViewCell {
	UILabel *mLeftLabel;
	UILabel *mMiddleLabel;
	UILabel *mRightLabel;
	UILabel *mDistanceLabel;
}

@property (nonatomic, retain) UILabel *mLeftLabel;
@property (nonatomic, retain) UILabel *mMiddleLabel;
@property (nonatomic, retain) UILabel *mRightLabel;
@property (nonatomic, retain) UILabel *mDistanceLabel;

@end
