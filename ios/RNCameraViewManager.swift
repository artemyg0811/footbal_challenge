import Foundation

@objc(CameraView)
class CameraViewManager : RCTViewManager {
  override func view() -> UIView! {
    return  UICameraView();
  }

  // this is required since RN 0.49+
  override class func requiresMainQueueSetup() -> Bool {
    return true
  }
  
  @objc func start(_ node: NSNumber) {
     DispatchQueue.main.async {
       let component = self.bridge.uiManager.view(
         forReactTag: node
       ) as! UICameraView
       component.start();
     }
   }
  
  @objc func stop(_ node: NSNumber) {
     DispatchQueue.main.async {
       let component = self.bridge.uiManager.view(
         forReactTag: node
       ) as! UICameraView
       component.stop();
     }
   }
  
  @objc func componentDidMount(_ node: NSNumber) {
     DispatchQueue.main.async {
       let component = self.bridge.uiManager.view(
         forReactTag: node
       ) as! UICameraView
       component.componentDidMount();
     }
   }
  
  @objc func componentWillUnmount(_ node: NSNumber) {
     DispatchQueue.main.async {
       let component = self.bridge.uiManager.view(
         forReactTag: node
       ) as! UICameraView
       component.componentWillUnmount();
     }
   }

}
