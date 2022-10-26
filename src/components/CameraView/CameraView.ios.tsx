import React from 'react';
import { findNodeHandle, requireNativeComponent, UIManager, ViewProps } from 'react-native';
import { NativeMethods, RNCameraViewProps } from './CameraView.types';

const RNCameraView = requireNativeComponent('CameraView')

export class CameraView extends React.PureComponent<RNCameraViewProps> {
    private NATIVE_REF = React.createRef()

    private _callNativeMethod(methodName: NativeMethods, ...args: any){
       return UIManager.dispatchViewManagerCommand(
            // @ts-ignore
            findNodeHandle(this.NATIVE_REF.current),
            // @ts-ignore
            UIManager.CameraView.Commands[methodName],
            [...args]
        );
    }

    public start = () => {
        this._callNativeMethod('start')
    }

    public stop = () => {
        this._callNativeMethod('stop')
    }

    componentDidMount(){
        this._callNativeMethod('componentDidMount')
    }
   
    componentWillUnmount() {
        this._callNativeMethod('componentWillUnmount')
    }

    render() {
        return (

            <>
                <RNCameraView
                    // @ts-ignore
                    ref={this.NATIVE_REF}
                    // @ts-ignore
                    onFinish={({ nativeEvent }) => {
                        delete nativeEvent.target;
                        this.props?.onFinish?.(nativeEvent)
                    }}
                    challangeType={this.props.challangeType}
                    style={{ flex: 1 }} />
            </>
        );
    }
};