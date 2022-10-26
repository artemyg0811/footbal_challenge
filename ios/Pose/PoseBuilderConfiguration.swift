/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The implementation details of a structure that hold the parameters algorithms use for
 estimating poses.
*/

import CoreGraphics

enum Algorithm: Int {
    case single
}

struct PoseBuilderConfiguration {
    /// The minimum value for valid joints in a pose.
    var jointConfidenceThreshold = 0.1
    /// The minimum value for a valid pose.
    var poseConfidenceThreshold = 0.5
}
