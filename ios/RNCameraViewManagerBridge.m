#import "React/RCTViewManager.h"

@interface RCT_EXTERN_MODULE(CameraView, RCTViewManager)
  // PROPS
  RCT_EXPORT_VIEW_PROPERTY(challangeType, NSNumber);
  RCT_EXPORT_VIEW_PROPERTY(onFinish, RCTBubblingEventBlock);
  
  // REF METHODS
  RCT_EXTERN_METHOD(start:(nonnull NSNumber *)node)
  RCT_EXTERN_METHOD(stop:(nonnull NSNumber *)node)
  RCT_EXTERN_METHOD(componentDidMount:(nonnull NSNumber *)node)
  RCT_EXTERN_METHOD(componentWillUnmount:(nonnull NSNumber *)node)

@end
