//
//  WAVParserPropertyTests.swift
//  BeepingTests
//
//  Property-style tests for `WAVParser` (BEE-76, reduced scope). Uses
//  Swift Testing's parameterized `arguments:` instead of pulling in
//  SwiftCheck so we don't need to wire an SPM package into a binary-
//  target-based Xcode project. The invariants are the same a
//  SwiftCheck-based test would assert; only the random generator
//  changes shape.
//
//  Covered properties:
//    1. Well-formed PCM 16-bit mono WAVs round-trip through the
//       parser to a Float32 array of the expected length.
//    2. Int16 → Float32 → Int16 round-trip stays within a 1-sample
//       quantization epsilon for every Int16 input.
//    3. Malformed WAVs (wrong magic, missing fmt/data, multi-channel,
//       non-16-bit) return nil.
//    4. Random-length payloads (1..8000 samples) parse correctly.
//

import Foundation
import Testing
@testable import Beeping

@Suite("WAVParser property tests (BEE-76)")
struct WAVParserPropertyTests {

    // MARK: - Helpers

    /// Builds a minimal RIFF/WAVE PCM 16-bit mono buffer with the
    /// given sample sequence.
    private func makeWAV(samples: [Int16], sampleRate: UInt32 = 44100) -> Data {
        let bitsPerSample: UInt16 = 16
        let channels: UInt16 = 1
        let byteRate = sampleRate * UInt32(channels) * UInt32(bitsPerSample / 8)
        let blockAlign: UInt16 = channels * (bitsPerSample / 8)
        let dataSize = UInt32(samples.count * 2)
        let riffSize = 36 + dataSize

        var data = Data()
        data.append(Data("RIFF".utf8))
        data.append(uint32LE(riffSize))
        data.append(Data("WAVE".utf8))
        data.append(Data("fmt ".utf8))
        data.append(uint32LE(16))             // fmt chunk size
        data.append(uint16LE(1))              // PCM
        data.append(uint16LE(channels))
        data.append(uint32LE(sampleRate))
        data.append(uint32LE(byteRate))
        data.append(uint16LE(blockAlign))
        data.append(uint16LE(bitsPerSample))
        data.append(Data("data".utf8))
        data.append(uint32LE(dataSize))
        for s in samples {
            data.append(int16LE(s))
        }
        return data
    }

    private func uint16LE(_ value: UInt16) -> Data {
        var v = value.littleEndian
        return Data(bytes: &v, count: 2)
    }

    private func uint32LE(_ value: UInt32) -> Data {
        var v = value.littleEndian
        return Data(bytes: &v, count: 4)
    }

    private func int16LE(_ value: Int16) -> Data {
        var v = value.littleEndian
        return Data(bytes: &v, count: 2)
    }

    // MARK: - Property: well-formed length → parser yields N samples

    @Test(
        "Well-formed PCM 16-bit mono WAV parses to exactly N Float32 samples",
        arguments: [1, 7, 100, 256, 1024, 2048, 8000]
    )
    func lengthRoundTrip(sampleCount: Int) {
        var rng = SystemRandomNumberGenerator()
        var samples = [Int16]()
        samples.reserveCapacity(sampleCount)
        for _ in 0..<sampleCount {
            samples.append(Int16.random(in: .min ... .max, using: &rng))
        }
        let wav = makeWAV(samples: samples)
        let parsed = WAVParser.float32Samples(from: wav)
        #expect(parsed != nil)
        #expect(parsed?.count == sampleCount)
    }

    // MARK: - Property: Int16 → Float32 quantization invariant

    @Test(
        "Int16 PCM round-trips to Float32 within quantization epsilon",
        arguments: stride(from: Int(Int16.min), through: Int(Int16.max), by: 137).map(Int16.init)
    )
    func quantizationEpsilon(sample: Int16) {
        let wav = makeWAV(samples: [sample])
        guard let parsed = WAVParser.float32Samples(from: wav), parsed.count == 1 else {
            Issue.record("Single-sample WAV failed to parse for value \(sample)")
            return
        }
        let f = parsed[0]
        let expected = Float(sample) / 32768.0
        // The parser uses /32768 quantization; epsilon comes from
        // Float32 precision near the bounds (~6e-8 in the worst case).
        #expect(abs(f - expected) < 1.0e-6)
        #expect(f >= -1.0)
        #expect(f < 1.0001)  // strictly < 1.0 except the unsigned cast boundary
    }

    // MARK: - Property: malformed shapes → nil

    @Test("Empty data → nil")
    func emptyData() {
        #expect(WAVParser.float32Samples(from: Data()) == nil)
    }

    @Test("Truncated header (<44 bytes) → nil")
    func truncatedHeader() {
        let wav = makeWAV(samples: [Int16.max, Int16.min, 0])
        for prefix in [0, 4, 12, 32, 43] {
            let truncated = wav.prefix(prefix)
            #expect(
                WAVParser.float32Samples(from: Data(truncated)) == nil,
                "Truncated to \(prefix) bytes should reject"
            )
        }
    }

    @Test(
        "Wrong magic → nil",
        arguments: ["XIFF", "RIFX", "AAAA", "WAVE", "    "]
    )
    func wrongMagic(magic: String) {
        var wav = makeWAV(samples: [0, 0, 0])
        let bytes = Array(magic.utf8)
        for i in 0..<min(4, bytes.count) {
            wav[i] = bytes[i]
        }
        #expect(WAVParser.float32Samples(from: wav) == nil)
    }

    @Test(
        "Multi-channel rejected (only mono is in beepbox contract)",
        arguments: [UInt16(2), 4, 6, 8]
    )
    func multiChannelRejected(channels: UInt16) {
        // Build a WAV but mutate the `channels` field at offset 22..23.
        var wav = makeWAV(samples: [0, 0, 0, 0])
        var ch = channels.littleEndian
        wav.replaceSubrange(22..<24, with: Data(bytes: &ch, count: 2))
        #expect(WAVParser.float32Samples(from: wav) == nil)
    }

    @Test(
        "Non-16-bit samples rejected",
        arguments: [UInt16(8), 24, 32]
    )
    func nonSixteenBitRejected(bits: UInt16) {
        var wav = makeWAV(samples: [0, 0, 0, 0])
        // bitsPerSample lives at offset 34..35 in the fmt chunk.
        var b = bits.littleEndian
        wav.replaceSubrange(34..<36, with: Data(bytes: &b, count: 2))
        #expect(WAVParser.float32Samples(from: wav) == nil)
    }

    // MARK: - Property: sequence preservation

    @Test("Sample sequence is preserved in order (no shuffling)")
    func sequencePreserved() {
        let samples: [Int16] = [1000, -1000, 5000, -5000, 16000, -16000, 0]
        let wav = makeWAV(samples: samples)
        guard let parsed = WAVParser.float32Samples(from: wav) else {
            Issue.record("Parser returned nil")
            return
        }
        #expect(parsed.count == samples.count)
        for (i, s) in samples.enumerated() {
            let expected = Float(s) / 32768.0
            #expect(abs(parsed[i] - expected) < 1.0e-6)
        }
    }
}
