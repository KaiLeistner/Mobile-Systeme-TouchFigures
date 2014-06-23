//
//  TFXViewController.m
//  TouchFiguresX
//
//  Created by Kai Leistner on 02.06.14.
//  Copyright (c) 2014 Kai Leistner. All rights reserved.
//

#import "TFXViewController.h"
#import "TFXBoxView.h"

@interface TFXViewController ()
{
    // Touch
    CGPoint touchPositionStart;
    CGPoint touchPositionEnd;
    double totalTouchDistance;
    
    CGPoint movePositionOld;
    CGPoint movePositionNew;
    double totalMoveDistance;
    double totalMoveCentimeter;
    double lastMoveDistance;
    double lastMoveCentimeter;
    
    // Time
    double timeTouched;
    double totalTimeTouched;
    
    // Heatblocks
    int columnCount;
    int rowCount;
    int blockSize;
    
    CGFloat screenWidth;
    CGFloat screenHeight;
    
    CGPoint blockPos;
    int blockField[18][10];
    TFXBoxView *blockViews[18][10];
    int blockAtTouchPosX;
    int blockAtTouchPosY;
    int highestBlockValue;
    
    bool showValues;
    bool shakedDeviceOnce;
    
    UIView *layerView;
}

@end


@implementation TFXViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithRed:(2.0/255.0) green:(12.0/255.0) blue:(18.0/255) alpha:1.0];
    
    highestBlockValue = 0;      // highest block touch value for reference
    showValues = true;          // should the values in the blockviews be shown
    shakedDeviceOnce = false;   // was the davice shaked once? (for info label)
    
    blockSize = 32;             // the size of the blocks
    columnCount = (int)[[UIScreen mainScreen] applicationFrame].size.width/blockSize;
    rowCount = (int)ceil([[UIScreen mainScreen] applicationFrame].size.height/blockSize);
    
    // Setup the block views
    int xPosition = 0;
    int yPosition = 0;
    for (int y = 0; y < rowCount; y++) {
        xPosition = 0;
        for (int x = 0; x < columnCount; x++) {
            TFXBoxView *view = [[TFXBoxView alloc] initWithFrame:CGRectMake(xPosition, yPosition, blockSize, blockSize)];
            
            [view setFont:[UIFont fontWithName: @"Trebuchet MS" size: 12.0f]];
            [view setTextColor:[UIColor whiteColor]];
            [view setTextAlignment:NSTextAlignmentCenter];
            
            [self.view addSubview:view];
            
            // save referneces to the view blocks in an array
            blockViews[y][x] = view;
            blockViews[y][x].value = 0;
            
            xPosition += blockSize;
        }
        yPosition += blockSize;
    }
    
    // create layer that hides the boxmap
    layerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] applicationFrame].size.width, [[UIScreen mainScreen] applicationFrame].size.height)];
    [layerView setBackgroundColor:[UIColor blackColor]];
    [self.view addSubview:layerView];
    
    // bring the text views in front of all other views
    [self.view bringSubviewToFront:self.touchLabelText];
    [self.view bringSubviewToFront:self.touchDistanceText];
    [self.view bringSubviewToFront:self.totalTouchDistanceText];
    [self.view bringSubviewToFront:self.timeLabelText];
    [self.view bringSubviewToFront:self.timeTouchedText];
    [self.view bringSubviewToFront:self.totalTimeTouchedText];
    
    [self.view bringSubviewToFront:self.infoLabelText];
    self.infoLabelText.alpha = 0.0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}


#pragma mark - Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    lastMoveDistance = 0;   // Reset move distance on new touch
    timeTouched = 0;        // Reset time of touch on new touch
    
    for (UITouch *touch in touches) {
		// Send to the dispatch method, which will make sure the appropriate subview is acted upon
		touchPositionStart = [touch locationInView:self.view];
        movePositionNew = touchPositionStart;
	}
    
    // Start timer to measure touch time
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(counter) userInfo:nil repeats:YES];

    [self updateBlockValue];    // Update the blockvalue at current position
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    movePositionOld = movePositionNew;
    for (UITouch *touch in touches) {
		// Send to the dispatch method, which will make sure the appropriate subview is acted upon
		movePositionNew = [touch locationInView:self.view];
	}
    // Calculate the distance of the motion
    double moveDistance = sqrt(pow(movePositionOld.x - movePositionNew.x, 2.0) + pow(movePositionOld.y - movePositionNew.y, 2.0));
    totalMoveDistance = totalMoveDistance + moveDistance;
    totalMoveCentimeter = totalMoveDistance / 64;   // Convert distance into actual centimeter
    
    lastMoveDistance = lastMoveDistance + moveDistance;
    lastMoveCentimeter = lastMoveDistance / 64;     // Convert distance into actual centimeter
    
    // Update label views
    NSString *distanceFormatString = NSLocalizedString(@"Total: %.2f cm", @"Format string for info text for distance");
    self.touchDistanceText.text = [NSString stringWithFormat:distanceFormatString, totalMoveCentimeter];
    
    NSString *lastDistanceFormatString = NSLocalizedString(@"Last: %.2f cm", @"Format string for info text for total distance");
    self.totalTouchDistanceText.text = [NSString stringWithFormat:lastDistanceFormatString, lastMoveCentimeter];

    [self updateBlockValue];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches) {
		// Send to the dispatch method, which will make sure the appropriate subview is acted upon
		touchPositionEnd = [touch locationInView:self.view];
	}
    
    // Calculate Distance
    double touchDistance = sqrt(pow(touchPositionEnd.x - touchPositionStart.x, 2.0) + pow(touchPositionEnd.y - touchPositionStart.y, 2.0));
    totalTouchDistance = totalTouchDistance + touchDistance;
    [self.timer invalidate];    // Cancel the timer
    [self animateViewBlocks];   // Switch digits on and off the block views
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.timer invalidate];    // Cancel the timer
}

#pragma mark - Timer

- (void)counter {
    // Count the touch time up
    timeTouched = timeTouched + 0.01;
    totalTimeTouched = totalTimeTouched + 0.01;
    
    if ( !shakedDeviceOnce && totalTimeTouched >= 5.0) {
        [UIView animateWithDuration:1.0 animations:^{
            self.infoLabelText.alpha = 1.0;     // Display the "shake device" info label
        }];
    }
    
    // Convert seconds into minutes if needed and update label views
    int minutes, seconds;
    if (totalTimeTouched >= 60.0) {
        minutes = (int) totalTimeTouched/60;
        seconds = (int) totalTimeTouched%60;
        
        self.totalTimeTouchedText.text = [NSString stringWithFormat:@"Total: %02d:%02d min", minutes, seconds];
    }
    else {
        self.totalTimeTouchedText.text = [NSString stringWithFormat:@"Total: %05.2f sec", totalTimeTouched];
    }
    if (timeTouched >= 60.0) {
        minutes = (int) totalTimeTouched/60;
        seconds = (int) totalTimeTouched%60;
        
        self.timeTouchedText.text = [NSString stringWithFormat:@"Last: %02d:%02d min", minutes, seconds];
    }
    else {
        self.timeTouchedText.text = [NSString stringWithFormat:@"Last: %05.2f sec", timeTouched];
    }
}

#pragma mark - Box Heatmap

- (void)updateBlockViews
{
    // Iterate through every viewblock
    for (int y = 0; y < rowCount; y++) {
        for (int x = 0; x < columnCount; x++) {
            
            TFXBoxView *blockView = blockViews[y][x];
            
            // Set tranparency in relation of highest touch value
            double alphaValue = (float)blockView.value / (float)highestBlockValue;
            [blockView setBackgroundColor:[UIColor colorWithRed:(55.0/255.0) green:(166.0/255.0) blue:(239.0/255.0) alpha:alphaValue]];
            
            if (showValues) {
                int valueDigit = (int) (blockViews[y][x].value);
                
                if (valueDigit == 0) {
                    [blockView setText: [NSString stringWithFormat: @""]];                  // Hide values
                } else {
                    [blockView setText: [NSString stringWithFormat: @"%d", valueDigit]];    // Show values
                }
            }
        }
    }
}

- (void)updateBlockValue
{
    blockAtTouchPosX = (int) movePositionNew.x/blockSize;
    blockAtTouchPosY = (int) movePositionNew.y/blockSize;
    TFXBoxView *blockView = blockViews[blockAtTouchPosY][blockAtTouchPosX];
    blockView.value += 1;
    if(blockView.value > highestBlockValue) {
        highestBlockValue = blockView.value;    // Update highest touch value
    }
    [self updateBlockViews];
}

#pragma mark - Shake Gesture

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    // Device was shaked
    shakedDeviceOnce = true;
    self.infoLabelText.hidden = true;
    
    if (motion == UIEventSubtypeMotionShake)
    {
        [self updateBlockViews];
        
        // Animations
        
        // Slide the text outside the display and hide it
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            short dist = 240;
            self.touchLabelText.alpha = (self.touchLabelText.alpha == 1.0 ? 0.0 : 1.0);
            self.touchLabelText.center = (self.touchLabelText.alpha == 1.0 ? CGPointMake(self.touchLabelText.center.x, self.touchLabelText.center.y + dist) : CGPointMake(self.touchLabelText.center.x, self.touchLabelText.center.y - dist));
            self.touchDistanceText.alpha = (self.touchDistanceText.alpha == 1.0 ? 0.0 : 1.0);
            self.touchDistanceText.center = (self.touchDistanceText.alpha == 1.0 ? CGPointMake(self.touchDistanceText.center.x, self.touchDistanceText.center.y + dist) : CGPointMake(self.touchDistanceText.center.x, self.touchDistanceText.center.y - dist));
            self.totalTouchDistanceText.alpha = (self.totalTouchDistanceText.alpha == 1.0 ? 0.0 : 1.0);
            self.totalTouchDistanceText.center = (self.totalTouchDistanceText.alpha == 1.0 ? CGPointMake(self.totalTouchDistanceText.center.x, self.totalTouchDistanceText.center.y + dist) : CGPointMake(self.totalTouchDistanceText.center.x, self.totalTouchDistanceText.center.y - dist));
            
            self.timeLabelText.alpha = (self.timeLabelText.alpha == 1.0 ? 0.0 : 1.0);
            self.timeLabelText.center = (self.timeLabelText.alpha == 1.0 ? CGPointMake(self.timeLabelText.center.x, self.timeLabelText.center.y - dist) : CGPointMake(self.timeLabelText.center.x, self.timeLabelText.center.y + dist));
            self.timeTouchedText.alpha = (self.timeTouchedText.alpha == 1.0 ? 0.0 : 1.0);
            self.timeTouchedText.center = (self.timeTouchedText.alpha == 1.0 ? CGPointMake(self.timeTouchedText.center.x, self.timeTouchedText.center.y - dist) : CGPointMake(self.timeTouchedText.center.x, self.timeTouchedText.center.y + dist));
            self.totalTimeTouchedText.alpha = (self.totalTimeTouchedText.alpha == 1.0 ? 0.0 : 1.0);
            self.totalTimeTouchedText.center = (self.totalTimeTouchedText.alpha == 1.0 ? CGPointMake(self.totalTimeTouchedText.center.x, self.totalTimeTouchedText.center.y - dist) : CGPointMake(self.totalTimeTouchedText.center.x, self.totalTimeTouchedText.center.y + dist));
            
        }completion:nil];

        
        // Layer hiding the boxmap
        [UIView animateWithDuration:0.5 animations:^{
            layerView.alpha = (layerView.alpha == 1.0 ? 0.0 : 1.0);
        }];
    }
}

- (void)animateViewBlocks
{
    // Animate and show or hide the values on top of the block heatmap
    for (int y = 0; y < rowCount; y++) {
        for (int x = 0; x < columnCount; x++) {
            
            TFXBoxView *blockView = blockViews[y][x];
            
            [UIView animateWithDuration:0.25 animations:^{
                blockView.transform = CGAffineTransformMakeScale(0, 0);
            } completion:^(BOOL finished){
                [UIView animateWithDuration:0.25 animations:^{
                    blockView.transform = CGAffineTransformMakeScale(1, 1);
                }];
                
                if (showValues) {
                    int valueDigit = (int) (blockViews[y][x].value);
                    if (valueDigit == 0) {
                        [blockView setText: [NSString stringWithFormat: @""]];
                    } else {
                        [blockView setText: [NSString stringWithFormat: @"%d", valueDigit]];
                    }
                } else {
                    [blockView setText: [NSString stringWithFormat: @""]];
                }
            }];
        }
    }
    showValues = !showValues;
}

@end