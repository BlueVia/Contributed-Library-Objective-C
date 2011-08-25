//
//  BlueVia4OSXView.m
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

#import "BlueVia4OSXView.h"
#import "OAToken.h"
#import "OAToken_KeychainExtensions.h"
#import "BlueViaConfig.h"

@implementation BlueVia4OSXView

@synthesize verifierField, infoField, msisdnField, messageField, smsIdField, 
            targetIdField, countryField, keywordsField, logoView, progressIndicator, adsWebView;

-(id) initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if(self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(finishedLaunching:)
                                                     name:NSApplicationDidFinishLaunchingNotification object:nil];        
    }
    return self;
}

- (void)finishedLaunching:(NSNotification *)aNotification {
    BOOL sandbox = YES;
    
    //  3 legged credentials, oAuth DAnce required 
    bluevia = [[BlueVia alloc] initWithConsumer:consumerKey1
                                         secret:consumerSecret1
                                      adSpaceId:adSpaceId
                                        appName:appName
                                       delegate:self];
    //  2 legged credentials
    bluevia2 = [[BlueVia alloc] initWithConsumer:consumerKey2
                                          secret:consumerSecret2
                                       adSpaceId:adSpaceId
                                         appName:appName
                                        delegate:self];
    
    if([bluevia loadAccessTokenFromKeychain]) {
        [infoField setStringValue:@"Access Token loaded from Keychain"];
    } else {
        [infoField setStringValue:@"No Access Token found in Keychain.\n\n\n1) Click on \"Request Token\" and follow the authorisation pages in the browser \n\n2) After successful authorisation copy the \"PIN Code\" into the \"Verifier\" field above\n\n3) Finally press \"Access Token\" and the authorisation is finished and stored in your Mac's keychain"]; 
    }
    [bluevia setSandbox:sandbox];
    [bluevia2 setSandbox:sandbox];
    
    trackSms = [[NSMutableDictionary alloc] init];
    NSImage *imageFromBundle = [NSImage imageNamed:@"BlueVia_Logo.png"];
    [logoView setImage: imageFromBundle];
    textAds = NO;
    
    NSString *adsPage = @"<html><body style=\"font-size:13px; font-family:'Lucida Grande'\"><b>Web view:</b></br>Image ads will be shown here</body></html>";
    [[adsWebView mainFrame] loadHTMLString:adsPage baseURL:[NSURL URLWithString:@"http://www.example.com"]];

} 

- (void) dealloc {
    SAFE_RELEASE(trackSms)
    SAFE_RELEASE(bluevia)
    SAFE_RELEASE(bluevia2)
    SAFE_RELEASE(logoView)
    SAFE_RELEASE(verifierField)
    SAFE_RELEASE(infoField)
    SAFE_RELEASE(msisdnField)
    SAFE_RELEASE(messageField)
    SAFE_RELEASE(smsIdField)
    SAFE_RELEASE(targetIdField)
    SAFE_RELEASE(keywordsField)
    SAFE_RELEASE(countryField) 
    SAFE_RELEASE(progressIndicator)
    SAFE_RELEASE(adsWebView)
}


#pragma mark -
#pragma mark BlueVia Delegates

- (void) defaultResponse:(NSNumber*)status data:(NSDictionary*)data {
    NSLog(@"Status: %@", status);
    NSLog(@"%@", data);        
    if ([status longValue] == kBlueviaSuccess) {
        [infoField setStringValue:[NSString stringWithFormat:@"%@", data]];
    } else {
        [self error:data];
    }
}

- (void) error:(NSDictionary*)data {
    [infoField setStringValue:[NSString stringWithFormat:@"Error: %@\n%@", [data objectForKey:@"httpStatus"],
                                                                           [data objectForKey:@"message"]]];            
}

- (void) gotRequestToken:(NSNumber*)status data:(NSDictionary*)data {
    NSLog(@"Status: %@", status);
    NSLog(@"%@", data);
    if ([status longValue] == kBlueviaSuccess) {
        [infoField setStringValue:[NSString stringWithFormat:@"%@", data]];
        NSString *authUrl = [data objectForKey:@"authorizationUrl"];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:authUrl]];
    } else {
        [self error:data];
    }
    [progressIndicator stopAnimation:self];
}
- (void) gotAccessToken:(NSNumber*)status data:(NSDictionary*)data {
    [self defaultResponse:status data:data];
    // NSString *accessKey = [[data objectForKey:@"AccessKey"] retain];
    // NSString *accessSecret = [[data objectForKey:@"AccessSecret"] retain];
    [bluevia saveAccessTokenToKeychain];
    [progressIndicator stopAnimation:self];
}

- (void) sendSmsResponse:(NSNumber*)status data:(NSDictionary*)data {
    NSLog(@"Status: %@", status);
    NSLog(@"%@", data);

    if ([status longValue] == kBlueviaSuccess) {
        NSNumber* smsId = [data objectForKey:@"smsId"];
        NSString* smsLocation = [data objectForKey:@"location"];
        [trackSms setValue:smsLocation forKey:[NSString stringWithFormat:@"%@", smsId]];
        [infoField setStringValue:[NSString stringWithFormat:@"%@", data]];
        [smsIdField setStringValue:[NSString stringWithFormat:@"%@", smsId]];
    } else {
        [self error:data];
    }
    [progressIndicator stopAnimation:self];
}

- (void) trackSmsResponse:(NSNumber*)status data:(NSDictionary*)data {
    [self defaultResponse:status data:data];
    [progressIndicator stopAnimation:self];
}

- (void) locateHandsetResponse:(NSNumber*)status data:(NSDictionary*)data {
    [self defaultResponse:status data:data];
    NSDictionary *loc = [[data objectForKey:@"terminalLocation"] objectForKey:@"currentLocation"];
    
    if (map) {
        [map closeWindow];
    }
    map = [[GoogleMaps alloc] initWithLatitude:[[loc objectForKey:@"coordinates"] objectForKey:@"latitude"]
                                                  longitude:[[loc objectForKey:@"coordinates"] objectForKey:@"longitude"]
                                                     radius:[loc objectForKey:@"accuracy"]];
    [progressIndicator stopAnimation:self];
}

- (void) userContextResponse:(NSNumber*)status data:(NSDictionary*)data {
    [self defaultResponse:status data:data];
    [progressIndicator stopAnimation:self];
}
     
- (void) advertisingResponse:(NSNumber*)status data:(NSDictionary*)data {
    
    if ([status longValue] == kBlueviaSuccess) {
        NSDictionary *creativeElement = [[[[data objectForKey:@"adResponse"] objectForKey:@"ad"] objectForKey:@"resource"] objectForKey:@"creative_element"]; 
        [self defaultResponse:status data:[NSString stringWithFormat:@"creative_element = %@", creativeElement]];
        NSString *adsPage;
        if ([[creativeElement objectForKey:@"type"] isEqualToString:@"image"]) {
            NSString *url = [[creativeElement objectForKey:@"attribute"] objectForKey:@"name"];
            NSString *interact = [[[creativeElement objectForKey:@"interaction"] objectForKey:@"attribute"] objectForKey:@"name"];
            adsPage = [NSString stringWithFormat:@"<html><body><a href=\"%@\"><img src=\"%@\"></img></a></body></html>",
                       interact, url];
            NSLog(@"%@", adsPage);
        } else {
            adsPage = @"<html><body style=\"font-size:13px; font-family:'Lucida Grande'\"><b>Web view:</b></br>Image ads will be shown here</body></html>";
        }
        [[adsWebView mainFrame] loadHTMLString:adsPage baseURL:[NSURL URLWithString:@"http://www.example.com"]];
    } else {
        [self error:data];
    }
    [progressIndicator stopAnimation:self];
}


#pragma mark -
#pragma mark UI methods

- (IBAction) sandboxClicked:(id)sender{
    [bluevia setSandbox:([(NSButton*)sender state] == NSOnState)];
}

- (IBAction) requestTokenClicked:(id)sender {
    [progressIndicator startAnimation:self];
    [bluevia fetchRequestToken:@"oob"];    
}

- (IBAction) accessTokenClicked:(id)sender {
    NSString *verifier = [verifierField stringValue];
    if ([verifier isNotEqualTo:@""]) {
        [progressIndicator startAnimation:self];
        [bluevia fetchAccessToken:verifier];    
    } else {
        [infoField setStringValue:@"ERROR: Add verifier first"];        
    }
}
- (IBAction) sendSMSClicked:(id)sender {
    NSString *msisdns = [msisdnField stringValue];
    NSString *message = [messageField stringValue];
    
    if ([msisdns isNotEqualTo:@""] && [message isNotEqualTo:@""]) {
        [progressIndicator startAnimation:self];
        NSNumber *smsId = [bluevia sendSMS:msisdns message:message];    
        [infoField setStringValue:[NSString stringWithFormat:@"SMS Id: %@", smsId]];
    } else {
        [infoField setStringValue:@"ERROR: Add Mobile Number(s) and Message first"];
    }
}

- (IBAction) trackSMSClicked:(id)sender {
    NSString *smsId = [smsIdField stringValue];
    NSString *location = [trackSms objectForKey:smsId];
    
    if ([smsId isNotEqualTo:@""] && location) {
        [progressIndicator startAnimation:self];
        [bluevia trackSMS:location];
        [infoField setStringValue:[NSString stringWithFormat:@"Track SMS Id: %@", smsId]];
    } else {
        [infoField setStringValue:@"ERROR: Add correct SMS Id first"];
    }
}

- (IBAction) locateHandset:(id)sender {
    [progressIndicator startAnimation:self];
    [bluevia locateHandset];
}

- (IBAction) userContext:(id)sender {
    [progressIndicator startAnimation:self];
    [bluevia userContext];
}

- (IBAction) adsImageClicked:(id)sender {
    textAds = ([sender state] == NSOffState);
    NSLog(@"%d", textAds); 
}

- (IBAction) ads3Clicked:(id)sender {
    [progressIndicator startAnimation:self];
    NSString *kwStr = [keywordsField stringValue];
    NSArray *kwList = nil;
    if ([kwStr isNotEqualTo:@""]) {
        kwList = [kwStr componentsSeparatedByString:@","];
    }
    [bluevia advertising3:textAds
                userAgent:@"" 
              keywordList:kwList 
         protectionPolicy:1];    
}

- (IBAction) ads2Clicked:(id)sender {
    NSString *kwStr = [keywordsField stringValue];
    NSArray *kwList = nil;
    if ([kwStr isNotEqualTo:@""]) {
        kwList = [kwStr componentsSeparatedByString:@","];
    }
    NSString *country = [countryField stringValue];
    NSString *targetId = [targetIdField stringValue];
    if (country && [country isNotEqualTo:@""]) {
        [progressIndicator startAnimation:self];
        [bluevia2 advertising2:country 
                      targetId:targetId 
                        textAd:textAds
                     userAgent:@"" 
                   keywordList:kwList 
              protectionPolicy:1];
    } else {
        [infoField setStringValue:@"ERROR: Add country first"];
    }
}


@end
