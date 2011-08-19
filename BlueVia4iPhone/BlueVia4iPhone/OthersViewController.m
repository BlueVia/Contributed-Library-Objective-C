//
//  SecondViewController.m
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

#import "OthersViewController.h"
#import "BlueViaConfig.h"

@implementation OthersViewController

@synthesize infoView, msisdnField, messageField, smsIdField, progressIndicator,
            sendSMSButton, trackSMSButton, userContextButton, advertisingButton;

#pragma mark -
#pragma mark Initialisation

- (void)viewDidLoad {
    [super viewDidLoad];
    bluevia = [[BlueVia alloc] initWithConsumer:consumerKey1 
                                         secret:consumerSecret1
                                      adSpaceId:adSpaceId
                                        appName:appName  // keychain identifier
                                       delegate:self];
    
    trackSms = [[NSMutableDictionary alloc] init];
    
    config = (ConfigViewController*) [[[self tabBarController] viewControllers] objectAtIndex:2];
}

- (void) setButtonStates:(BOOL)on {
    CGFloat alpha;
    if (on) alpha = 1.0;
    else    alpha = 0.5;
    sendSMSButton.enabled = on;
    sendSMSButton.alpha = alpha;
    trackSMSButton.enabled = on;
    trackSMSButton.alpha = alpha;
    userContextButton.enabled = on;
    userContextButton.alpha = alpha;
    advertisingButton.enabled = on;
    advertisingButton.alpha = alpha;
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
    SAFE_RELEASE(trackSms)
    SAFE_RELEASE(bluevia)
    SAFE_RELEASE(msisdnField)
    SAFE_RELEASE(messageField)
    SAFE_RELEASE(smsIdField)
    SAFE_RELEASE(progressIndicator)
    SAFE_RELEASE(infoView)
    SAFE_RELEASE(sendSMSButton)
    SAFE_RELEASE(trackSMSButton)
    SAFE_RELEASE(advertisingButton)
    SAFE_RELEASE(userContextButton)
}


#pragma mark -
#pragma mark UI methods

- (IBAction) sendSMSClicked:(id)sender {
    NSString *msisdns = msisdnField.text;
    NSString *message = messageField.text;
    
    if (![msisdns isEqualToString:@""] && ![message isEqualToString:@""]) {
        [progressIndicator startAnimating];
        NSNumber *smsId = [bluevia sendSMS:msisdns message:message];  
        infoView.text = [NSString stringWithFormat:@"SMS Id: %@", smsId];
    } else {
        infoView.text = @"ERROR: Add Mobile Number(s) and Message first";
    }
}

- (IBAction) trackSMSClicked:(id)sender {
    NSString *smsId = smsIdField.text;
    NSString *location = [trackSms objectForKey:smsId];
    NSLog(@"%@ \n %@", smsId, trackSms);
    if (![smsId isEqualToString:@""] && location) {
        [progressIndicator startAnimating];
        [bluevia trackSMS:location];
        infoView.text = [NSString stringWithFormat:@"Track SMS Id: %@", smsId];
    } else {
        infoView.text = @"ERROR: Add correct SMS Id first";
    }
}

- (IBAction) userContextClicked:(id)sender {
    [progressIndicator startAnimating];
    [bluevia userContext];
}


- (IBAction) ads3Clicked:(id)sender {
    [progressIndicator startAnimating];
    NSArray *kwList = nil;
    [bluevia advertising3:NO
                userAgent:@"" 
              keywordList:kwList 
         protectionPolicy:1];    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}


#pragma mark -
#pragma mark BlueViaDelegate

- (void) showError:(NSDictionary*)data {
    infoView.text = [NSString stringWithFormat:@"Error: %@\n%@", [data objectForKey:@"httpStatus"],
                     [data objectForKey:@"message"]];            
}

- (void) defaultResponse:(NSNumber*)status data:(NSDictionary*)data {
    NSLog(@"Status: %@", status);
    NSLog(@"%@", data);        
    if ([status longValue] == kBlueviaSuccess) {
        infoView.text =[NSString stringWithFormat:@"%@", data];
    } else {
        [self showError:data];
    }
}

- (void) sendSmsResponse:(NSNumber*)status data:(NSDictionary*)data {
    NSLog(@"Status: %@", status);
    NSLog(@"%@", data);
    
    if ([status longValue] == kBlueviaSuccess) {
        NSString* smsId = [NSString stringWithFormat:@"%@", [data objectForKey:@"smsId"]];
        NSString* smsLocation = [data objectForKey:@"location"];
        [trackSms setValue:smsLocation forKey:smsId];
        NSLog(@"%@", trackSms);
        infoView.text = [NSString stringWithFormat:@"%@", data];
        smsIdField.text = [NSString stringWithFormat:@"%@", smsId];
    } else {
        [self showError:data];
    }
    [progressIndicator stopAnimating];
}

- (void) trackSmsResponse:(NSNumber*)status data:(NSDictionary*)data {
    if ([status longValue] == kBlueviaSuccess) {
        [self defaultResponse:status data:data];
    } else {
        [self showError:data];
    }
    [progressIndicator stopAnimating];
}

- (void) userContextResponse:(NSNumber*)status data:(NSDictionary*)data {
    if ([status longValue] == kBlueviaSuccess) {
        [self defaultResponse:status data:data];
    } else {
        [self showError:data];
    }
    [progressIndicator stopAnimating];
}

- (void) advertisingResponse:(NSNumber*)status data:(NSDictionary*)data {
    NSString *creativeElement = [[[[data objectForKey:@"adResponse"] objectForKey:@"ad"] objectForKey:@"resource"] objectForKey:@"creative_element"]; 
    
    if ([status longValue] == kBlueviaSuccess) {
        [self defaultResponse:status data:[NSString stringWithFormat:@"creative_element = %@", creativeElement]];    
    } else {
        [self showError:data];
    }
    [progressIndicator stopAnimating];
}

- (void) locateHandsetResponse:(NSNumber*)status data:(NSDictionary*)data { /* NOT USED */ }
- (void) gotRequestToken:(NSNumber*)status data:(NSDictionary*)data       { /* NOT USED */ }
- (void) gotAccessToken:(NSNumber*)status data:(NSDictionary*)data        { /* NOT USED */ }

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
