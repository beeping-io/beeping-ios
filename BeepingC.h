//
//  BeepingC.h
//  Beeping
//
//  Internal ObjC++ bridge between Swift 6 (BeepingClient + AudioEngine)
//  and the C API of beeping-core (`BeepingCoreLib_api.h`).
//
//  This header is INTERNAL to the Beeping framework — exposed to Swift
//  sources via the framework module map but NOT part of the public API.
//
//  Lifecycle: each `BCNativeCore` owns one C engine handle (`BEEPING_Create`
//  on init, `BEEPING_Destroy` on dealloc). `BCAudioUnitController` borrows a
//  `BCNativeCore` to drive decode/encode from the iOS RemoteIO audio unit.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - BCNativeCore

/// Wraps the opaque C engine handle from `BeepingCoreLib_api.h`. Methods on
/// this class are 1:1 with the C API. Higher-level orchestration (modes,
/// state machine, threading) lives in the Swift `BeepingCoreWrapper`.
@interface BCNativeCore : NSObject

/// Engine version (wraps `BEEPING_GetVersion`).
@property (class, readonly, copy) NSString *version;

- (instancetype)init NS_DESIGNATED_INITIALIZER;

/// Wraps `BEEPING_Configure`. Returns 0 on success, <0 on failure.
- (int32_t)configureWithMode:(int32_t)mode
                  sampleRate:(float)sampleRate
                  bufferSize:(int32_t)bufferSize;

/// Wraps `BEEPING_SetCustomBaseFreq`. Used only with custom mode.
- (int32_t)setCustomBaseFreq:(float)baseFreq beepsSeparation:(int32_t)separation;

/// Wraps `BEEPING_GetDecodingBeginFreq` / `BEEPING_GetDecodingEndFreq`.
@property (readonly) float decodingBeginFreq;
@property (readonly) float decodingEndFreq;

/// Wraps `BEEPING_EncodeDataToAudioBuffer`.
/// - Parameters:
///   - string: the 9-char code to encode (digits 0-9 and a-v).
///   - type: 0 tones, 1 tones+R2D2, 2 melody.
/// - Returns: number of samples in the encoded buffer.
- (int32_t)encodeString:(NSString *)string type:(int32_t)type;

/// Wraps `BEEPING_GetEncodedAudioBuffer`. Caller-supplied buffer must be at
/// least `bufferSize` floats wide. Returns number of samples written.
- (int32_t)readEncodedAudioBuffer:(float *)buffer NS_REFINED_FOR_SWIFT;

/// Wraps `BEEPING_DecodeAudioBuffer`. Caller-supplied buffer is mono float32
/// audio frames at the configured sample rate. Returns the raw decoder code:
///   - `-1` no data
///   - `-2` start token
///   - `-3` complete word decoded (call `getDecodedDataInto:` to fetch)
///   - `>= 0` partial token index
- (int32_t)decodeAudioBuffer:(float *)buffer size:(int32_t)size NS_REFINED_FOR_SWIFT;

/// Wraps `BEEPING_GetDecodedData`. Writes up to 64 bytes into `out`.
/// Returns sign-magnitude:
///   - `0` no data
///   - `> 0` decoded data is OK; magnitude is byte count
///   - `< 0` decoded data is wrong; magnitude is byte count
- (int32_t)getDecodedDataInto:(char *)out NS_REFINED_FOR_SWIFT;

/// Wraps `BEEPING_GetDecodedMode`.
@property (readonly) int32_t decodedMode;

/// Wraps confidence + volume metric getters from the C API.
@property (readonly) float confidence;
@property (readonly) float confidenceError;
@property (readonly) float confidenceNoise;
@property (readonly) float receivedBeepsVolume;

@end


#pragma mark - BCAudioUnitController

/// Manages the iOS RemoteIO Audio Unit. The audio callbacks dispatch into
/// the supplied `BCNativeCore` for decode/encode and forward token events
/// through the `onToken` block.
///
/// **Threading:** the `onToken` block runs on the real-time audio thread.
/// It MUST NOT allocate, take contended locks, or hop into Swift actors
/// synchronously. The Swift `AudioEngine` is responsible for hopping the
/// event onto a safe queue / actor before dispatching to consumers.
///
/// **Self capture:** the C audio callbacks resolve `self` via `inRefCon`,
/// not a global pointer (legacy `IosAudioController` used a global, which
/// is replaced here).
@interface BCAudioUnitController : NSObject

/// Strong reference to the native core that decodes/encodes audio frames.
@property (strong, readonly) BCNativeCore *core;

/// Called from the audio thread on every decoder token transition.
/// - `token` is the raw decoder return code:
///   - `-2` start
///   - `-3` end (decoded data available; query `core` if `decodedString` is nil)
/// - `decodedString` is non-nil only on `-3` AND when the decoded data is OK.
@property (copy, atomic, nullable) void (^onToken)(int32_t token,
                                                   NSString *_Nullable decodedString);

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCore:(BCNativeCore *)core NS_DESIGNATED_INITIALIZER;

/// Starts the RemoteIO audio unit. Mic permission must already be granted
/// by the caller (this class does not request it). Returns 0 on success.
- (int32_t)start;

/// Stops the audio unit. Returns 0 on success.
- (int32_t)stop;

/// Marks whether the next playback callback should consume the encoded
/// buffer from the native core. Set to YES after `encodeString:type:` and
/// `start` to begin emission; reset to NO once the buffer is drained.
@property (atomic) BOOL emitting;

@end

NS_ASSUME_NONNULL_END
