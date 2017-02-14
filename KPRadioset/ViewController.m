//
//  ViewController.m
//  KPRadioset
//
//  Created by Павел Квачан on 1/20/17.
//  Copyright © 2017 Павел Квачан. All rights reserved.
//

#import "ViewController.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "KPRecorder.h"

NSString * const KPServiceType = @"KPServiceType";
//<MCBrowserViewControllerDelegate, MCSessionDelegate, KPRecorderDelegate>

@interface ViewController () <KPRecorderDelegate>
{
//    MCPeerID  *_myPeerID;
////    MCSession *_mySession;
////    
////    MCBrowserViewController *_browserViewController;
////    MCAdvertiserAssistant   *_advertiser;
    
    KPRecorder *_recorder;
    UIProgressView *_progressView;
    
    CGFloat _minLevel;
}


@end

@implementation ViewController


#pragma mark lifeCycle
//
//- (id) init
//{
//    self = [super init];
//    
//    if (self != nil)
//    {
//        
//    }
//    return self;
//}


#pragma mark -

- (IBAction)recordBtn:(id)sender {
    if (_recorder.recording)
    {
        [_recorder stop];
        _progressView.progress = .0;
        [sender setTitle:NSLocalizedString(@"Record", @"")
                forState:UIControlStateNormal];
    }
    else
    {
        [_recorder start];
        [sender setTitle:NSLocalizedString(@"Stop", @"") forState:UIControlStateNormal];
    }
    
}


#pragma mark -

//- (void)recorder:(KPRecorder *)recorder
//          levels:(NSArray *)lvls
//{
//    CGFloat level = [[lvls objectAtIndex:0] floatValue];
//    if (level < _minLevel)
//    {
//        _minLevel = level;
//        _progressView.progress = 0.0;
//    }
//    else
//    {
//        _progressView.progress = (_minLevel - level) / _minLevel;
//    }
//    
//}


#pragma mark -

- (void)viewDidAppear:(BOOL)animated
{
}

- (void) viewDidDisappear:(BOOL) animated
{
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation
{
    return YES;
}


- (void)loadView
{
    [super loadView];
    
    _recorder = [[KPRecorder alloc] init];
    _recorder.delegate = self;
    
    _minLevel = 0.0;
}



/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
 // Custom initialization
 }
 return self;
 }
 */


// Implement loadView to create a view hierarchy programmatically, without using a nib.
//- (void)loadView
//{
//    [super loadView];
//
//    self.navigationItem.title = NSLocalizedString(@"audio recording", @"");
//    
//    CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
//    
//    UIView *contentView = [[UIView alloc] initWithFrame:screenRect];
//    contentView.autoresizesSubviews = YES;
//    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
//    contentView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.8];
//    
//    self.view = contentView;
//    
//    CGRect rct = self.navigationController.navigationBar.bounds;
//    rct.origin.y += 3.0;
//    UIButton *_btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//    _btn.frame = rct;
//    _btn.autoresizingMask = UIViewAutoresizingFlexibleWidth;
//    [_btn setTitle:NSLocalizedString(@"Record", @"") forState:UIControlStateNormal];
//    [_btn addTarget:self action:@selector(recordBtnPress:) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:_btn];
//    
//    rct.origin.y += rct.size.height + 6.0;
//    rct.size.height /= 2.0;
//    UIProgressView *_pv = [[UIProgressView alloc] initWithFrame:rct];
//    _pv.autoresizingMask = UIViewAutoresizingFlexibleWidth;
//    _pv.progress = 0.0;
//    [self.view addSubview:_pv];
//}


/*
 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 - (void)viewDidLoad {
 [super viewDidLoad];
 }
 */

/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

@end


//- (void)viewDidLoad
//{
//    [super viewDidLoad];
//    
//    _myPeerID = [[MCPeerID alloc] initWithDisplayName:[UIDevice currentDevice].name];
//    
//    _mySession = [[MCSession alloc] initWithPeer:_myPeerID
//                                securityIdentity:nil
//                            encryptionPreference:MCEncryptionNone];
//    
//    _mySession.delegate = self;
//    
//    _browserViewController = [[MCBrowserViewController alloc] initWithServiceType:KPServiceType
//                                                                          session:_mySession];
//    
//    _browserViewController.delegate = self;
//    
//    
//    _advertiser = [[MCAdvertiserAssistant alloc] initWithServiceType:KPServiceType
//                                                       discoveryInfo:nil
//                                                             session:_mySession];
//    
//    [_advertiser start];
//}
//
//
//- (void)viewDidAppear:(BOOL)animated
//{
//    [super viewDidAppear:animated];
//    
//    [self showBrowserViewController];
//}
//
//
//- (void)showBrowserViewController
//{
//    if (_browserViewController != nil)
//    {
//        [self presentViewController:_browserViewController
//                           animated:YES
//                         completion:nil];
//    }
//}
//
//
//
//#pragma mark - MCBrowserViewControllerDelegate -
//
//- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController
//{
//    [browserViewController dismissViewControllerAnimated:YES
//                                              completion:^
//     {
//         NSLog(@"browserViewControllerDidFinish");
//     }];
//}
//
//
//- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController
//{
//    [browserViewController dismissViewControllerAnimated:YES
//                                              completion:^
//     {
//         NSLog(@"browserViewControllerWasCancelled");
//     }];
//}
//
//
//
//
//#pragma mark - MCSessionDelegate -
//
//// Remote peer changed state.
//- (void)session:(MCSession *)session
//           peer:(MCPeerID *)peerID
// didChangeState:(MCSessionState)state
//{
//    switch (state)
//    {
//        case MCSessionStateConnecting:
//            NSLog(@"connecting");
//            break;
//            
//        case MCSessionStateConnected:
//            NSLog(@"connected");
//            break;
//            
//        case MCSessionStateNotConnected:
//            NSLog(@"NotConnected");
//            break;
//            
//        default:
//            break;
//    }
//}
//
//// Received data from remote peer.
//- (void)session:(MCSession *)session
// didReceiveData:(NSData *)data
//       fromPeer:(MCPeerID *)peerID
//{
//    
//}
//
//// Received a byte stream from remote peer.
//- (void)    session:(MCSession *)session
//   didReceiveStream:(NSInputStream *)stream
//           withName:(NSString *)streamName
//           fromPeer:(MCPeerID *)peerID
//{
//    
//}
//
//// Start receiving a resource from remote peer.
//- (void)                    session:(MCSession *)session
//  didStartReceivingResourceWithName:(NSString *)resourceName
//                           fromPeer:(MCPeerID *)peerID
//                       withProgress:(NSProgress *)progress
//{
//
//}
//
//// Finished receiving a resource from remote peer and saved the content
//// in a temporary location - the app is responsible for moving the file
//// to a permanent location within its sandbox.
//- (void)                    session:(MCSession *)session
// didFinishReceivingResourceWithName:(NSString *)resourceName
//                           fromPeer:(MCPeerID *)peerID
//                              atURL:(NSURL *)localURL
//                          withError:(nullable NSError *)error
//{
//    
//}
//
//
