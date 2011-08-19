//
//  GoogleMaps.h
//  BlueVia4OSX
//
//  Created by Bernhard Walter on 05.08.11.
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

#import "GoogleMaps.h"
#import <WebKit/WebKit.h>

@implementation GoogleMaps

@synthesize window, latitude, longitude, radius, js;

- (id) initWithLatitude:(NSString*) lat longitude:(NSString*)lng radius:(NSString*)rad {
    self = [super init];
    if (self) {
        latitude = [lat copy];
        longitude = [lng copy];
        radius = [rad copy];
 
        if ([NSBundle loadNibNamed:@"GoogleMaps" owner:self]) {
            NSString *htmlPath = [[NSBundle mainBundle] pathForResource:@"GoogleMaps" ofType:@"html"];
            [[mapView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:htmlPath]]]; 
            [[[mapView mainFrame] frameView] setAllowsScrolling:NO];
            [mapView setFrameLoadDelegate:self];
            [mapView setNeedsDisplay:YES];
            js = [mapView windowScriptObject];
            
        }
    }
    return self;
}

- (void) dealloc {
    [super dealloc];
    SAFE_RELEASE(latitude)
    SAFE_RELEASE(longitude)
    SAFE_RELEASE(radius)
    SAFE_RELEASE(js)
    SAFE_RELEASE(mapView)
    SAFE_RELEASE(zoomIn)
    SAFE_RELEASE(zoomOut)
    SAFE_RELEASE(window)
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame*)frame {
    if(frame == [sender mainFrame]) {
        NSString *jsCmd = [NSString stringWithFormat:@"locate(%@, %@, %@);", latitude, longitude, radius];
        [js evaluateWebScript:jsCmd];
    }
}

-(IBAction)zoomIn:sender{
    [js evaluateWebScript:@"zoomIn();"];
}

-(IBAction)zoomOut:sender{
    [js evaluateWebScript:@"zoomOut();"];
}

- (void) closeWindow {
    if (window) {
        [window close];
    }
}
@end
