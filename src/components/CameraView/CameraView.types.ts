import { ViewProps } from "react-native";

export enum ChallangeTypeEnum {
    dribbling = 0,
    juggling = 1
}

export interface OnFinishEvent {
    challangeType: ChallangeTypeEnum;
    touches: number
    counter: number
}

export interface RNCameraViewProps extends ViewProps {
    challangeType: ChallangeTypeEnum;
    onFinish(event?: OnFinishEvent): void;
}

export type NativeMethods = 'start' | 'stop' | 'componentDidMount' | 'componentWillUnmount';