//
//  KPRecoder.m
//  KPRadioset
//
//  Created by Developer on 2/7/17.
//  Copyright © 2017 Павел Квачан. All rights reserved.
//

#import "KPRecorder.h"
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

#define AUDIO_BUFFERS	5

typedef struct KPAudioQueueCallbackStruct
{
    AudioStreamBasicDescription dataFormat;
    AudioQueueRef queue;
    AudioQueueBufferRef mBuffers[AUDIO_BUFFERS];
    AudioFileID outputFile;
    unsigned int frameSize;
    long long recPtr;
    int run;
    AudioQueueLevelMeterState *chanelLevels;
    KPRecorder *recorder;
} KPAudioQueueCallbackStruct;


static void AQInputCallback(void *aqr,
                            AudioQueueRef inputQueue,
                            AudioQueueBufferRef inputQueueBuffer,
                            const AudioTimeStamp *timestamp,
                            UInt32 frameSize,
                            const AudioStreamPacketDescription *dataFormat)
{
    KPAudioQueueCallbackStruct *audioQueueCallback = (KPAudioQueueCallbackStruct *)aqr;
    
    @autoreleasepool
    {
        
        if ([((NSObject *)audioQueueCallback->recorder.delegate) respondsToSelector:@selector(recorder:levels:)])
        {
            UInt32 dataSize = sizeof(AudioQueueLevelMeterState)*audioQueueCallback->dataFormat.mChannelsPerFrame;
            
            OSErr status = AudioQueueGetProperty(inputQueue, kAudioQueueProperty_CurrentLevelMeterDB, audioQueueCallback->chanelLevels, &dataSize);
            
            if (status == noErr)
            {
                if (audioQueueCallback->chanelLevels)
                {
                    NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:audioQueueCallback->dataFormat.mChannelsPerFrame];
                    
                    for (NSInteger i = 0; i < audioQueueCallback->dataFormat.mChannelsPerFrame; i++)
                    {
                        [arr addObject:[NSNumber numberWithFloat:audioQueueCallback->chanelLevels[i].mAveragePower]];
                    }
                    [audioQueueCallback->recorder.delegate recorder:audioQueueCallback->recorder levels:arr];
                    [arr release];
                }
            }
        }
        
        OSStatus result = AudioFileWritePackets(audioQueueCallback->outputFile, false, inputQueueBuffer->mAudioDataByteSize, dataFormat, audioQueueCallback->recPtr, &frameSize, inputQueueBuffer->mAudioData);
        
        if (result == noErr)
        {
            audioQueueCallback->recPtr += frameSize;
        }
        
        if (!audioQueueCallback->run)
        {
            return;
        }
        
        AudioQueueEnqueueBuffer(audioQueueCallback->queue, inputQueueBuffer, 0, NULL);
    }
}



@interface KPRecorder()
{
    KPAudioQueueCallbackStruct _audioQueueCallback;

    BOOL _recording;
}


@end




@implementation KPRecorder

@synthesize delegate = _delegate;

- (void)dealloc
{
    if (_audioQueueCallback.chanelLevels)
    {
        free(_audioQueueCallback.chanelLevels);
    }
    
    [super dealloc];
}

- (BOOL)start
{
    AudioFileTypeID fileFormat;
    
    _audioQueueCallback.dataFormat.mFormatID = kAudioFormatLinearPCM;
    _audioQueueCallback.dataFormat.mSampleRate = 44100;
    _audioQueueCallback.dataFormat.mChannelsPerFrame = 1;
    _audioQueueCallback.dataFormat.mBitsPerChannel = 16;
    _audioQueueCallback.dataFormat.mBytesPerPacket =
    _audioQueueCallback.dataFormat.mBytesPerFrame = _audioQueueCallback.dataFormat.mChannelsPerFrame * sizeof(short int);
    _audioQueueCallback.dataFormat.mFramesPerPacket = 1;
    _audioQueueCallback.dataFormat.mFormatFlags = kLinearPCMFormatFlagIsBigEndian
                                                | kLinearPCMFormatFlagIsSignedInteger
                                                | kLinearPCMFormatFlagIsPacked;
    if (_audioQueueCallback.chanelLevels)
    {
        free(_audioQueueCallback.chanelLevels);
    }
    _audioQueueCallback.chanelLevels = malloc(sizeof(AudioQueueLevelMeterState)*_audioQueueCallback.dataFormat.mChannelsPerFrame);
    _audioQueueCallback.frameSize = 0;
    _audioQueueCallback.recorder = self;
    
    AudioQueueNewInput(&_audioQueueCallback.dataFormat, AQInputCallback, &_audioQueueCallback, NULL, kCFRunLoopCommonModes, 0, &_audioQueueCallback.queue);
    
    int frames;
    CGFloat buffDuration = 0.1;
    frames = (int)ceil(buffDuration * _audioQueueCallback.dataFormat.mSampleRate);
    _audioQueueCallback.frameSize = frames * _audioQueueCallback.dataFormat.mBytesPerFrame;
    
    fileFormat = kAudioFileAIFFType;
    CFURLRef fn = CFURLCreateFromFileSystemRepresentation(NULL,
                                                          (const UInt8 *)[self.fileName cStringUsingEncoding:NSUTF8StringEncoding],
                                                          [self.fileName length],
                                                          false);
    
    AudioFileCreateWithURL(fn, fileFormat, &_audioQueueCallback.dataFormat, kAudioFileFlags_EraseFile, &_audioQueueCallback.outputFile);
    
    for (int i = 0; i < AUDIO_BUFFERS; i++)
    {
        AudioQueueAllocateBuffer(_audioQueueCallback.queue, _audioQueueCallback.frameSize, &_audioQueueCallback.mBuffers[i]);
        AudioQueueEnqueueBuffer(_audioQueueCallback.queue, _audioQueueCallback.mBuffers[i], 0, NULL);
    }
    
    _audioQueueCallback.recPtr = 0;
    _audioQueueCallback.run = 1;
    
    AudioQueueStart(_audioQueueCallback.queue, NULL);
    
    _recording = YES;
    
    return YES;

}

- (void)stop
{
    AudioQueueStop(_audioQueueCallback.queue, true);
    _audioQueueCallback.run = 0;
    
    AudioQueueDispose(_audioQueueCallback.queue, true);
    AudioFileClose(_audioQueueCallback.outputFile);
    _recording = NO;
}


- (NSString *)fileName
{
    NSString *pathDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *rv = [pathDir stringByAppendingPathComponent:
                    [NSString stringWithFormat:@"1.aiff"]
                    ];
    NSLog(@"%@", rv);
    return rv;
}


@end
