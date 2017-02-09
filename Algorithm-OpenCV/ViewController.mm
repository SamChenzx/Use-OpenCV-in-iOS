//
//  ViewController.mm
//  Algorithm-OpenCV
//
//  Created by Sam on 2/8/17.
//  Copyright © 2017 Sam. All rights reserved.
//

#import "ViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "UIImage+UIImage_OpenCV.h"
#include<vector>
#include<iostream>
#include<stdlib.h>
#include<stdio.h>
#import "ldb.h"
#import <opencv2/calib3d/calib3d.hpp>
#import <opencv2/opencv.hpp>
#import <opencv2/highgui.hpp>

using namespace std;
using namespace cv;

@interface ViewController () <CvVideoCameraDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (nonatomic) BOOL isCameraWorking;
@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (nonatomic, strong) UIImage *myImage;



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:_imageView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.grayscaleMode = NO;
    
    [self prepareForImagePickerController];
    
}

- (void)prepareForImagePickerController
{
    _imagePickerController = [[UIImagePickerController alloc] init];
    _imagePickerController.delegate = self;
    _imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    _imagePickerController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    _imagePickerController.allowsEditing = YES;
}

#pragma mark get image or video from camera
- (void)selectImageFromCamera
{
    _imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    _imagePickerController.videoMaximumDuration = 15;
    _imagePickerController.mediaTypes = @[(NSString *)kUTTypeMovie,(NSString *)kUTTypeImage];

    _imagePickerController.videoQuality = UIImagePickerControllerQualityTypeHigh;
    _imagePickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
    [self presentViewController:_imagePickerController animated:YES completion:nil];
}

#pragma mark get image or video from photo library
- (void)selectImageFromAlbum
{
    _imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:_imagePickerController animated:YES completion:nil];
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    NSString *mediaType=[info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]){
        self.imageView.image = info[UIImagePickerControllerEditedImage];
        UIImageWriteToSavedPhotosAlbum(self.imageView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) image: (UIImage *) image didFinishSavingWithError:(NSError *) error contextInfo: (void *)contextInf{
    if (error == nil) {
        [self.videoCamera start];
        _isCameraWorking = YES;
        [self.button setTitle:@"Stop" forState:UIControlStateNormal];
    }
}


- (IBAction)actionStart:(UIButton *)sender {
    if (!_isCameraWorking) {
        [self presentViewController:self.imagePickerController animated:YES completion:NULL];
        
    } else {
        [self.videoCamera stop];
        _isCameraWorking = NO;
        [self.button setTitle:@"Start" forState:UIControlStateNormal];
    }
}

- (UIImage *)scaleImage:(UIImage *)image toScale:(float)scaleSize

{
    UIGraphicsBeginImageContext(CGSizeMake(image.size.width * scaleSize, image.size.height * scaleSize));
    [image drawInRect:CGRectMake(0, 0, image.size.width * scaleSize, image.size.height * scaleSize)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

#pragma mark - Protocol CvVideoCameraDelegate

#ifdef __cplusplus
- (void)processImage:(Mat&)image;
{
    // Do some OpenCV stuff with the image
//    Mat image_copy;
//    cvtColor(image, image_copy, CV_BGRA2BGR);
//    
//    // invert image
//    bitwise_not(image_copy, image_copy);
//    cvtColor(image_copy, image, CV_BGR2BGRA);
    
    Mat image_1,image_2, mat_show, descriptors_1,descriptors_2, out_img;
    vector<Point2f> obj, scene;
    Mat img_gray;
    cv::cvtColor(image, img_gray, CV_RGB2GRAY);
    UIImage *image1 = self.imageView.image;
    image1 = [self scaleImage:image1 toScale:0.5];
    cv::cvtColor([UIImage cvMatFromUIImage:image1], image_1, CV_RGB2GRAY);
    
    image_2=img_gray;
    
    /**************************/   //measure for time
    clock_t start, finish;
    double duration, total_time = 0;
    /**************************/
    
    if(!image_1.data)
    {
        cout << "fail to load " <<  endl;
    }
    //-- Detect keypoint based on ORB
    ORB orb;
    vector<KeyPoint> keypoints_1,keypoints_2;
    
    orb(image_1, Mat(), keypoints_1, descriptors_1);
    start = clock();
    orb(image_2, Mat(), keypoints_2, descriptors_2);
    
    finish = clock();
    duration = (double)(finish - start) / CLOCKS_PER_SEC;
    printf("Pre: %.4f ms ",duration*1000);
    total_time += duration;
    
    
    //-- Compute LDB descriptors
    
    LDB ldb(48);
    ldb.compute(image_1, keypoints_1, descriptors_1, 1);
    start = clock();
    ldb.compute(image_2, keypoints_2, descriptors_2, 1);
    finish = clock();
    duration = (double)(finish - start) / CLOCKS_PER_SEC;
    printf("compute: %.4f ms ",duration*1000);
    total_time += duration;
    
    //-- Keypoint Matching
    DescriptorMatcher* pMatcher = new BFMatcher(NORM_HAMMING, false);
    vector< vector<DMatch> > matches;
    vector<DMatch> good_matches;
    
    start = clock();
    if (descriptors_2.rows) {
        pMatcher->knnMatch(descriptors_1, descriptors_2, matches, 2);
    } else {
        return;
    }
    
    
    finish = clock();
    duration = (double)(finish - start) / CLOCKS_PER_SEC;
    printf("match: %.4f ms ",duration*1000);
    total_time += duration;
    printf("total time: %.4f ms \n",total_time*1000);
    total_time = 0;
    
    delete pMatcher;
    
    for(unsigned int i=0; i<matches.size(); i++){
        if(matches[i][0].distance < 0.8*matches[i][1].distance){
            good_matches.push_back(matches[i][0]);
        }
    }
    drawMatches(image_1, keypoints_1, image_2, keypoints_2, good_matches, image);
    if(good_matches.size() < 4){
        // cout << "insufficient matches for RANSAC verification" << endl;
        return;
    }
    for(unsigned int i = 0; i < good_matches.size(); i++)
    {
        obj.push_back( keypoints_1[ good_matches[i].queryIdx ].pt );
        scene.push_back( keypoints_2[ good_matches[i].trainIdx ].pt );
    }
    
    Mat H = findHomography( obj, scene, CV_RANSAC );
    
    vector<Point2f> obj_corners(4), scene_corners(4);
    obj_corners[0] = cvPoint(0,0); obj_corners[1] = cvPoint( image_1.cols, 0 );
    obj_corners[2] = cvPoint( image_1.cols, image_1.rows ); obj_corners[3] = cvPoint( 0, image_1.rows );
    
    perspectiveTransform(obj_corners, scene_corners, H);
    
    line( image, scene_corners[0] + Point2f( image_1.cols, 0), scene_corners[1] + Point2f( image_1.cols, 0), Scalar(255, 0, 0), 4 );
    line( image, scene_corners[1] + Point2f( image_1.cols, 0), scene_corners[2] + Point2f( image_1.cols, 0), Scalar(255, 0, 0), 4 );
    line( image, scene_corners[2] + Point2f( image_1.cols, 0), scene_corners[3] + Point2f( image_1.cols, 0), Scalar(255, 0, 0), 4 );
    line( image, scene_corners[3] + Point2f( image_1.cols, 0), scene_corners[0] + Point2f( image_1.cols, 0), Scalar(255, 0, 0), 4 );

}

#endif



@end
