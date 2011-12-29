//
//  OAuthViewController.m
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

#import "ConfigViewController.h"
#import "OAToken_KeychainExtensions.h"
#import "BlueViaConfig.h"

@implementation ConfigViewController

@synthesize verifierField, infoView, progressIndicator, sandboxSwitch, authView, 
            sandboxFlag, accessToken;

#pragma mark -
#pragma mark Initialisation


- (void) awakeFromNib {
    [super awakeFromNib];
    sandboxFlag = NO;
    accessToken = nil;
    
    bluevia = [[BlueVia alloc] initWithConsumer:consumerKey1 
                                         secret:consumerSecret1
                                      adSpaceId:adSpaceId
                                        appName:appName  // keychain identifier
                                       delegate:self];
    
    if([bluevia loadAccessTokenFromKeychain])
        accessToken = bluevia.accessToken;
    else
        [[self tabBarController] setSelectedIndex:2];

    [bluevia setSandbox:sandboxFlag];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (accessToken) {
        infoView.text = @"Authorization already done!";
    } else {
        infoView.text = @"Authorization needed!";
    }
}


- (void)dealloc
{
    [super dealloc];
    SAFE_RELEASE(verifierField)
    SAFE_RELEASE(bluevia)
    SAFE_RELEASE(progressIndicator)
    SAFE_RELEASE(infoView)
    SAFE_RELEASE(sandboxSwitch)
    SAFE_RELEASE(authView)
}


#pragma mark -
#pragma mark UI methods

- (IBAction) sandboxClicked:(id)sender{
    UISwitch * sw = (UISwitch*) sender;
    sandboxFlag = sw.on;
    [bluevia setSandbox:sw.on];
}

- (IBAction) requestTokenClicked:(id)sender {
    [progressIndicator startAnimating];
    [bluevia fetchRequestToken:@"oob"];    
}

- (IBAction) accessTokenClicked:(id)sender {
    NSString *verifier = [verifierField text];
    if (![verifier isEqualToString:@""]) {
        [progressIndicator startAnimating];
        [bluevia fetchAccessToken:verifier];    
    } else {
        self.infoView.text = @"ERROR: Add verifier first"; 
    }
}


#pragma mark -
#pragma mark BlueViaDelegate


- (void) error:(NSDictionary*)data {
    infoView.text = [NSString stringWithFormat:@"Error: %@\n%@", [data objectForKey:@"httpStatus"],
                      [data objectForKey:@"message"]]; 
}

- (void) defaultResponse:(NSNumber*)status data:(NSDictionary*)data {
    NSLog(@"Status: %@", status);
    NSLog(@"%@", data);        
    if ([status longValue] == kBlueviaSuccess) {
        self.infoView.text = [NSString stringWithFormat:@"%@", data];
    } else {
        [self error:data];
    }
}

- (void) gotRequestToken:(NSNumber*)status data:(NSDictionary*)data {
    NSLog(@"Status: %@", status);
    NSLog(@"%@", data);
    if ([status longValue] == kBlueviaSuccess) {
        self.infoView.text = [NSString stringWithFormat:@"%@", data];
        NSString *authUrl = [data objectForKey:@"authorizationUrl"];
        [authView setDelegate:self];
        [authView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:authUrl]]];
        authView.hidden = NO;
    } else {
        [self error:data];
    }
    [progressIndicator startAnimating];
}

- (void) gotAccessToken:(NSNumber*)status data:(NSDictionary*)data {
    [self defaultResponse:status data:data];
    
    NSString *accessKey = [data objectForKey:@"AccessKey"];
    NSString *accessSecret = [data objectForKey:@"AccessSecret"];
    accessToken = [[OAToken alloc] initWithKey:accessKey secret:accessSecret];

    [bluevia setAccessToken:accessToken];
    [bluevia saveAccessTokenToKeychain];
    
    [progressIndicator stopAnimating];
}

- (void) locateHandsetResponse:(NSNumber*)status data:(NSDictionary*)data { /* NOT USED */ }
- (void) sendSmsResponse:(NSNumber*)status data:(NSDictionary*)data       { /* NOT USED */ }
- (void) trackSmsResponse:(NSNumber*)status data:(NSDictionary*)data      { /* NOT USED */ }
- (void) userContextResponse:(NSNumber*)status data:(NSDictionary*)data   { /* NOT USED */ }
- (void) advertisingResponse:(NSNumber*)status data:(NSDictionary*)data   { /* NOT USED */ }


#pragma mark -
#pragma mark WebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSString* url = webView.request.URL.absoluteString;
    NSArray* parts = [url componentsSeparatedByString:@"/"];

    NSLog(@"%@", url);
    NSString *verifier = @"n/a";
    if([parts count] == 9) {
        NSString *k1 = (NSString*)[parts objectAtIndex:4]; 
        NSString *k2 = (NSString*)[parts objectAtIndex:5]; 
        
        if([k1 isEqualToString:@"authorise"] && [k2 isEqualToString:@"success"]) {
            verifier = [(NSString*)[parts objectAtIndex:7] URLDecodedString];
            [bluevia fetchAccessToken:verifier];
            authView.hidden = YES;
        }
    }
}

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
