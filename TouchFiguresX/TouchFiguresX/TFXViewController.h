//
//  TFXViewController.h
//  TouchFiguresX
//
//  Created by Kai Leistner on 02.06.14.
//  Copyright (c) 2014 Kai Leistner. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TFXViewController : UIViewController

@property (nonatomic, strong) IBOutlet UILabel *touchLabelText;
@property (nonatomic, strong) IBOutlet UILabel *touchDistanceText;
@property (nonatomic, strong) IBOutlet UILabel *totalTouchDistanceText;

@property (nonatomic, strong) IBOutlet UILabel *timeLabelText;
@property (nonatomic, strong) IBOutlet UILabel *timeTouchedText;
@property (nonatomic, strong) IBOutlet UILabel *totalTimeTouchedText;
@property (nonatomic, strong) IBOutlet UILabel *infoLabelText;
@property (nonatomic, strong) NSTimer *timer;

@end
