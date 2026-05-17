import AVFoundation
import Foundation

/// Wraps the float32 PCM produced by `BeepingClient.encodeWithSchedule(...)`
/// in a minimal Int16 WAV header and hands it to `AVAudioPlayer` for the
/// sample-app scheduler demo (BEE-2241).
///
/// Not part of the public SDK — production consumers should use
/// `AVAudioEngine` + `AVAudioPlayerNode` with the float buffer directly.
@MainActor
final class SchedulerDemoPlayer {
    private var player: AVAudioPlayer?

    /// Play `pcm` at `sampleRate` Hz mono. The sample app expects
    /// 44_100 Hz from `BeepingClient.encodeWithSchedule(...)`.
    /// Returns after playback finishes (does NOT await async).
    func play(pcmFloat32: Data, sampleRate: Int = 44_100) throws {
        let wav = Self.wrapAsInt16Wav(pcmFloat32: pcmFloat32, sampleRate: sampleRate)
        let p = try AVAudioPlayer(data: wav)
        p.prepareToPlay()
        p.play()
        player = p
    }

    /// Float32 PCM → Int16 WAV. Quick and tiny — enough for the demo.
    /// AVAudioPlayer accepts 16-bit PCM reliably across iOS versions, so
    /// converting here avoids the IEEE-float WAV-codec edge cases.
    static func wrapAsInt16Wav(pcmFloat32: Data, sampleRate: Int) -> Data {
        let floatCount = pcmFloat32.count / MemoryLayout<Float>.size
        var int16Bytes = Data(capacity: floatCount * MemoryLayout<Int16>.size)
        pcmFloat32.withUnsafeBytes { raw in
            let floats = raw.bindMemory(to: Float.self)
            for f in floats {
                let clamped = max(-1.0, min(1.0, f))
                var sample = Int16(clamped * Float(Int16.max))
                withUnsafeBytes(of: &sample) { int16Bytes.append(contentsOf: $0) }
            }
        }

        let bitsPerSample: UInt16 = 16
        let channels: UInt16 = 1
        let byteRate = UInt32(sampleRate) * UInt32(channels) * UInt32(bitsPerSample / 8)
        let blockAlign: UInt16 = channels * (bitsPerSample / 8)
        let dataSize = UInt32(int16Bytes.count)
        let chunkSize = 36 + dataSize

        var wav = Data()
        wav.append("RIFF".data(using: .ascii)!)
        wav.append(le4(chunkSize))
        wav.append("WAVE".data(using: .ascii)!)
        wav.append("fmt ".data(using: .ascii)!)
        wav.append(le4(16))
        wav.append(le2(1))  // PCM
        wav.append(le2(channels))
        wav.append(le4(UInt32(sampleRate)))
        wav.append(le4(byteRate))
        wav.append(le2(blockAlign))
        wav.append(le2(bitsPerSample))
        wav.append("data".data(using: .ascii)!)
        wav.append(le4(dataSize))
        wav.append(int16Bytes)
        return wav
    }

    private static func le4(_ value: UInt32) -> Data {
        var v = value.littleEndian
        return Data(bytes: &v, count: 4)
    }

    private static func le2(_ value: UInt16) -> Data {
        var v = value.littleEndian
        return Data(bytes: &v, count: 2)
    }
}
