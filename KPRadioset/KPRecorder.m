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
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    NSString *rv = [pathDir stringByAppendingPathComponent:
                    [NSString stringWithFormat:@"%@.aiff", [dateFormatter stringFromDate:[NSDate date]]]
                    ];
    
    return rv;
}


@end



//#define kNumberRecordBuffers 3
//
//#pragma mark user data struct
//typedef struct MyRecorder{
//    AudioFileID recordFile;
//    SInt64 recordPacket;
//    Boolean running;
//}MyRecorder;
//
//
//#pragma mark utility functions
//static void CheckError(OSStatus err, const char* operation){
//    if (err == noErr)return;
//    
//    char errorString[20];
//    *(UInt32 *)(errorString+1) = CFSwapInt32HostToBig(err);
//    if(isprint(errorString[1]) && isprint(errorString[2])
//       && isprint(errorString[3]) && isprint(errorString[4])){
//        errorString[0] = errorString[5] = '\'';
//        errorString[6] = '\0';
//    }
//    else{
//        sprintf(errorString, "%d", (int)err);
//    }
//    fprintf(stderr, "Error: %s (%s)\n",operation, errorString);
//    exit(1);
//}
//
//OSStatus MyGetDefaultInputDeviceSampleRate(Float64 *outSampleRate)
//{
//    OSStatus error;
//    AudioDeviceID deviceID = 0;
//    
//    AudioObjectPropertyAddress propertyAddress;
//    UInt32 propertySize;
//    propertyAddress.mSelector = kAudioHardwarePropertyDefaultInputDevice;
//    propertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
//    propertyAddress.mElement = 0;
//    propertySize = sizeof(AudioDeviceID);
//    error = AudioHardwareServiceGetPropertyData(kAudioObjectSystemObject,
//                                                &propertyAddress,
//                                                0,
//                                                NULL,
//                                                &propertySize,
//                                                &deviceID);
//    if (error) {
//        return error;
//    }
//    
//    propertyAddress.mSelector = kAudioDevicePropertyNominalSampleRate;
//    propertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
//    propertyAddress.mElement = 0;
//    propertySize = sizeof(Float64);
//    error = AudioHardwareServiceGetPropertyData(deviceID,
//                                                &propertyAddress,
//                                                0,
//                                                NULL,
//                                                &propertySize,
//                                                outSampleRate);
//    return error;
//}
//
//static void MyCopyEncoderCookieToFile(AudioQueueRef queue, AudioFileID theFile){
//    OSStatus error;
//    UInt32 propertySize;
//    
//    error = AudioQueueGetPropertySize(queue, kAudioConverterCompressionMagicCookie, &propertySize);
//    
//    if(error == noErr && propertySize > 0){
//        Byte *magicCookie = (Byte*)malloc(propertySize);
//        CheckError(AudioQueueGetProperty(queue,
//                                         kAudioQueueProperty_MagicCookie,
//                                         magicCookie,
//                                         &propertySize),
//                   "Couldn't get audio queue's magic cookie");
//        
//        CheckError(AudioFileSetProperty(theFile,
//                                        kAudioFilePropertyMagicCookieData,
//                                        propertySize,
//                                        magicCookie),
//                   "Couldn't set file's magic cookie");
//        free(magicCookie);
//    }
//}
//
//static int MyComputeRecordBufferSize(const AudioStreamBasicDescription *format,
//                                     AudioQueueRef queue,
//                                     float seconds)
//{
//    int packets, frames, bytes;
//    frames = (int)ceil(seconds * format->mSampleRate);
//    
//    if (format->mBytesPerFrame > 0) {
//        bytes = frames * format->mBytesPerFrame;
//    }
//    else
//    {
//        UInt32 maxPacketSize;
//        if (format->mBytesPerPacket)
//        {
//            maxPacketSize = format->mBytesPerPacket;
//        }
//        else
//        {
//            UInt32 propertySize = sizeof(maxPacketSize);
//            CheckError(AudioQueueGetProperty(queue,
//                                             kAudioConverterPropertyMaximumOutputPacketSize,
//                                             &maxPacketSize,
//                                             &propertySize),
//                       "Couldn't get queue's maximum output size");
//        }
//        if (format->mFramesPerPacket > 0) {
//            packets = frames / format->mFramesPerPacket;
//        }
//        else{
//            packets = frames;
//        }
//        if (packets == 0) {
//            packets = 1;
//        }
//        bytes = packets * maxPacketSize;
//    }
//    return bytes;
//}
//
//
//
//
//#pragma mark record callback function
//static void MyAQInputCallback(void *inUserData,
//                              AudioQueueRef inQueue,
//                              AudioQueueBufferRef inBuffer,
//                              const AudioTimeStamp *inStartTime,
//                              UInt32 inNumPackets,
//                              const AudioStreamPacketDescription *inPacketDesc)
//{
//    MyRecorder *recorder = (MyRecorder*)inUserData;
//    if (inNumPackets > 0) {
//        CheckError(AudioFileWritePackets(recorder->recordFile,
//                                         FALSE,
//                                         inBuffer->mAudioDataByteSize,
//                                         inPacketDesc,
//                                         recorder->recordPacket,
//                                         &inNumPackets,
//                                         inBuffer->mAudioData),
//                   "Writing Audio File Packets failed");
//    }
//    recorder->recordPacket += inNumPackets;
//    
//    if (recorder->running) {
//        CheckError(AudioQueueEnqueueBuffer(inQueue,
//                                           inBuffer,
//                                           0,
//                                           NULL),
//                   "AudioQueueEnqueueBuffer failed");
//    }
//}
//
//
//
//#pragma mark main function
//int main(int argc, const char * argv[])
//{
//    MyRecorder recorder = {0};
//    AudioStreamBasicDescription recordFormat = {0};
//    memset(&recordFormat, 0, sizeof(recordFormat));
//    
//    MyGetDefaultInputDeviceSampleRate(&recordFormat.mSampleRate);
//    // Configure the output data format to be AAC
//    recordFormat.mFormatID = kAudioFormatMPEG4AAC;
//    recordFormat.mChannelsPerFrame = 2;
//    
//    
//    UInt32 propSize = sizeof(recordFormat);
//    CheckError(AudioFormatGetProperty(kAudioFormatProperty_FormatInfo,
//                                      0,
//                                      NULL,
//                                      &propSize,
//                                      &recordFormat),
//               "AudioFormatGetProperty failed");
//    
//    AudioQueueRef queue = {0};
//    CheckError(AudioQueueNewInput(&recordFormat,
//                                  MyAQInputCallback,
//                                  &recorder,
//                                  NULL,
//                                  NULL,
//                                  0,
//                                  &queue),
//               "AudioQueueNewInput failed");
//    
//    UInt32 size = sizeof(recordFormat);
//    CheckError(AudioQueueGetProperty(queue,
//                                     kAudioConverterCurrentOutputStreamDescription,
//                                     &recordFormat,
//                                     &size),
//               "AudioQueueGetProperty failed");
//    
//    CFURLRef myFileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
//                                                       CFSTR("output.caf"),
//                                                       kCFURLPOSIXPathStyle,
//                                                       false);
//    CheckError(AudioFileCreateWithURL(myFileURL, kAudioFileCAFType, &recordFormat, kAudioFileFlags_EraseFile, &recorder.recordFile), "AudioFileCreateWithURL failed");
//    CFRelease(myFileURL);
//    
//    MyCopyEncoderCookieToFile(queue, recorder.recordFile);
//    
//    int bufferByteSize = MyComputeRecordBufferSize(&recordFormat,queue,0.5);
//    
//    int bufferIndex;
//    for (bufferIndex = 0; bufferIndex < kNumberRecordBuffers; ++bufferIndex) {
//        AudioQueueBufferRef buffer;
//        CheckError(AudioQueueAllocateBuffer(queue,
//                                            bufferByteSize,
//                                            &buffer),
//                   "AudioQueueAllocateBuffer failed");
//        CheckError(AudioQueueEnqueueBuffer(queue,
//                                           buffer,
//                                           0,
//                                           NULL),
//                   "AudioQueueEnqueueBuffer failed");
//    }
//    
//    recorder.running = TRUE;
//    CheckError(AudioQueueStart(queue, NULL),"AudioQueueStart failed");
//    
//    printf("Recording... press <enter> to end:\n");
//    getchar();
//    
//    printf("Recording done...\n");
//    recorder.running = FALSE;
//    CheckError(AudioQueueStop(queue, TRUE), "AudioQueueStop failed");
//    MyCopyEncoderCookieToFile(queue,recorder.recordFile);
//    AudioQueueDispose(queue, TRUE);
//    AudioFileClose(recorder.recordFile);
//    
//    return 0;
//}
