//
//  ViewController.m
//  KPRadioset
//
//  Created by Павел Квачан on 1/20/17.
//  Copyright © 2017 Павел Квачан. All rights reserved.
//

#import "ViewController.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>

NSString * const KPServiceType = @"KPServiceType";


@interface ViewController () <MCBrowserViewControllerDelegate, MCSessionDelegate>
{
    MCPeerID  *_myPeerID;
    MCSession *_mySession;
    
    MCBrowserViewController *_browserViewController;
    MCAdvertiserAssistant   *_advertiser;
}


@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _myPeerID = [[MCPeerID alloc] initWithDisplayName:[UIDevice currentDevice].name];
    
    _mySession = [[MCSession alloc] initWithPeer:_myPeerID
                                securityIdentity:nil
                            encryptionPreference:MCEncryptionNone];
    
    _mySession.delegate = self;
    
    _browserViewController = [[MCBrowserViewController alloc] initWithServiceType:KPServiceType
                                                                          session:_mySession];
    
    _browserViewController.delegate = self;
    
    
    _advertiser = [[MCAdvertiserAssistant alloc] initWithServiceType:KPServiceType
                                                       discoveryInfo:nil
                                                             session:_mySession];
    
    [_advertiser start];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self showBrowserViewController];
}


- (void)showBrowserViewController
{
    if (_browserViewController != nil)
    {
        [self presentViewController:_browserViewController
                           animated:YES
                         completion:nil];
    }
}



#pragma mark - MCBrowserViewControllerDelegate -

- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController
{
    [browserViewController dismissViewControllerAnimated:YES
                                              completion:^
     {
         NSLog(@"browserViewControllerDidFinish");
     }];
}


- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController
{
    [browserViewController dismissViewControllerAnimated:YES
                                              completion:^
     {
         NSLog(@"browserViewControllerWasCancelled");
     }];
}




#pragma mark - MCSessionDelegate -

// Remote peer changed state.
- (void)session:(MCSession *)session
           peer:(MCPeerID *)peerID
 didChangeState:(MCSessionState)state
{
    switch (state)
    {
        case MCSessionStateConnecting:
            NSLog(@"connecting");
            break;
            
        case MCSessionStateConnected:
            NSLog(@"connected");
            break;
            
        case MCSessionStateNotConnected:
            NSLog(@"NotConnected");
            break;
            
        default:
            break;
    }
}

// Received data from remote peer.
- (void)session:(MCSession *)session
 didReceiveData:(NSData *)data
       fromPeer:(MCPeerID *)peerID
{
    
}

// Received a byte stream from remote peer.
- (void)    session:(MCSession *)session
   didReceiveStream:(NSInputStream *)stream
           withName:(NSString *)streamName
           fromPeer:(MCPeerID *)peerID
{
    
}

// Start receiving a resource from remote peer.
- (void)                    session:(MCSession *)session
  didStartReceivingResourceWithName:(NSString *)resourceName
                           fromPeer:(MCPeerID *)peerID
                       withProgress:(NSProgress *)progress
{

}

// Finished receiving a resource from remote peer and saved the content
// in a temporary location - the app is responsible for moving the file
// to a permanent location within its sandbox.
- (void)                    session:(MCSession *)session
 didFinishReceivingResourceWithName:(NSString *)resourceName
                           fromPeer:(MCPeerID *)peerID
                              atURL:(NSURL *)localURL
                          withError:(nullable NSError *)error
{
    
}


@end
