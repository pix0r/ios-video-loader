//
//  FYViewController.m
//  VideoLoader
//
//  Created by Mike Matz on 2/17/12.
//  Copyright (c) 2012 Flying Yeti. All rights reserved.
//

#import "FYViewController.h"

@implementation FYViewController

@synthesize urlField, logView, progressView, connection, localPath, request = _request, response = _response, totalBytesRead = _totalBytesRead, bytesRead, totalBytesExpected = _totalBytesExpected;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)writeLog:(NSString *)message {
	NSString *stripped = [message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	if (self.logView.text == nil) {
		self.logView.text = stripped;
	} else {
		self.logView.text = [self.logView.text stringByAppendingFormat:@"\n%@", stripped];
	}
	NSLog(@"%@", stripped);
	
	// Scroll to bottom
	CGPoint bottomOffset = CGPointMake(0, self.logView.contentSize.height - self.logView.bounds.size.height);
	[self.logView setContentOffset:bottomOffset animated:YES];
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
	if (error != nil) {
		[self writeLog:[NSString stringWithFormat:@"Error saving video: %@", error]];
	} else {
		[self writeLog:[NSString stringWithFormat:@"Saved video at path: %@", videoPath]];
	}
	self.progressView.progress = 0.0;
}

// Taken from http://snippets.dzone.com/posts/show/3038
- (NSString *)stringFromFileSize:(int)theSize {
	float floatSize = theSize;
	if (theSize<1023)
		return([NSString stringWithFormat:@"%i bytes",theSize]);
	floatSize = floatSize / 1024;
	if (floatSize<1023)
		return([NSString stringWithFormat:@"%1.1f KB",floatSize]);
	floatSize = floatSize / 1024;
	if (floatSize<1023)
		return([NSString stringWithFormat:@"%1.1f MB",floatSize]);
	floatSize = floatSize / 1024;
	
	// Add as many as you like
	
	return([NSString stringWithFormat:@"%1.1f GB",floatSize]);
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)cancel:(id)sender {
	[self writeLog:@"Canceling"];
	[self.connection cancel];
	self.connection = nil;
	self.request = nil;
	self.response = nil;
	self.progressView.progress = 0.0;
	self.totalBytesRead = 0;
	self.totalBytesExpected = -1;
	[self.urlField resignFirstResponder];
}

- (IBAction)loadVideo:(id)sender {
	[self.urlField resignFirstResponder];
	
	if (self.connection != nil) {
		[self writeLog:@"Already have an open connection!"];
		return;
	}
	
	NSURL *aURL = [NSURL URLWithString:self.urlField.text];

	NSString *tempDir = NSTemporaryDirectory();
	NSString *fileName = [[aURL pathComponents] lastObject];
	NSString *tempFilePath = [tempDir stringByAppendingPathComponent:fileName];
	[self writeLog:[NSString stringWithFormat:@"Saving to file: %@", tempFilePath]];
	if ([[NSFileManager defaultManager] fileExistsAtPath:tempFilePath]) {
		NSError *error = nil;
		
		[self writeLog:@"File exists; removing first"];
		[[NSFileManager defaultManager] removeItemAtPath:tempFilePath error:&error];
	}
	[[NSFileManager defaultManager] createFileAtPath:tempFilePath contents:nil attributes:nil];
	self.localPath = tempFilePath;

	NSURLRequest *req = [NSURLRequest requestWithURL:aURL];
	self.progressView.progress = 0.0;
	self.totalBytesExpected = -1;
	self.totalBytesRead = 0;
	self.connection = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:YES];
}

- (IBAction)populateFull:(id)sender {
	self.urlField.text = @"http://pixor.net/temp/how-to-eat-vicodin.m4v";
}

- (IBAction)populateShort:(id)sender {
	self.urlField.text = @"http://pixor.net/temp/vicodin-short.m4v";
}

- (void)updateBytesDisplay {
	if (self.totalBytesExpected > 0) {
		self.bytesRead.text = [NSString stringWithFormat:@"%@ of %@",
							   [self stringFromFileSize:self.totalBytesRead],
							   [self stringFromFileSize:self.totalBytesExpected]];
	} else {
		self.bytesRead.text = [NSString stringWithFormat:@"%@ read", [self stringFromFileSize:self.totalBytesRead]];
	}
}

- (void)setTotalBytesRead:(unsigned long long)totalBytesRead {
	_totalBytesRead = totalBytesRead;
	[self updateBytesDisplay];
}

- (void)setTotalBytesExpected:(unsigned long long)totalBytesExpected {
	_totalBytesExpected = totalBytesExpected;
	[self updateBytesDisplay];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[self writeLog:[NSString stringWithFormat:@"Failed with error: %@", error]];
	[self cancel:nil];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[self writeLog:[NSString stringWithFormat:@"Received response; reading %d bytes", response.expectedContentLength]];
	self.response = response;
	self.totalBytesExpected = response.expectedContentLength;
	NSLog(@"expected content length: %lld", self.response.expectedContentLength);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	NSFileHandle *fp = [NSFileHandle fileHandleForWritingAtPath:self.localPath];
	[fp seekToEndOfFile];
	[fp writeData:data];
	NSLog(@"Received %d bytes", [data length]);
	
	self.totalBytesRead += [data length];
	
	unsigned long long e = self.response.expectedContentLength;
	float p = (float)self.totalBytesRead / (float)e;
	NSLog(@"%llu / %llu = %e", self.totalBytesRead, e, p);
	if (e > 0) {
		self.progressView.progress = p;
	} else {
		self.progressView.progress = 0.5;
	}
	
	[fp closeFile];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(self.localPath)) {
		[self writeLog:@"Connection finished loading; attemping to save"];
		UISaveVideoAtPathToSavedPhotosAlbum(self.localPath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
	} else {
		[self writeLog:@"Video is not compatible with saved photos album!"];
	}
	self.request = nil;
	self.response = nil;
	self.connection = nil;
	self.progressView.progress = 1.0;
}

@end
