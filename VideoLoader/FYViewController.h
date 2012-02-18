//
//  FYViewController.h
//  VideoLoader
//
//  Created by Mike Matz on 2/17/12.
//  Copyright (c) 2012 Flying Yeti. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FYViewController : UIViewController <NSURLConnectionDelegate>

- (IBAction)cancel:(id)sender;
- (IBAction)loadVideo:(id)sender;
- (IBAction)populateFull:(id)sender;
- (IBAction)populateShort:(id)sender;

@property (nonatomic, retain) IBOutlet UITextField *urlField;
@property (nonatomic, retain) IBOutlet UIProgressView *progressView;
@property (nonatomic, retain) IBOutlet UITextView *logView;
@property (nonatomic, retain) IBOutlet UILabel *bytesRead;
@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSURLRequest *request;
@property (nonatomic, retain) NSURLResponse *response;
@property (nonatomic, copy) NSString *localPath;
@property (nonatomic, assign) unsigned long long totalBytesExpected;
@property (nonatomic, assign) unsigned long long totalBytesRead;

@end
