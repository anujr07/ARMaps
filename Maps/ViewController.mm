//
//  ViewController.m
//  Maps
//
//  Created by Anuj Shah on 9/27/16.
//  Copyright © 2016 Anuj Shah. All rights reserved.
//

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

#import "ViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <opencv2/highgui/cap_ios.h>
using namespace cv;
#include "opencv2/opencv.hpp"

@interface ViewController (){
    CvVideoCamera* videoCamera;
    MKDirectionsHandler mk;
    NSMutableArray * dict;
}

@property (nonatomic, retain) CvVideoCamera* videoCamera;

@end

@implementation ViewController{
    
CLPlacemark *thePlacemark;
MKRoute *routeDetails;
    
//CLLocationManager *locationManager;
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    _mapView.delegate = self;

    
    dict  = [[NSMutableArray alloc]init];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)addressSearch:(UITextField *)sender {
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder geocodeAddressString:sender.text completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
            NSLog(@"%@", error);
        } else {
            thePlacemark = [placemarks lastObject];
            float spanX = 1.00725;
            float spanY = 1.00725;
            MKCoordinateRegion region;
            region.center.latitude = thePlacemark.location.coordinate.latitude;
            region.center.longitude = thePlacemark.location.coordinate.longitude;
            region.span = MKCoordinateSpanMake(spanX, spanY);
            [self.mapView setRegion:region animated:YES];
            [self addAnnotation:thePlacemark];
        }
    }];
}

- (void)addAnnotation:(CLPlacemark *)placemark {
    MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
    point.coordinate = CLLocationCoordinate2DMake(placemark.location.coordinate.latitude, placemark.location.coordinate.longitude);
    point.title = [placemark.addressDictionary objectForKey:@"Street"];
    point.subtitle = [placemark.addressDictionary objectForKey:@"City"];
    [self.mapView addAnnotation:point];
}

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    // If it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    // Handle any custom annotations.
    if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
        // Try to dequeue an existing pin view first.
        MKPinAnnotationView *pinView = (MKPinAnnotationView*)[self.mapView dequeueReusableAnnotationViewWithIdentifier:@"CustomPinAnnotationView"];
        if (!pinView)
        {
            // If an existing pin view was not available, create one.
            pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"CustomPinAnnotationView"];
            pinView.canShowCallout = YES;
        } else {
            pinView.annotation = annotation;
        }
        return pinView;
    }
    return nil;
}

- (IBAction)findDirection:(UIBarButtonItem *)sender {
    MKDirectionsRequest *directionsRequest = [[MKDirectionsRequest alloc] init];
    MKPlacemark *placemark = [[MKPlacemark alloc] initWithPlacemark:thePlacemark];
    [directionsRequest setSource:[MKMapItem mapItemForCurrentLocation]];
    [directionsRequest setDestination:[[MKMapItem alloc] initWithPlacemark:placemark]];
    directionsRequest.transportType = MKDirectionsTransportTypeAutomobile;
    MKDirections *directions = [[MKDirections alloc] initWithRequest:directionsRequest];
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        if (error) {
            NSLog(@"Error %@", error.description);
        } else {
            routeDetails = response.routes.lastObject;
            [self.mapView addOverlay:routeDetails.polyline];
            self.allSteps = @"";
            for (int i = 0; i < routeDetails.steps.count-1; i++) {
                MKRouteStep *step = [routeDetails.steps objectAtIndex:i];
                MKRouteStep *step2 = [routeDetails.steps objectAtIndex:i+1];
                NSString *newStep = step.instructions;
                
                [dict addObject:newStep];
                self.allSteps = [self.allSteps stringByAppendingString:newStep];
                self.allSteps = [self.allSteps stringByAppendingString:@"\n\n"];
                self.steps.text = self.allSteps;
            }
            [self calculateDistance:routeDetails];
        }
    }];
    
}

-(void)calculateDistance:(MKRoute*)routes{
    [self startCamera];
    float distance = LONG_MAX;
    for(int i =0 ;i< routes.steps.count ;i++){
        // start coordinate of step1
        MKRouteStep * step = [routes.steps objectAtIndex:0];
        MKRouteStep * step1 = [routes.steps objectAtIndex:1];
        CLLocationCoordinate2D startCoordinate;
        [step.polyline getCoordinates:&startCoordinate range:NSMakeRange(0, 1)];
        
        // end coordinate of step1
        CLLocationCoordinate2D endCoordinate;
        [step1.polyline getCoordinates:&endCoordinate range:NSMakeRange(step1.polyline.pointCount - 1, 1)];
        
        distance = [self kilometersfromPlace:startCoordinate andToPlace:endCoordinate];
        
        if (distance <= 0.1) {
            [self displayOnCamera:(float)distance];
            if ([step1.instructions rangeOfString:@"left" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                [self displayLeftOrRight:(NSString*)@"left"];
            }else if([step1.instructions rangeOfString:@"right" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                [self displayLeftOrRight:(NSString*)@"right"];
            }else {
                    [self displayLeftOrRight:(NSString*)@"waiting for direction"];
            }
        }
    }
}

-(void)displayLeftOrRight:(NSString*)direction{
    UILabel *tempLabel = [[UILabel alloc] initWithFrame:CGRectMake(300, 150, 220, 130)];
    [self setScanningLabel:tempLabel];
    [_scanningLabel setBackgroundColor:[UIColor clearColor]];
    [_scanningLabel setFont:[UIFont fontWithName:@"Courier" size: 18.0]];
    [_scanningLabel setText:direction];
    [_scanningLabel setTextColor:[UIColor redColor]];
    [[self view]addSubview:_scanningLabel];
}

-(void)startCamera{
    //using the  CVVideoCamera class of opnecv framework to use the AVFoundation for camera
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:_cameraLayout];
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.grayscaleMode = NO;
    self.videoCamera.delegate = self;
    
    [self.videoCamera start];
}

-(void)displayOnCamera:(float)data{
    UILabel *tempLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, 50, 120, 30)];
    [self setScanningLabel:tempLabel];
    [_scanningLabel setBackgroundColor:[UIColor clearColor]];
    [_scanningLabel setFont:[UIFont fontWithName:@"Courier" size: 18.0]];
    [_scanningLabel setText:[[NSNumber numberWithFloat:data]stringValue]];
    [_scanningLabel setTextColor:[UIColor redColor]];
    [[self view]addSubview:_scanningLabel];
}

-(float)kilometersfromPlace:(CLLocationCoordinate2D)from andToPlace:(CLLocationCoordinate2D)to  {
    
    CLLocation *userloc = [[CLLocation alloc]initWithLatitude:from.latitude longitude:from.longitude];
    CLLocation *dest = [[CLLocation alloc]initWithLatitude:to.latitude longitude:to.longitude];
    
    CLLocationDistance dist = [userloc distanceFromLocation:dest]/1000;
    
    NSString *distance = [NSString stringWithFormat:@"%f",dist];
    
    return [distance floatValue];
    
}

-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    MKPolylineRenderer  * routeLineRenderer = [[MKPolylineRenderer alloc] initWithPolyline:routeDetails.polyline];
    routeLineRenderer.strokeColor = [UIColor redColor];
    routeLineRenderer.lineWidth = 5;
    return routeLineRenderer;
}



- (IBAction)clearRoute:(UIBarButtonItem *)sender {
    self.steps.text = nil;
    [self.mapView removeOverlay:routeDetails.polyline];
}




@end
