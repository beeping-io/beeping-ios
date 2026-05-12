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
}
