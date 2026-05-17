//
//  BeepingC.mm
//  Beeping
//
//  ObjC++ implementation of the BCNativeCore + BCAudioUnitController bridge.
//  See `BeepingC.h` for the interface contract.
//
//  This file is the ONLY .mm file allowed in beeping-ios per the BEE-68
//  scope: it owns the C++ ↔ Swift transition. All higher-level orchestration
//  (state machine, dual-mode strategy, public API) lives in pure Swift.
//

#import "BeepingC.h"
#import "BeepingCoreLib_api.h"

#include <atomic>
#include <vector>

#pragma mark - C bridging helpers

namespace {

/// `BEEPING_DecodeAudioBuffer` returns -2 (start), -3 (end), -1 (no data),
/// or >=0 (partial token). The callers in this file only forward the first
/// three through the `onToken` block.
constexpr int32_t kBeepStartToken    = -2;
constexpr int32_t kBeepEndToken      = -3;

/// Audio unit sample rate. Bus identifiers come from RemoteIO conventions
/// (Apple AudioUnit programming guide).
/// `kDefaultBufferSize` from legacy `BeepingCore.m` is intentionally NOT
/// duplicated here — buffer size is owned by the Swift caller via
/// `BCNativeCore.configureWithMode:sampleRate:bufferSize:`.
constexpr float   kDefaultSampleRate = 44100.0f;
constexpr UInt32  kInputBus          = 1;
constexpr UInt32  kOutputBus         = 0;

void bcCheckStatus(OSStatus status, const char *step) {
    if (status != noErr) {
        NSLog(@"[BeepingC] AudioUnit step '%s' failed with OSStatus=%d",
              step, (int)status);
    }
}

} // namespace


#pragma mark - BCNativeCore

@interface BCNativeCore () {
    void *_cHandle;
}
@end

@implementation BCNativeCore

+ (NSString *)version {
    const char *raw = BEEPING_GetVersion();
    if (raw == nullptr) {
        return @"";
    }
    return [NSString stringWithUTF8String:raw] ?: @"";
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _cHandle = BEEPING_Create();
        NSAssert(_cHandle != NULL, @"[BCNativeCore] BEEPING_Create returned NULL");
    }
    return self;
}

- (void)dealloc {
    if (_cHandle != NULL) {
        BEEPING_Destroy(_cHandle);
        _cHandle = NULL;
    }
}

- (int32_t)configureWithMode:(int32_t)mode
                  sampleRate:(float)sampleRate
                  bufferSize:(int32_t)bufferSize {
    return BEEPING_Configure(static_cast<int>(mode), sampleRate, bufferSize, _cHandle);
}

- (float)decodingBeginFreq { return BEEPING_GetDecodingBeginFreq(_cHandle); }
- (float)decodingEndFreq   { return BEEPING_GetDecodingEndFreq(_cHandle); }

- (int32_t)encodeString:(NSString *)string type:(int32_t)type {
    const char *raw = [string UTF8String] ?: "";
    int32_t length = static_cast<int32_t>(strlen(raw));
    return BEEPING_EncodeDataToAudioBuffer(raw, length, type, nullptr, 0, _cHandle);
}

- (int32_t)readEncodedAudioBuffer:(float *)buffer {
    return BEEPING_GetEncodedAudioBuffer(buffer, _cHandle);
}

- (int32_t)decodeAudioBuffer:(float *)buffer size:(int32_t)size {
    return BEEPING_DecodeAudioBuffer(buffer, static_cast<int>(size), _cHandle);
}

- (int32_t)getDecodedDataInto:(char *)out {
    return BEEPING_GetDecodedData(out, _cHandle);
}

- (int32_t)decodedMode         { return BEEPING_GetDecodedMode(_cHandle); }
- (float)  confidence          { return BEEPING_GetConfidence(_cHandle); }
- (float)  confidenceError     { return BEEPING_GetConfidenceError(_cHandle); }
- (float)  confidenceNoise     { return BEEPING_GetConfidenceNoise(_cHandle); }
- (float)  receivedBeepsVolume { return BEEPING_GetReceivedBeepsVolume(_cHandle); }

+ (NSArray<NSNumber *> *)computeBeepScheduleWithDuration:(float)duration
                                                startTime:(float)startTime
                                                 interval:(float)interval
                                                    error:(int32_t *)errorOut {
    // Size-query mode: pass maxTimestamps=0 to learn the count first.
    int32_t count = 0;
    int32_t rc = BEEPING_ComputeBeepSchedule(duration, startTime, interval,
                                             nullptr, 0, &count);
    if (rc != 0) {
        if (errorOut != nullptr) { *errorOut = rc; }
        return nil;
    }
    if (count <= 0) {
        return @[];
    }
    // Allocate the timestamps buffer and call again.
    std::vector<double> timestamps(static_cast<size_t>(count));
    int32_t writtenCount = 0;
    rc = BEEPING_ComputeBeepSchedule(duration, startTime, interval,
                                     timestamps.data(), count, &writtenCount);
    if (rc != 0) {
        if (errorOut != nullptr) { *errorOut = rc; }
        return nil;
    }
    NSMutableArray<NSNumber *> *result =
        [NSMutableArray arrayWithCapacity:static_cast<NSUInteger>(writtenCount)];
    for (int32_t i = 0; i < writtenCount; i++) {
        [result addObject:@(timestamps[static_cast<size_t>(i)])];
    }
    return result;
}

- (NSData *)encodeWithScheduleCode:(NSString *)code
                          duration:(float)duration
                         startTime:(float)startTime
                          interval:(float)interval
                        beepGainDb:(float)beepGainDb
                             error:(int32_t *)errorOut {
    const char *codeBytes = [code UTF8String];
    if (codeBytes == nullptr) {
        if (errorOut != nullptr) { *errorOut = -2; }
        return nil;
    }
    int32_t codeSize = static_cast<int32_t>(strlen(codeBytes));

    // Ask the engine how many samples the output buffer needs.
    int32_t maxSamples = BEEPING_GetScheduleBufferSize(duration, _cHandle);
    if (maxSamples <= 0) {
        if (errorOut != nullptr) { *errorOut = maxSamples; }
        return nil;
    }

    // Allocate as NSMutableData so we can hand back ownership without copying.
    NSMutableData *outData =
        [NSMutableData dataWithLength:static_cast<NSUInteger>(maxSamples) * sizeof(float)];
    if (outData == nil) {
        if (errorOut != nullptr) { *errorOut = -2; }
        return nil;
    }
    int32_t written = 0;
    int32_t rc = BEEPING_EncodeWithSchedule(codeBytes, codeSize,
                                            /*type=*/0,
                                            /*melody=*/nullptr,
                                            /*melodySize=*/0,
                                            duration, startTime, interval,
                                            beepGainDb,
                                            static_cast<float *>([outData mutableBytes]),
                                            maxSamples,
                                            &written,
                                            _cHandle);
    if (rc != 0) {
        if (errorOut != nullptr) { *errorOut = rc; }
        return nil;
    }
    // Trim defensively: the C API guarantees `written ==
    // floor(duration * sampleRate)`, which should equal `maxSamples`, but
    // we honor the explicit count returned to stay correct if the engine
    // ever returns a shorter buffer.
    if (written > 0 && written < maxSamples) {
        [outData setLength:static_cast<NSUInteger>(written) * sizeof(float)];
    }
    return outData;
}

@end


#pragma mark - BCAudioUnitController

@interface BCAudioUnitController () {
    AudioComponentInstance _audioUnit;
    std::atomic<bool>      _running;
}
/// Accessor used only from the file-local C audio callbacks. The ivar
/// itself stays private; this is the file-internal door.
- (AudioComponentInstance)audioUnitForCallback;
@end

namespace {

/// Recording (microphone) callback. Pulls a chunk of mono int16 frames from
/// the input bus, converts to float, hands it to the decoder, and forwards
/// any token transition through `controller.onToken`.
OSStatus bcRecordingCallback(void *inRefCon,
                             AudioUnitRenderActionFlags *ioActionFlags,
                             const AudioTimeStamp *inTimeStamp,
                             UInt32 inBusNumber,
                             UInt32 inNumberFrames,
                             AudioBufferList *ioData) {
    BCAudioUnitController *controller =
        (__bridge BCAudioUnitController *)inRefCon;
    if (controller == nil) {
        return noErr;
    }

    AudioBuffer captureBuffer;
    captureBuffer.mNumberChannels = 1;
    captureBuffer.mDataByteSize   = inNumberFrames * sizeof(SInt16);
    captureBuffer.mData           = malloc(captureBuffer.mDataByteSize);
    if (captureBuffer.mData == nullptr) {
        return noErr;
    }

    AudioBufferList captureList;
    captureList.mNumberBuffers = 1;
    captureList.mBuffers[0]    = captureBuffer;

    AudioComponentInstance audioUnit = [controller audioUnitForCallback];
    OSStatus renderStatus =
        AudioUnitRender(audioUnit, ioActionFlags, inTimeStamp,
                        inBusNumber, inNumberFrames, &captureList);
    bcCheckStatus(renderStatus, "AudioUnitRender");

    SInt16 *frames = static_cast<SInt16 *>(captureList.mBuffers[0].mData);
    float *floatBuf = static_cast<float *>(malloc(inNumberFrames * sizeof(float)));
    if (floatBuf == nullptr) {
        free(captureList.mBuffers[0].mData);
        return noErr;
    }
    for (UInt32 j = 0; j < inNumberFrames; ++j) {
        floatBuf[j] = frames[j] / 32768.0f;
    }

    int32_t code = [controller.core decodeAudioBuffer:floatBuf
                                                 size:static_cast<int32_t>(inNumberFrames)];

    if (code == kBeepStartToken) {
        if (controller.onToken) {
            controller.onToken(code, nil);
        }
    } else if (code == kBeepEndToken) {
        char decodedRaw[64] = {0};
        int32_t status = [controller.core getDecodedDataInto:decodedRaw];
        NSString *decoded = nil;
        if (status > 0) {
            decoded = [NSString stringWithUTF8String:decodedRaw];
        }
        if (controller.onToken) {
            controller.onToken(code, decoded);
        }
    }
    // Other codes (>= 0 partial, -1 no data) are not forwarded — matches
    // legacy behavior in `IosAudioController.m`.

    free(floatBuf);
    free(captureList.mBuffers[0].mData);
    return noErr;
}

/// Playback (speaker) callback. When `controller.emitting` is YES, fills
/// the output bus with samples drained from the encoded buffer in
/// `controller.core`. When NO, fills with silence.
OSStatus bcPlaybackCallback(void *inRefCon,
                            AudioUnitRenderActionFlags *ioActionFlags,
                            const AudioTimeStamp *inTimeStamp,
                            UInt32 inBusNumber,
                            UInt32 inNumberFrames,
                            AudioBufferList *ioData) {
    (void)ioActionFlags; (void)inTimeStamp; (void)inBusNumber;
    BCAudioUnitController *controller =
        (__bridge BCAudioUnitController *)inRefCon;
    if (controller == nil || ioData == nullptr) {
        return noErr;
    }

    for (UInt32 i = 0; i < ioData->mNumberBuffers; ++i) {
        AudioBuffer buffer = ioData->mBuffers[i];
        SInt16 *frames     = static_cast<SInt16 *>(buffer.mData);

        if (controller.emitting) {
            float floatBuf[2048] = {0};
            int32_t got = [controller.core readEncodedAudioBuffer:floatBuf];
            if (got <= 0) {
                controller.emitting = NO;
                for (UInt32 j = 0; j < inNumberFrames; ++j) frames[j] = 0;
            } else {
                int32_t copy = MIN(got, static_cast<int32_t>(inNumberFrames));
                for (int32_t j = 0; j < copy; ++j) {
                    frames[j] = static_cast<SInt16>(floatBuf[j] * 32767.0f);
                }
                for (UInt32 j = copy; j < inNumberFrames; ++j) frames[j] = 0;
            }
        } else {
            for (UInt32 j = 0; j < inNumberFrames; ++j) frames[j] = 0;
        }
    }

    return noErr;
}

} // namespace


@implementation BCAudioUnitController

@synthesize core = _core;
@synthesize onToken = _onToken;

- (AudioComponentInstance)audioUnitForCallback { return _audioUnit; }

- (instancetype)initWithCore:(BCNativeCore *)core {
    NSParameterAssert(core != nil);
    self = [super init];
    if (self) {
        _core = core;
        _running.store(false);
        _emitting = NO;
        if (![self setupAudioUnit]) {
            return nil;
        }
    }
    return self;
}

- (void)dealloc {
    if (_running.load()) {
        AudioOutputUnitStop(_audioUnit);
    }
    if (_audioUnit) {
        AudioUnitUninitialize(_audioUnit);
        AudioComponentInstanceDispose(_audioUnit);
        _audioUnit = nullptr;
    }
}

- (BOOL)setupAudioUnit {
    AudioComponentDescription desc = {
        .componentType         = kAudioUnitType_Output,
        .componentSubType      = kAudioUnitSubType_RemoteIO,
        .componentManufacturer = kAudioUnitManufacturer_Apple,
        .componentFlags        = 0,
        .componentFlagsMask    = 0,
    };

    AudioComponent component = AudioComponentFindNext(nullptr, &desc);
    if (component == nullptr) { return NO; }

    OSStatus status = AudioComponentInstanceNew(component, &_audioUnit);
    bcCheckStatus(status, "AudioComponentInstanceNew");
    if (status != noErr) { return NO; }

    UInt32 enable = 1;
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input, kInputBus,
                                  &enable, sizeof(enable));
    bcCheckStatus(status, "EnableIO input");

    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Output, kOutputBus,
                                  &enable, sizeof(enable));
    bcCheckStatus(status, "EnableIO output");

    AudioStreamBasicDescription fmt = {};
    fmt.mSampleRate       = kDefaultSampleRate;
    fmt.mFormatID         = kAudioFormatLinearPCM;
    fmt.mFormatFlags      = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    fmt.mFramesPerPacket  = 1;
    fmt.mChannelsPerFrame = 1;
    fmt.mBitsPerChannel   = 16;
    fmt.mBytesPerPacket   = 2;
    fmt.mBytesPerFrame    = 2;

    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output, kInputBus,
                                  &fmt, sizeof(fmt));
    bcCheckStatus(status, "StreamFormat input");
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input, kOutputBus,
                                  &fmt, sizeof(fmt));
    bcCheckStatus(status, "StreamFormat output");

    AURenderCallbackStruct rec;
    rec.inputProc       = bcRecordingCallback;
    rec.inputProcRefCon = (__bridge void *)self;
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Global, kInputBus,
                                  &rec, sizeof(rec));
    bcCheckStatus(status, "SetInputCallback");

    AURenderCallbackStruct play;
    play.inputProc       = bcPlaybackCallback;
    play.inputProcRefCon = (__bridge void *)self;
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Global, kOutputBus,
                                  &play, sizeof(play));
    bcCheckStatus(status, "SetRenderCallback");

    status = AudioUnitInitialize(_audioUnit);
    bcCheckStatus(status, "AudioUnitInitialize");
    return status == noErr;
}

- (int32_t)start {
    if (_running.load()) { return 0; }
    OSStatus status = AudioOutputUnitStart(_audioUnit);
    bcCheckStatus(status, "AudioOutputUnitStart");
    if (status == noErr) { _running.store(true); }
    return static_cast<int32_t>(status);
}

- (int32_t)stop {
    if (!_running.load()) { return 0; }
    OSStatus status = AudioOutputUnitStop(_audioUnit);
    bcCheckStatus(status, "AudioOutputUnitStop");
    if (status == noErr) { _running.store(false); }
    return static_cast<int32_t>(status);
}

@end
