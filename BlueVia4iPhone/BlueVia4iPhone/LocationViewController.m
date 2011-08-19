//
//  FirstViewController.m
//  BlueVia4iPhone
//
//  Created by Bernhard Walter on 08.08.11.
//

//
//  The MIT license
//
//  Copyright (C) 2011 by Bernhard Walter ( @bernhard42 )
// 
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

//
//  Version 18.08.2011
//

#import "LocationViewController.h"
#import "BlueViaConfig.h"

@implementation LocationViewController

@synthesize mapView, progressIndicator, infoView, locationButton;


#pragma mark -
#pragma mark Initialisation

- (void)viewDidLoad {
    [super viewDidLoad];
    bluevia = [[BlueVia alloc] initWithConsumer:consumerKey1 
                                         secret:consumerSecret1
                                      adSpaceId:adSpaceId
                                        appName:appName  // keychain identifier
                                       delegate:self];
    config = (ConfigViewController*) [[[self tabBarController] viewControllers] objectAtIndex:2];
}

- (void) setButtonStates:(BOOL)on {
    CGFloat alpha;
    if (on) alpha = 1.0;
    else    alpha = 0.5;
    locationButton.enabled = on;
    locationButton.alpha = alpha;
}


- (void) viewWillAppear:(BOOL)animated {
    if (bluevia.accessToken == nil && config.accessToken != nil)
        [bluevia setAccessToken:config.accessToken];
    if (bluevia.accessToken) {
        [self setButtonStates:YES];
    } else {
        infoView.text = @"Authorization needed!";
        [self setButtonStates:NO];
    }
    [bluevia setSandbox:config.sandboxFlag];
    [super viewWillAppear:animated];    
}

- (void)dealloc {
    [super dealloc];
    SAFE_RELEASE(infoView)
    SAFE_RELEASE(bluevia)
    SAFE_RELEASE(progressIndicator)
    SAFE_RELEASE(locationButton)
    SAFE_RELEASE(mapView)
}


#pragma mark -
#pragma mark UI methods


- (IBAction) locateHandset:(id)sender {
    [progressIndicator startAnimating];
    [bluevia locateHandset];
}


#pragma mark -
#pragma mark BlueViaDelegate

- (void) error:(NSDictionary*)data {
    infoView.text = [NSString stringWithFormat:@"Error: %@\n%@", [data objectForKey:@"httpStatus"],
                     [data objectForKey:@"message"]]; 
}

- (void) updateMapWithLatitude:(NSString*) lat longitude:(NSString*) lng radius:(NSString*)rad {
    CLLocationCoordinate2D coordinate;
    
    MKCoordinateRegion region;
    coordinate.longitude = [lng doubleValue];
    coordinate.latitude = [lat doubleValue];
    region.center = coordinate;
    
    MKCoordinateSpan span = {0.01, 0.01};
    region.span = span;
    [mapView setDelegate:self];
    [mapView setRegion:region animated:YES]; 
    
    MKPointAnnotation *pa = [[MKPointAnnotation alloc] init];
    pa.coordinate = coordinate;
    pa.title = @"Your handset";
    [mapView addAnnotation:pa];
    [pa release];
    
//    MKCircle *circle = [MKCircle circleWithCenterCoordinate:coordinate radius:(lround([rad intValue] / 10.0))];
    MKCircle *circle = [MKCircle circleWithCenterCoordinate:coordinate radius:[rad intValue]];
    [mapView addOverlay:circle];
}

- (void) locateHandsetResponse:(NSNumber*)status data:(NSDictionary*)data {
    if ([status longValue] == kBlueviaSuccess) {
        NSDictionary *loc = [[data objectForKey:@"terminalLocation"] objectForKey:@"currentLocation"];

        NSString *lat = [[loc objectForKey:@"coordinates"] objectForKey:@"latitude"];
        NSString *lng = [[loc objectForKey:@"coordinates"] objectForKey:@"longitude"];
        NSString *rad = [loc objectForKey:@"accuracy"];
        [self updateMapWithLatitude:lat
                          longitude:lng
                             radius:rad];
        // NSLog(@"Status: %@", status);
        // NSLog(@"%@", data);
        self.infoView.text = [NSString stringWithFormat:@"Latitude: %@ \nLongitude: %@ \nAccuracy: %@", lat, lng, rad];
    } else {
        [self error:data];
    }
    [progressIndicator stopAnimating];
}

-(MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id)overlay 
{
    MKCircleView* circleView = [[[MKCircleView alloc] initWithOverlay:overlay] autorelease];
    circleView.fillColor = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.2];
    return circleView;
}

- (void) gotRequestToken:(NSNumber*)status data:(NSDictionary*)data     { /* NOT USED */ }
- (void) gotAccessToken:(NSNumber*)status data:(NSDictionary*)data      { /* NOT USED */ }
- (void) sendSmsResponse:(NSNumber*)status data:(NSDictionary*)data     { /* NOT USED */ }
- (void) trackSmsResponse:(NSNumber*)status data:(NSDictionary*)data    { /* NOT USED */ }
- (void) userContextResponse:(NSNumber*)status data:(NSDictionary*)data { /* NOT USED */ }
- (void) advertisingResponse:(NSNumber*)status data:(NSDictionary*)data { /* NOT USED */ }

#pragma mark -
#pragma mark Standard Interface methods


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

@end
