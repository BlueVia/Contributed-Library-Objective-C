//
//  BlueVia.m
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


#import "BlueVia.h"
#import "SBJson.h"
#import "OAToken_KeychainExtensions.h"
#import "BlueViaMutableURLRequest.h"

 
@implementation BlueVia

@synthesize delegate, consumer, appName, adSpaceId, requestToken, accessToken, realm;


- (id) initWithConsumer:(NSString*)consumerKey 
                 secret:(NSString*)consumerSecret
              adSpaceId:(NSString*)aAdSpaceId
                appName:(NSString*)aAppName
               delegate:aDelegate {
    if((self = [super init])) {
        consumer = [[OAConsumer alloc] initWithKey:consumerKey secret:consumerSecret];
        adSpaceId = aAdSpaceId;
        appName = aAppName;
        delegate = aDelegate;
        realm = @"BlueVia";
        sandbox = @"_Sandbox";

        accessToken = nil;
        requestCounter = 0;
    }
    
    return self;
}

- (void)dealloc {
    [super dealloc];
    
    SAFE_RELEASE(consumer)
    SAFE_RELEASE(requestToken)
    SAFE_RELEASE(accessToken)
    SAFE_RELEASE(realm)
    SAFE_RELEASE(adSpaceId)
    SAFE_RELEASE(appName)
}


#pragma mark -
#pragma mark Generic sign and send method

- (NSNumber*) signAndSend:(NSString*)requestUrl 
                  method:(NSString*)method 
                   token:(OAToken*)token 
              parameters:(NSDictionary*) parameters 
                    body:(NSString*) body 
            extraHeaders:(NSDictionary*) extraHeaders 
             formEncoded:(BOOL)isFormEncoded 
        finishSelector:(SEL)finishSelector { 

    OAMutableURLRequest *request = [[[BlueViaMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestUrl]
                                                                        consumer:[self consumer]
                                                                           token:token
                                                                           realm:nil    
                                                               signatureProvider:nil
                                                                       requestId:requestCounter] autorelease];    
    [request setHTTPMethod:method];
    
    for (id key in extraHeaders) {
        [request setValue:[extraHeaders objectForKey:key] forHTTPHeaderField:key];
    }

    NSMutableArray *params = [[[NSMutableArray alloc] init] autorelease];    
    NSMutableString *query = [NSMutableString stringWithString:@""];
    NSString* delim = @"?";
    
    for (id key in parameters) {
        if ([key isEqualToString:@"oauth_callback"]) {
            [request setOAuthParameterName:key withValue:[parameters objectForKey:key]];
        } else if ([key isEqualToString:@"oauth_verifier"]) {
            [request setOAuthParameterName:key withValue:[parameters objectForKey:key]];
        } else if (([key isEqualToString:@"version"] || [key isEqualToString:@"alt"]) && 
                   ([method isEqualToString:@"POST"]) )   {
            // for POST don't take version and alt as params, but as query parameter
            [query appendFormat:@"%@%@=%@", delim, 
                                            [key URLEncodedString], 
                                            [[parameters objectForKey:key] URLEncodedString]];
            delim = @"&";
        } else {
            [params addObject:[OARequestParameter requestParameterWithName:key 
                                                                     value:[parameters objectForKey:key]]];                            
        }
    }

    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [request URL], query]]];
    [request setHTTPBody:[body dataUsingEncoding: NSUTF8StringEncoding]];
    [request setParameters: params];
    
    OAAsynchronousDataFetcher *fetcher;
    fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:request
                                                               delegate:self
                                                      didFinishSelector:finishSelector
                                                        didFailSelector:@selector(signAndSend:didFailWithError:)];
    [fetcher start];
    return [NSNumber numberWithUnsignedInt:requestCounter++];
}

- (void)signAndSend:(OAServiceTicket *)ticket didFailWithError:(NSError *)error {
    NSLog(@"%@", error);
}

- (void) success:(NSDictionary *) result selector:(SEL)selector {
    // NSLog(@"Success:\n%@", result);        
    [delegate performSelector:selector
                   withObject:[NSNumber numberWithLong:kBlueviaSuccess]
                   withObject:result];   
}

- (void) failure:(long) httpStatus message:(NSString *) message selector:(SEL)selector {
    NSLog(@"Failure: %ld\n%@", httpStatus, message);
    [delegate performSelector:selector
                   withObject:[NSNumber numberWithInt:kBlueviaFailure]
                   withObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithLong:httpStatus], @"httpStatus", 
                               message, @"message",
                               nil]];
    
}

- (void) defaultResponse:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data selector:(SEL)selector{
    NSHTTPURLResponse* response = (NSHTTPURLResponse*) ticket.response;
    
    NSInteger status = [response statusCode];
    NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (status == 200) {
        SBJsonParser *parser = [SBJsonParser new];
        NSDictionary *result = [parser objectWithString:responseBody error:nil];
        [self success:result selector:selector];
        [parser release];
    } else {
        [self failure:status message:responseBody selector:selector];
    }
    SAFE_RELEASE(responseBody)
} 

- (void) setSandbox:(BOOL) isSandbox {
    if(isSandbox) {
        sandbox = @"_Sandbox";
    } else {
        sandbox = @"";
    }
}

#pragma mark -
#pragma mark oAuth Dance


- (void) fetchRequestToken:(NSString*) callback {
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:callback, @"oauth_callback", nil];
    [self signAndSend:kBlueviaRequestURL 
               method:@"POST"
                token:nil 
           parameters:parameters 
                 body:nil 
         extraHeaders:nil 
          formEncoded:NO
       finishSelector:@selector(fetchRequestToken:didFinishWithData:)];
}

- (void) fetchRequestToken:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
    NSHTTPURLResponse* response = (NSHTTPURLResponse*) ticket.response;
    NSInteger status = [response statusCode];
    NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (ticket.didSucceed) {
        requestToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
        NSString *authUrl = [NSString stringWithFormat:@"%@?oauth_token=%@", kBlueviaAuthorizeURL, requestToken.key];
        NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys: authUrl, @"authorizationUrl", nil];
        [self success:result selector:@selector(gotRequestToken:data:)];
    } else {
        [self failure:status message:responseBody selector:@selector(gotRequestToken:data:)];
    }
    SAFE_RELEASE(responseBody);
}

- (void) fetchAccessToken:(NSString*) verifier {
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:verifier, @"oauth_verifier", nil];
    [self signAndSend:kBlueviaAccessURL 
               method:@"POST"
                token:[self requestToken] 
           parameters:parameters 
                 body:nil 
         extraHeaders:nil 
          formEncoded:NO
       finishSelector:@selector(fetchAccessToken:didFinishWithData:)];
}

- (void) fetchAccessToken:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
    NSHTTPURLResponse* response = (NSHTTPURLResponse*) ticket.response;
    NSInteger status = [response statusCode];
    NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (ticket.didSucceed) {
        accessToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
        
        NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys: accessToken.key, @"AccessKey", 
                                                                           accessToken.secret, @"AccessSecret", nil];
        [self success:result selector:@selector(gotAccessToken:data:)];
        SAFE_RELEASE(requestToken)
    } else {
        [self failure:status message:responseBody selector:@selector(gotAccessToken:data:)];
    }
    SAFE_RELEASE(responseBody);
}

- (BOOL) loadAccessTokenFromKeychain {
    accessToken = [[OAToken alloc] initWithKeychainUsingAppName:appName serviceProviderName:@"BlueVia"];
    return ((accessToken.key != nil) && (accessToken.secret != nil));
}

- (BOOL) saveAccessTokenToKeychain {
    int ret = [accessToken storeInDefaultKeychainWithAppName:appName serviceProviderName:@"BlueVia"];
    return (ret == noErr);
}

- (NSArray*) getAccessToken {
    return [NSArray arrayWithObjects:accessToken.key, accessToken.secret ,nil];
}

- (void) setAccessTokenFromKey:(NSString *)key andSecret:(NSString *)secret {
    accessToken.key = key;
    accessToken.secret = secret;
}

#pragma mark -
#pragma mark Send SMS


//
// Send SMS
//

- (NSString*) constructJsonBody:(NSString*)msisdnStr message:(NSString*)message {
    NSMutableArray *recipients = [[NSMutableArray alloc] init];
    NSArray *msisdns = [msisdnStr componentsSeparatedByString:@","];
    NSString* msisdn;
    for(msisdn in msisdns) {
        msisdn = [msisdn stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [recipients addObject:[NSDictionary dictionaryWithObjectsAndKeys:msisdn, @"phoneNumber", nil]];
    }
    NSDictionary *origin = [NSDictionary dictionaryWithObject:accessToken.key forKey:@"alias"];
    NSDictionary *sms = [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObjectsAndKeys: recipients, @"address",
                                                            message, @"message",
                                                            origin, @"originAddress",
                                                            nil]
                                                    forKey:@"smsText"];
    
    SBJsonWriter *writer = [SBJsonWriter new];
    NSString* body = [writer stringWithObject:sms];
    SAFE_RELEASE(writer)
    SAFE_RELEASE(recipients)
    return body;
}

- (NSNumber *) sendSMS:(NSString*) msisdnStr message:(NSString*) message {
    NSMutableString* url = [NSMutableString stringWithFormat:@"%@", kBlueviaSmsOutboundURL];
    [url replaceOccurrencesOfString:@"#env#" withString:sandbox options:NSLiteralSearch range:NSMakeRange(0, [url length])];

    NSString* body = [self constructJsonBody:msisdnStr message:message];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:kBlueviaApiVersion, @"version", @"json", @"alt", nil];

    return [self signAndSend:url 
                      method:@"POST"
                       token:[self accessToken] 
                  parameters:parameters 
                        body:body
                extraHeaders:[NSDictionary dictionaryWithObjectsAndKeys:@"application/json", @"Content-Type", nil] 
                 formEncoded:NO
              finishSelector:@selector(sendSMS:didFinishWithData:)]; 
}

- (void) sendSMS:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
    NSHTTPURLResponse* response = (NSHTTPURLResponse*) ticket.response;
    NSInteger status = [response statusCode];
    
    if (status == 201) {
        NSString *loc;
        NSDictionary* responseHeaders = [response  allHeaderFields];
        NSArray *parts = [[responseHeaders objectForKey:@"Location"] componentsSeparatedByString:@"/"];
        loc = [parts objectAtIndex:[parts count] - 2];

        BlueViaMutableURLRequest *request = (BlueViaMutableURLRequest*) ticket.request;
        NSNumber *smsId = [NSNumber numberWithUnsignedInt:[request getRequestId]];
        NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:smsId, @"smsId", loc, @"location", nil];
        
        [self success:result selector:@selector(sendSmsResponse:data:)];
    } else {
        NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [self failure:status message:responseBody selector:@selector(sendSmsResponse:data:)];
        SAFE_RELEASE(responseBody)
    }

} 


//
// Track SMS
//

- (void) trackSMS:(NSString*) location {
    NSMutableString* url = [NSMutableString stringWithFormat:@"%@/%@/deliverystatus", kBlueviaSmsOutboundURL, location];
    [url replaceOccurrencesOfString:@"#env#" withString:sandbox options:NSLiteralSearch range:NSMakeRange(0, [url length])];

    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:kBlueviaApiVersion, @"version", @"json", @"alt", nil];
    
    [self signAndSend:url 
               method:@"GET"
                token:[self accessToken] 
           parameters:parameters 
                 body:nil
         extraHeaders:nil
          formEncoded:NO
       finishSelector:@selector(trackSMS:didFinishWithData:)]; 
}

- (void) trackSMS:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
    [self defaultResponse:ticket didFinishWithData:data selector:@selector(trackSmsResponse:data:)];
}


#pragma mark -
#pragma mark location

- (void) locateHandset {
    NSMutableString* url = [NSMutableString stringWithFormat:@"%@", kBlueviaLocationURL];
    [url replaceOccurrencesOfString:@"#env#" withString:sandbox options:NSLiteralSearch range:NSMakeRange(0, [url length])];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:kBlueviaApiVersion, @"version", @"json", @"alt", 
                                    [NSString stringWithFormat:@"alias:%@", accessToken.key],@"locatedParty", nil];
    
    [self signAndSend:url 
               method:@"GET"
                token:[self accessToken] 
           parameters:parameters 
                 body:nil
         extraHeaders:nil
          formEncoded:NO
       finishSelector:@selector(locateHandset:didFinishWithData:)];     
}

- (void) locateHandset:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
    [self defaultResponse:ticket didFinishWithData:data selector:@selector(locateHandsetResponse:data:)];
}


#pragma mark -
#pragma mark User Context

- (void) userContext {
    NSMutableString* url = [NSMutableString stringWithFormat:@"%@", kBlueviaUserContextURL];
    [url replaceOccurrencesOfString:@"#env#" withString:sandbox options:NSLiteralSearch range:NSMakeRange(0, [url length])];
    [url replaceOccurrencesOfString:@"#token#" withString:accessToken.key options:NSLiteralSearch range:NSMakeRange(0, [url length])];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:kBlueviaApiVersion, @"version", @"json", @"alt", nil];
    
    [self signAndSend:url 
               method:@"GET"
                token:[self accessToken] 
           parameters:parameters 
                 body:nil
         extraHeaders:nil
          formEncoded:NO
       finishSelector:@selector(userContext:didFinishWithData:)];     
}

- (void) userContext:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
    [self defaultResponse:ticket didFinishWithData:data selector:@selector(userContextResponse:data:)];
}


#pragma mark -
#pragma mark Advertising

- (NSString*) _generateUid {
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
    return [NSMakeCollectable(uuidStringRef) autorelease];
}

- (void) advertising:(OAToken*) token
             country:(NSString*) country 
            targetId:(NSString*) targetUserId 
              textAd:(BOOL)textAd 
           userAgent:(NSString*)userAgent  
         keywordList:(NSArray*)keywordList 
    protectionPolicy:(int)protectionPolicy {

    NSMutableString* url = [NSMutableString stringWithFormat:@"%@", kBlueviaAdvertisingURL];
    [url replaceOccurrencesOfString:@"#env#" withString:sandbox options:NSLiteralSearch range:NSMakeRange(0, [url length])];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];

    [parameters setObject:[self _generateUid] forKey:@"ad_request_id"];
    if (textAd)
        [parameters setObject:@"0104" forKey:@"ad_presentation"];
    else
        [parameters setObject:@"0101" forKey:@"ad_presentation"];
    if (![country isEqualToString:@""])
        [parameters setObject:country forKey:@"country"];
    if (![targetUserId isEqualToString:@""])
        [parameters setObject:targetUserId forKey:@"target_user_id"];
                    
    [parameters setObject:adSpaceId forKey:@"ad_space"];
    if (![userAgent isEqualToString:@""]) 
        [parameters setObject:userAgent forKey:@"user_agent"];
    else
        [parameters setObject:@"none" forKey:@"user_agent"];
    
    [parameters setObject:[NSString stringWithFormat:@"%d", protectionPolicy] forKey:@"protection_policy"];
    if (keywordList) {
        [parameters setObject:[keywordList componentsJoinedByString:@"|"] forKey:@"keywords"];
    }  

    [parameters setObject:kBlueviaApiVersion forKey:@"version"];

    [self signAndSend:url 
               method:@"POST"
                token:token 
           parameters:parameters 
                 body:nil
         extraHeaders:[NSDictionary dictionaryWithObjectsAndKeys:@"application/x-www-form-urlencoded", @"Content-Type", nil]
          formEncoded:YES
       finishSelector:@selector(advertising:didFinishWithData:)];         
    
    SAFE_RELEASE(parameters)
}

- (void) advertising:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
    NSHTTPURLResponse* response = (NSHTTPURLResponse*) ticket.response;
    
    NSInteger status = [response statusCode];
    NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (status == 201) {
        TBXML * tbxml = [TBXML tbxmlWithXMLString:responseBody];
        NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:[self adResponseToDict:tbxml.rootXMLElement], 
                                                                          @"adResponse", 
                                                                          nil];
        [self success:result selector:@selector(advertisingResponse:data:)];
    } else {
        [self failure:status message:responseBody selector:@selector(advertisingResponse:data:)];
    }
    SAFE_RELEASE(responseBody)
}

- (void) advertising2:(NSString*) country 
             targetId:(NSString*) targetUserId 
               textAd:(BOOL)textAd 
            userAgent:(NSString*)userAgent  
          keywordList:(NSArray*)keywordList 
     protectionPolicy:(int)protectionPolicy {

    [self advertising:nil 
              country:country
             targetId:targetUserId
               textAd:textAd
            userAgent:userAgent
          keywordList:keywordList
     protectionPolicy:protectionPolicy];
}

- (void) advertising3:(BOOL)textAd 
            userAgent:(NSString*)userAgent  
          keywordList:(NSArray*)keywordList 
     protectionPolicy:(int)protectionPolicy {

    [self advertising:accessToken 
              country:@""
             targetId:@""
               textAd:textAd
            userAgent:userAgent
          keywordList:keywordList
     protectionPolicy:protectionPolicy];
}


- (NSDictionary*) adResponseToDict:(TBXMLElement *)element {
    TBXMLElement *element2;
    NSMutableDictionary* dictElem = [[[NSMutableDictionary alloc] init] autorelease] ;
    
    if ((element2 = element->firstChild)) {
        do {
            NSString *key = [[TBXML elementName:element2] substringFromIndex:4];
            NSString *value = [dictElem objectForKey:key];
            if (value) { // elementName exists multiple times -> change to array 
                if ([value isKindOfClass:[NSMutableArray class]]) {
                    [(NSMutableArray*)value addObject:[self adResponseToDict:element2]];                    
                } else {
                    [dictElem setObject:[NSMutableArray arrayWithObjects:value, [self adResponseToDict:element2], nil] forKey:key];
                }
            } else {
                [dictElem setObject:[self adResponseToDict:element2] forKey:key];                
            }
        } while ((element2 = element2->nextSibling));
    } 
    TBXMLAttribute * attribute = element->firstAttribute;
    while (attribute) {
        NSString *key = [TBXML attributeName:attribute];
        if (![key isEqualToString:@"xmlns:NS1"]) {
            [dictElem setObject:[TBXML attributeValue:attribute] forKey:key];
        }
        attribute = attribute->next;
    }
    NSString * description = [TBXML textForElement:element];
    if (description && ![description isEqualToString:@""]) {
        [dictElem setObject:description forKey:@"name"];
    }
    
    return dictElem; 
}

@end
