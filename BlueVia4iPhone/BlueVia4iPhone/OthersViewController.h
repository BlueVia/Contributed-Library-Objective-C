//
//  SecondViewController.h
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

#import <UIKit/UIKit.h>
#import "BlueVia.h"
#import "ConfigViewController.h"


@interface OthersViewController : UIViewController <UITextFieldDelegate, BlueViaDelegate> {
    BlueVia *bluevia;
    UITextView* infoView;
    UITextField* msisdnField;
    UITextField* messageField;
    UITextField* smsIdField;
    UIActivityIndicatorView *progressIndicator;
    NSMutableDictionary *trackSms;
    
    UIButton* sendSMSButton;
    UIButton* trackSMSButton;
    UIButton* advertisingButton;
    UIButton* userContextButton;    

    ConfigViewController* config;
}

@property (nonatomic, retain) IBOutlet UITextView *infoView;
@property (nonatomic, retain) IBOutlet UITextField *msisdnField;
@property (nonatomic, retain) IBOutlet UITextField *messageField;
@property (nonatomic, retain) IBOutlet UITextField *smsIdField;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *progressIndicator;
@property (nonatomic, retain) IBOutlet UIButton* sendSMSButton;
@property (nonatomic, retain) IBOutlet UIButton* trackSMSButton;
@property (nonatomic, retain) IBOutlet UIButton* advertisingButton;
@property (nonatomic, retain) IBOutlet UIButton* userContextButton;    

- (IBAction) sendSMSClicked:(id)sender;
- (IBAction) trackSMSClicked:(id)sender;
- (IBAction) userContextClicked:(id)sender;
- (IBAction) ads3Clicked:(id)sender;

@end
