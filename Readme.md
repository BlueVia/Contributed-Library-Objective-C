Keywords:			MultiMarkdown, Markdown, XML, XHTML, XSLT, PDF   
CSS:				css/print.css
CSS:  				css/doc-less.css



Feel free to download and mess around with this app, it may or may not be updated regularly, when it is we will publicise on our twitter feed (@BlueVia)


## Get your X Code environment prepared


The library and the demo applications are written with XCode 4

The library is in the folder "BlueVia4ObjectiveC" and includes 4 external packages:

- [OACounsumer](http://code.google.com/p/oauth/): The core oAuth routines (Obj-c 2.0), slightly changed to support BlueVia (see github history)
- [TBXML](http://http://www.tbxml.co.uk/TBXML/TBXML_Free.html): A small XML library to work with XML results from the Advertising API
- [SBJSON](/https://github.com/stig/json-framework): A small JSON library
- [SFHFKeychainUtils](http://gorgando.com/blog/tag/sfhfkeychainutils): A small library to easily read and write from the iPhone keychain 

Additionally the sample code contains two projects using the BlueVia library

- An iPhone application (tested with iOS SDK 4.2, 4.3). You can find it in the folder "BlueVia4iPhone"
- An OS X application (tested with OS X SDK 10.6). You can find it in the folder "BlueVia4OSX"

Both projects use the files in the library (linked and not copied to the project folders)

The three TabBar icons in the iPhone app are taken from [GLYPHISH](http://glyphish.com/)
	
	
## Sample usage of all BlueVia Objective C routines


### Setup and personal settings

Rename BlueViaConfig_template.h to BlueViaConfig.h

For the iPhone app it looks like:

        static NSString* consumerKey1 =    @"xxxxxxxxxxxxxxxx";
        static NSString* consumerSecret1 = @"xxxxxxxxxxxx";
        static NSString* adSpaceId =       @"xxxxx";
        static NSString* appName =         @"BlueVia4iPhone";	
    
And for the OS X app it has two more keys for a 2 legged Advertising call:

        static NSString* consumerKey1 =    @"xxxxxxxxxxxxxxxx";
        static NSString* consumerSecret1 = @"xxxxxxxxxxxx";
        static NSString* consumerKey2 =    @"xxxxxxxxxxxxxxxx";
        static NSString* consumerSecret2 = @"xxxxxxxxxxxx";
        static NSString* adSpaceId =       @"xxxxx";
        static NSString* appName =         @"BlueVia4OSX";
    
Create an application at the [BlueVia portal](https://www.bluevia.com) using all available API's.
The value of the field "key" needs to be added as "consumerKey1" in both apps.  And the value of the field "secret" needs to be added as "consumerSecret1" in both apps.
If you want to use 2-legged oAuth for Advertising, you additionally need to create an app in the BlueVia portal that only uses the Advertising API. Add "key" and "secret" in the same way to "consumerKey2" and "consumerSecret2".
In bosth cases add the ad Space Id that you receive with your app credentials.


### Initialize the BlueVia object 

First, create the bluevia object

        //  3 legged credentials, oAuth DAnce required 
        bluevia = [[BlueVia alloc] initWithConsumer:consumerKey1
                                             secret:consumerSecret1
                                          adSpaceId:adSpaceId
                                            appName:appName
                                           delegate:self];

Then try to retrieve the access token from the keychain (if it was written to it after the last successful appauthorisation)

        if([bluevia loadAccessTokenFromKeychain]) {
            NSLog(@"Access Token loaded from Keychain");
        } else {
            NSLog(@"No Access Token found in Keychain"); 
        }

And set the bluvia Sandbox property to "YES" (no access to the real network) or "NO" (access the real network, e.g. send real SMS)

        [bluevia setSandbox:"YES"];

Note: The BlueVia library assumes that your code implements the BlueViaDelegate protocol:

        @protocol BlueViaDelegate <NSObject>
        - (void) gotRequestToken:(NSNumber*)status data:(NSDictionary*)data;
        - (void) gotAccessToken:(NSNumber*)status data:(NSDictionary*)data;
        - (void) sendSmsResponse:(NSNumber*)status data:(NSDictionary*)data;
        - (void) trackSmsResponse:(NSNumber*)status data:(NSDictionary*)data;
        - (void) locateHandsetResponse:(NSNumber*)status data:(NSDictionary*)data;
        - (void) userContextResponse:(NSNumber*)status data:(NSDictionary*)data;
        - (void) advertisingResponse:(NSNumber*)status data:(NSDictionary*)data;
        @end
 
Each call to a bluevia method is asynchronous. The library will call (for both success and failure case) the respective protocol method in your code.

     
### oAuth Dance

First step is to get a Request Token

        [bluevia fetchRequestToken:@"oob"]; 
        
You will receive the result in your implementation of "gotRequestToken", e.g.:

        - (void) gotRequestToken:(NSNumber*)status data:(NSDictionary*)data {
            if ([status longValue] == kBlueviaSuccess) {
                NSString *authUrl = [data objectForKey:@"authorizationUrl"];
                // do something with the authUrl, e.g. open Safari with it
            } else {
                NSLog(@"Error requesting Requrest Token ...");
            }
        }

After successful Authorisation the oAuth portal will provide the user with a verifier, e.g. "437456". This verifier needs to handed over to the next call:

        NSString *verifier = @"437456";
        [bluevia fetchAccessToken:verifier];

This time the result will be provided via "gotAccessToken" methos of the BlueViaDelegate protocol. Your implementation could look like this:

        - (void) gotAccessToken:(NSNumber*)status data:(NSDictionary*)data {
            - (void) gotAccessToken:(NSNumber*)status data:(NSDictionary*)data {
                [self defaultResponse:status data:data];                                 // optional
                NSString *accessKey = [[data objectForKey:@"AccessKey"] retain];         // optional
                NSString *accessSecret = [[data objectForKey:@"AccessSecret"] retain];   // optional

                [bluevia saveAccessTokenToKeychain];
            }
        }

Here you could derive the Access Token Key and Secret, if you want to store it somewhere else or simply use the "saveAccessTokenToKeychain" method.

	
### Send SMS and track delivery

        NSString *msisdns = @"447760xxxxxx,447763yyyyyy";
        NSString *message = @"Hello World";

        if ([msisdns isNotEqualTo:@""] && [message isNotEqualTo:@""]) {
            NSNumber *smsId = [bluevia sendSMS:msisdns message:message];    
        }

Since the call is asynchronous, the routine gives back an id for the request. This id can be used in the "sendSmsResponse" method to associate a delivery URL (smsLocation) with its respective "send SMS " call, e.g. :

        - (void) sendSmsResponse:(NSNumber*)status data:(NSDictionary*)data {
            if ([status longValue] == kBlueviaSuccess) {
                NSNumber* smsId = [data objectForKey:@"smsId"];
                NSString* smsLocation = [data objectForKey:@"location"];
                [trackSms setValue:smsLocation forKey:[NSString stringWithFormat:@"%@", smsId]];
            }
        }

Accordingly, to receive poll for the delivery notification, you would call (given that smsId is the one from above):

        NSString *location = [trackSms objectForKey:smsId];
        if ([smsId isNotEqualTo:@""] && location) {
            [bluevia trackSMS:location];
        }

and the respective BlueViaDelegate method to implement is:

        - (void) trackSmsResponse:(NSNumber*)status data:(NSDictionary*)data;

Note: to use the real radio network, call:
		
        [bluevia setSandbox:"NO"];

This holds for all BlueVia calless below.


### User Context API

The actual call is:

        [bluevia userContext];

and the respective BlueViaDelegate method to implement is:
    
        - (void) userContextResponse:(NSNumber*)status data:(NSDictionary*)data;
        
        
### Location API

The actual call is:

        [bluevia locateHandset];

and the respective BlueViaDelegate method to implement is:
    
        - (void) locateHandsetResponse:(NSNumber*)status data:(NSDictionary*)data;


### Advertising API (3 legged oAuth)

The actual call is:

        NSString *kwStr = @"sports,entertainment";
        NSArray *kwList = nil;
        if ([kwStr isNotEqualTo:@""]) {
            kwList = [kwStr componentsSeparatedByString:@","];
        }
        [bluevia advertising3:textAds
                    userAgent:@"" 
                  keywordList:kwList 
             protectionPolicy:1];    

 and the respective BlueViaDelegate method to implement is:

         - (void) advertisingResponse:(NSNumber*)status data:(NSDictionary*)data;
         
