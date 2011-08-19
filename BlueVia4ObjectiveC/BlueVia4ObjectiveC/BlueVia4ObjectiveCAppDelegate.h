//
//  BlueVia4ObjectiveCAppDelegate.h
//  BlueVia4ObjectiveC
//
//  Created by Bernhard Walter on 12.08.11.
//  Copyright 2011 O2. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BlueVia4ObjectiveCAppDelegate : NSObject <NSApplicationDelegate> {
@private
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
