//
//  WAVParser.swift
//  Beeping
//
//  Minimal RIFF/WAVE parser. Used by BEE-2050's cloud-mode loopback path:
//  the server returns a 16-bit PCM mono `audio/wav` blob, and we need its
//  raw Float32 samples to feed `BCNativeCore.decodeAudioBuffer:size:` so
//  the listener can decode the cloud-emitted beep without depending on a
//  speaker→mic acoustic round-trip (which doesn't loop on iOS Simulator).
//
//  Scope is intentionally tight: only the shape `beepbox-server` produces
//  per its OpenAPI spec — `audio/wav`, PCM 16-bit, mono, 44.1 kHz. Other
//  formats (multi-channel, float, IMA-ADPCM, etc.) are rejected with
//  `nil` rather than silently mis-decoded.
//

import Foundation

internal enum WAVParser {

    /// Returns the WAV's PCM samples as Float32 in [-1.0, 1.0], or `nil`
    /// if the bytes don't match the expected shape.
    internal static func float32Samples(from data: Data) -> [Float]? {
        guard data.count >= 44 else { return nil }
        guard data[0..<4] == Data("RIFF".utf8) else { return nil }
        guard data[8..<12] == Data("WAVE".utf8) else { return nil }

        // Walk the chunks looking for `fmt ` and `data`. Beepbox emits
        // them at fixed offsets but other producers may pad — be tolerant.
        var fmt: FormatChunk?
        var pcmBytes: Data?

        var cursor = 12
        while cursor + 8 <= data.count {
            let id = data[cursor..<(cursor + 4)]
            let size = Int(readUInt32LE(data, at: cursor + 4))
            let payloadStart = cursor + 8
            let payloadEnd = payloadStart + size
            guard payloadEnd <= data.count else { return nil }

            if id == Data("fmt ".utf8) {
                fmt = parseFormat(data[payloadStart..<payloadEnd])
            } else if id == Data("data".utf8) {
                pcmBytes = data[payloadStart..<payloadEnd]
            }
            // Chunks are zero-padded to even byte boundaries.
            cursor = payloadEnd + (size % 2)
        }

        guard let fmt, let pcmBytes else { return nil }
        // Beepbox contract: PCM (1), mono (1 channel), 16-bit. Accept the
        // sample rate as-is (caller is responsible for matching the C
        // engine's configured rate).
        guard fmt.audioFormat == 1, fmt.channels == 1, fmt.bitsPerSample == 16 else {
            return nil
        }

        let count = pcmBytes.count / 2
        var samples = [Float](repeating: 0, count: count)
        pcmBytes.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            let int16Buffer = raw.bindMemory(to: Int16.self)
            for i in 0..<count {
                samples[i] = Float(int16Buffer[i]) / 32768.0
            }
        }
        return samples
    }

    /// Builds a 16-bit PCM mono `audio/wav` blob from Float32 samples in
    /// [-1.0, 1.0]. Inverse of `float32Samples(from:)` — the same shape the
    /// SDK ecosystem speaks (PCM 1, mono, 16-bit), so the output round-trips
    /// back through `float32Samples(from:)`. Used by `sendScheduled(...)`
    /// (BEE-2329) to hand the C engine's scheduler PCM to a `WAVPlaybackSink`.
    ///
    /// - Parameter data: raw Float32 little-endian PCM (as returned by
    ///   `BeepingCoreWrapper.encodeWithSchedule`).
    internal static func wav16(fromFloat32 data: Data, sampleRate: UInt32 = 44100) -> Data {
        let floatCount = data.count / MemoryLayout<Float>.size
        var int16Samples = [Int16](repeating: 0, count: floatCount)
        data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            let floats = raw.bindMemory(to: Float.self)
            for i in 0..<floatCount {
                // Clamp to [-1, 1] then scale. 32767 (not 32768) so +1.0
                // maps to Int16.max without overflow.
                let clamped = max(-1.0, min(1.0, floats[i]))
                int16Samples[i] = Int16(clamped * 32767.0)
            }
        }

        let bitsPerSample: UInt16 = 16
        let channels: UInt16 = 1
        let byteRate = sampleRate * UInt32(channels) * UInt32(bitsPerSample / 8)
        let blockAlign = channels * (bitsPerSample / 8)
        let dataBytes = int16Samples.count * MemoryLayout<Int16>.size

        var wav = Data()
        wav.append(Data("RIFF".utf8))
        appendUInt32LE(&wav, UInt32(36 + dataBytes))  // ChunkSize
        wav.append(Data("WAVE".utf8))
        wav.append(Data("fmt ".utf8))
        appendUInt32LE(&wav, 16)  // Subchunk1Size (PCM)
        appendUInt16LE(&wav, 1)  // AudioFormat = PCM
        appendUInt16LE(&wav, channels)
        appendUInt32LE(&wav, sampleRate)
        appendUInt32LE(&wav, byteRate)
        appendUInt16LE(&wav, blockAlign)
        appendUInt16LE(&wav, bitsPerSample)
        wav.append(Data("data".utf8))
        appendUInt32LE(&wav, UInt32(dataBytes))
        int16Samples.withUnsafeBytes { wav.append(contentsOf: $0) }
        return wav
    }

    // MARK: - Internals

    private struct FormatChunk {
        let audioFormat: UInt16
        let channels: UInt16
        let sampleRate: UInt32
        let bitsPerSample: UInt16
    }

    private static func parseFormat(_ payload: Data) -> FormatChunk? {
        guard payload.count >= 16 else { return nil }
        let base = payload.startIndex
        return FormatChunk(
            audioFormat: readUInt16LE(payload, at: base),
            channels: readUInt16LE(payload, at: base + 2),
            sampleRate: readUInt32LE(payload, at: base + 4),
            bitsPerSample: readUInt16LE(payload, at: base + 14)
        )
    }

    private static func readUInt16LE(_ data: Data, at offset: Int) -> UInt16 {
        UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
    }

    private static func readUInt32LE(_ data: Data, at offset: Int) -> UInt32 {
        UInt32(data[offset])
            | (UInt32(data[offset + 1]) << 8)
            | (UInt32(data[offset + 2]) << 16)
            | (UInt32(data[offset + 3]) << 24)
    }

    private static func appendUInt16LE(_ data: inout Data, _ value: UInt16) {
        data.append(UInt8(value & 0xFF))
        data.append(UInt8((value >> 8) & 0xFF))
    }

    private static func appendUInt32LE(_ data: inout Data, _ value: UInt32) {
        data.append(UInt8(value & 0xFF))
        data.append(UInt8((value >> 8) & 0xFF))
        data.append(UInt8((value >> 16) & 0xFF))
        data.append(UInt8((value >> 24) & 0xFF))
    }
}
