//
//  ViewController.h
//  Maps
//
//  Created by Anuj Shah on 9/27/16.
//  Copyright © 2016 Anuj Shah. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MKAnnotation.h>
#import <opencv2/highgui/cap_ios.h>

@interface ViewController : UIViewController<CvVideoCameraDelegate, MKMapViewDelegate>{
    CGPoint lastPoint;
    CGPoint moveBackTo;
    CGPoint currentPoint;
    CGPoint location;
    NSDate *lastClick;
     
    BOOL mouseSwiped;
    //UIImageView *drawImage; // used to draw on camera image
}

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet UITextView *steps;

@property (strong, nonatomic) NSString *allSteps;

@property (strong, nonatomic) IBOutlet UIImageView *cameraLayout;
@property (nonatomic, retain) UILabel *scanningLabel;

-(float)kilometersfromPlace:(CLLocationCoordinate2D)from andToPlace:(CLLocationCoordinate2D)to;
-(void)startCamera:(float)distance;
-(void)calculateDistance:(MKRoute*)routes;

-(void)displayOnCamera:(float)data;
-(void)displayLeftOrRight:(NSString*)direction;
+(UIImage*)drawFront:(UIImage*)image text:(NSString*)text atPoint:(CGPoint)point;
@end

