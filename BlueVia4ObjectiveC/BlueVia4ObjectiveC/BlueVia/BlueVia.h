//
//  BlueVia.h
//  BlueVia4ObjectiveC
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
#import "OAuthConsumer.h"
#import "TBXML.h"

static NSString *const kBlueviaRequestURL     = @"https://api.bluevia.com/services/REST/Oauth/getRequestToken";
static NSString *const kBlueviaAccessURL      = @"https://api.bluevia.com/services/REST/Oauth/getAccessToken";
static NSString *const kBlueviaAuthorizeURL   = @"https://connect.bluevia.com/en/authorise";
static NSString *const kBlueviaSmsOutboundURL = @"https://api.bluevia.com/services/REST/SMS#env#/outbound/requests";
static NSString *const kBlueviaLocationURL    = @"https://api.bluevia.com/services/REST/Location#env#/TerminalLocation";
static NSString *const kBlueviaUserContextURL = @"https://api.bluevia.com/services/REST/Directory#env#/alias:#token#/UserInfo";
static NSString *const kBlueviaAdvertisingURL = @"https://api.bluevia.com/services/REST/Advertising#env#/simple/requests";
static NSString *const kBlueviaApiVersion     = @"v1";

static int const kBlueviaSuccess =  0;
static int const kBlueviaFailure = -1;



@protocol BlueViaDelegate <NSObject>
- (void) gotRequestToken:(NSNumber*)status data:(NSDictionary*)data;
- (void) gotAccessToken:(NSNumber*)status data:(NSDictionary*)data;
- (void) sendSmsResponse:(NSNumber*)status data:(NSDictionary*)data;
- (void) trackSmsResponse:(NSNumber*)status data:(NSDictionary*)data;
- (void) locateHandsetResponse:(NSNumber*)status data:(NSDictionary*)data;
- (void) userContextResponse:(NSNumber*)status data:(NSDictionary*)data;
- (void) advertisingResponse:(NSNumber*)status data:(NSDictionary*)data;
@end





@interface BlueVia : NSObject {
    OAConsumer *consumer;
    NSString* adSpaceId;
    NSString* appName;
    OAToken *requestToken;
    OAToken *accessToken;
    NSString* realm;
    NSString* sandbox;
    
    id delegate;
    
    uint requestCounter;
}

@property (nonatomic, retain) NSString *realm;
@property (nonatomic, retain) NSString *adSpaceId;
@property (nonatomic, retain) NSString *appName;
@property (nonatomic, retain) OAConsumer *consumer;
@property (nonatomic, retain) OAToken *requestToken;
@property (nonatomic, retain) OAToken *accessToken;
@property (nonatomic, retain) id delegate;

- (id) initWithConsumer:(NSString*) consumerKey 
                 secret:(NSString*) consumerSecret 
              adSpaceId:(NSString*) adSpaceId
                appName:(NSString*) aAppName
               delegate:(id)aDelegate;

- (void) setSandbox:(BOOL) isSandbox;

- (void) fetchRequestToken:(NSString*) callback;
- (void) fetchAccessToken:(NSString*) verifier;
- (BOOL) loadAccessTokenFromKeychain;
- (BOOL) saveAccessTokenToKeychain;
- (NSArray*) getAccessToken;
- (void) setAccessTokenFromKey:(NSString*) key andSecret:(NSString*) secret;

- (NSNumber *) sendSMS:(NSString*) msisdnStr 
               message:(NSString*) message;

- (void) trackSMS:(NSString*) location;

- (void) locateHandset;

- (void) userContext;

- (void) advertising:(OAToken*) token
             country:(NSString*) country 
            targetId:(NSString*) targetUserId 
              textAd:(BOOL)textAd 
           userAgent:(NSString*)userAgent  
         keywordList:(NSArray*)keywordList 
    protectionPolicy:(int)protectionPolicy;

- (void) advertising2:(NSString*) country 
             targetId:(NSString*) targetUserId 
               textAd:(BOOL)textAd 
            userAgent:(NSString*)userAgent  
          keywordList:(NSArray*)keywordList 
     protectionPolicy:(int)protectionPolicy;

- (void) advertising3:(BOOL)textAd 
            userAgent:(NSString*)userAgent  
          keywordList:(NSArray*)keywordList 
     protectionPolicy:(int)protectionPolicy;

- (NSDictionary*) adResponseToDict:(TBXMLElement *)element;

- (void) success:(NSDictionary *) result 
        selector:(SEL)selector;
- (void) failure:(long) HttpStatus 
         message:(NSString *) message 
        selector:(SEL)selector;
@end
