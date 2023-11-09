//
//  GenericAudioEngine.swift
//
//  Copyright © 2020 GORA Studio. https://gora.studio
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import AVFoundation
import UIKit

@available(iOS 13.0, *)
public final class GenericAudioEngine {

    public var audioFormat: AVAudioFormat?

    public weak var recorder: BaseRecorder? {
        didSet {
            oldValue?.audioInput.audioFormat = nil
            guard let recorder = recorder else {
                return
            }

            recorder.audioInput.audioFormat = self.audioFormat
        }
    }

    @Observable public internal(set) var error: Swift.Error?

    public init() {
    }

    deinit {
        recorder?.audioInput.audioFormat = nil
    }

    public func pushAudioSamples(from buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        guard let recorder = self.recorder else { return }

        do {
            let sampleBuffer = try Self.createAudioSampleBuffer(from: buffer, time: time)
            recorder.audioInput.genericAudioEngine(self, didOutputAudioSampleBuffer: sampleBuffer)
        }
        catch {
            self.error = error
        }
    }
}



@available(iOS 13.0, *)
extension GenericAudioEngine {

    static func createAudioSampleBuffer(from buffer: AVAudioPCMBuffer, time: AVAudioTime) throws -> CMSampleBuffer {
        let audioBufferList = buffer.mutableAudioBufferList
        let streamDescription = buffer.format.streamDescription.pointee
        let timescale = CMTimeScale(streamDescription.mSampleRate)
        let format = try CMAudioFormatDescription(audioStreamBasicDescription: streamDescription)
        let sampleBuffer = try CMSampleBuffer(
            dataBuffer: nil,
            formatDescription: format,
            numSamples: CMItemCount(buffer.frameLength),
            sampleTimings: [
                CMSampleTimingInfo(
                    duration: CMTime(value: 1, timescale: timescale),
                    presentationTimeStamp: CMTime(
                        seconds: AVAudioTime.seconds(forHostTime: time.hostTime),
                        preferredTimescale: timescale
                    ),
                    decodeTimeStamp: .invalid
                )
            ],
            sampleSizes: []
        )
        try sampleBuffer.setDataBuffer(fromAudioBufferList: audioBufferList)
        return sampleBuffer
    }
}
