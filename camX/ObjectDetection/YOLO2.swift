import Foundation
import UIKit
import CoreML

class YOLO2 {

    // Anchor boxes
    let anchors: [Float] = [0.57273, 0.677385, 1.87446, 2.06253, 3.33843, 5.47434, 7.88282, 3.52778, 9.77052, 9.16828]

    // Tweak these values to get more or fewer predictions.
    let confidenceThreshold: Float = 0.5
    let iouThreshold: Float = 0.6

    let model = yolo2()
    
    // Singleton instance
    static let sharedInstance = YOLO2()
    
    private init() {}
    
    public func predict(image: CVPixelBuffer) throws -> [Prediction] {
        if let output = try? model.prediction(input__0: image) {
            return computeBoundingBoxes(features: output.output__0)
        } else {
            return []
        }
    }

    public func computeBoundingBoxes(features: MLMultiArray) -> [Prediction] {
        //  assert(features.count == 125*13*13)
        assert(features.count == 425*19*19)

        var predictions = [Prediction]()

        let blockSize: Float = 32
        let gridHeight = 19
        let gridWidth = 19
        let boxesPerCell = 5;//Int(anchors.count/5)
        let numClasses = 80

        // The 608x608 image is divided into a 19x19 grid. Each of these grid cells
        // will predict 5 bounding boxes (boxesPerCell). A bounding box consists of
        // five data items: x, y, width, height, and a confidence score. Each grid
        // cell also predicts which class each bounding box belongs to.
        //
        // The "features" array therefore contains (numClasses + 5)*boxesPerCell
        // values for each grid cell, i.e. 425 channels. The total features array
        // contains 425x19x19 elements.

        // NOTE: It turns out that accessing the elements in the multi-array as
        // `features[[channel, cy, cx] as [NSNumber]].floatValue` is kinda slow.
        // It's much faster to use direct memory access to the features.
        let featurePointer = UnsafeMutablePointer<Double>(OpaquePointer(features.dataPointer))
        let channelStride = features.strides[0].intValue
        let yStride = features.strides[1].intValue
        let xStride = features.strides[2].intValue

        func offset(_ channel: Int, _ x: Int, _ y: Int) -> Int {
            return channel*channelStride + y*yStride + x*xStride
        }

        for cy in 0..<gridHeight {
            for cx in 0..<gridWidth {
                for b in 0..<boxesPerCell {

                    // For the first bounding box (b=0) we have to read channels 0-24,
                    // for b=1 we have to read channels 25-49, and so on.
                    let channel = b*(numClasses + 5)

                    // The slow way:
                    /*
                    let tx = features[[channel    , cy, cx] as [NSNumber]].floatValue
                    let ty = features[[channel + 1, cy, cx] as [NSNumber]].floatValue
                    let tw = features[[channel + 2, cy, cx] as [NSNumber]].floatValue
                    let th = features[[channel + 3, cy, cx] as [NSNumber]].floatValue
                    let tc = features[[channel + 4, cy, cx] as [NSNumber]].floatValue
                    */

                    // The fast way:
                    let tx = Float(featurePointer[offset(channel    , cx, cy)])
                    let ty = Float(featurePointer[offset(channel + 1, cx, cy)])
                    let tw = Float(featurePointer[offset(channel + 2, cx, cy)])
                    let th = Float(featurePointer[offset(channel + 3, cx, cy)])
                    let tc = Float(featurePointer[offset(channel + 4, cx, cy)])
                    
                    // The predicted tx and ty coordinates are relative to the location
                    // of the grid cell; we use the logistic sigmoid to constrain these
                    // coordinates to the range 0 - 1. Then we add the cell coordinates
                    // (0-12) and multiply by the number of pixels per grid cell (32).
                    // Now x and y represent center of the bounding box in the original
                    // 608x608 image space.
                    let x = (Float(cx) + sigmoid(tx)) * blockSize
                    let y = (Float(cy) + sigmoid(ty)) * blockSize

                    // The size of the bounding box, tw and th, is predicted relative to
                    // the size of an "anchor" box. Here we also transform the width and
                    // height into the original 416x416 image space.
                    let w = exp(tw) * anchors[2*b    ] * blockSize
                    let h = exp(th) * anchors[2*b + 1] * blockSize

                    // The confidence value for the bounding box is given by tc. We use
                    // the logistic sigmoid to turn this into a percentage.
                    let confidence = sigmoid(tc)

                    // Gather the predicted classes for this anchor box and softmax them,
                    // so we can interpret these numbers as percentages.
                    var classes = [Float](repeating: 0, count: numClasses)
                    for c in 0..<numClasses {
                        // The slow way:
                        //classes[c] = features[[channel + 5 + c, cy, cx] as [NSNumber]].floatValue

                        // The fast way:
                        classes[c] = Float(featurePointer[offset(channel + 5 + c, cx, cy)])
                    }
                    classes = softmax(classes)
                    // Find the index of the class with the largest score.
                    let (detectedClass, bestClassScore) = classes.argmax()

                    // Combine the confidence score for the bounding box, which tells us
                    // how likely it is that there is an object in this box (but not what
                    // kind of object it is), with the largest class prediction, which
                    // tells us what kind of object it detected (but not where).
                    let confidenceInClass = bestClassScore * confidence

                    // Since we compute 19x19x5 = 1805 bounding boxes, we only want to
                    // keep the ones whose combined score is over a certain threshold.
                    if confidenceInClass > confidenceThreshold {
                        let rect = CGRect(x: CGFloat(x - w/2), y: CGFloat(y - h/2), width: CGFloat(w), height: CGFloat(h))

                        let prediction = Prediction(classIndex: detectedClass, score: confidenceInClass, rect: rect)
                        predictions.append(prediction)
                    }
                }
            }
        }

        // We already filtered out any bounding boxes that have very low scores,
        // but there still may be boxes that overlap too much with others. We'll
        // use "non-maximum suppression" to prune those duplicate bounding boxes.
        return nonMaxSuppression(boxes: predictions, limit: SettingManager.sharedInstance.maxBoundingBoxes, threshold: iouThreshold)
      }
}
