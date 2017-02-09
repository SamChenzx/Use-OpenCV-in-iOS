//
//  ViewController.h
//  Algorithm-OpenCV
//
//  Created by Sam on 2/8/17.
//  Copyright © 2017 Sam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/highgui/cap_ios.h>
#import <opencv2/highgui.hpp>
#include <stdio.h>
#include <stdlib.h>
#import "fastMotionDetection/MCDWrapper.hpp"

using namespace cv;

@interface ViewController : UIViewController 

@property (nonatomic, retain) CvVideoCamera* videoCamera;


@end
