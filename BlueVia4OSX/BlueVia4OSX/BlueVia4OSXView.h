//
//  BlueVia4OSXView.h
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

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "BlueVia.h"
#import "GoogleMaps.h"


@interface BlueVia4OSXView : NSView <BlueViaDelegate> {
    BlueVia *bluevia;
    BlueVia *bluevia2;
    
    NSImageView* logoView;
    NSTextField* verifierField;
    NSTextField* infoField;
    NSTextField* msisdnField;
    NSTextField* messageField;
    NSTextField* smsIdField;
    NSTextField* keywordsField;
    NSTextField* targetIdField;
    NSTextField* countryField;
    NSButton*    sandboxButton;
    NSButton*    adsImageButton;
    BOOL         textAds;
    NSMutableDictionary *trackSms;
    NSProgressIndicator *progressIndicator;
    
    GoogleMaps *map;
}
 
@property (nonatomic, retain) IBOutlet NSImageView *logoView;
@property (nonatomic, retain) IBOutlet NSTextField *verifierField;
@property (nonatomic, retain) IBOutlet NSTextField *infoField;
@property (nonatomic, retain) IBOutlet NSTextField *msisdnField;
@property (nonatomic, retain) IBOutlet NSTextField *messageField;
@property (nonatomic, retain) IBOutlet NSTextField *smsIdField;
@property (nonatomic, retain) IBOutlet NSTextField *targetIdField;
@property (nonatomic, retain) IBOutlet NSTextField *keywordsField;
@property (nonatomic, retain) IBOutlet NSTextField *countryField;
@property (nonatomic, retain) IBOutlet NSProgressIndicator *progressIndicator;

- (IBAction) sandboxClicked:(id)sender;

- (IBAction) requestTokenClicked:(id)sender;
- (IBAction) accessTokenClicked:(id)sender;

- (IBAction) sendSMSClicked:(id)sender;
- (IBAction) trackSMSClicked:(id)sender;

- (IBAction) locateHandset:(id)sender;
- (IBAction) userContext:(id)sender;

- (IBAction) adsImageClicked:(id)sender;
- (IBAction) ads2Clicked:(id)sender;
- (IBAction) ads3Clicked:(id)sender;

- (void) error:(NSDictionary*)data;
- (void) defaultResponse:(NSNumber*)status data:(NSDictionary*)data;
@end
