
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import React from 'react';
import { Text, TouchableOpacity, View } from 'react-native';
import Orientation from 'react-native-orientation';
import { ChallangeTypeEnum, CameraView } from '../components';
import { ScreenParams } from '../navigation/Root.navigation';

export const TrainNamesMap = {
    [ChallangeTypeEnum.dribbling]: "dribbling",
    [ChallangeTypeEnum.juggling]: "juggling",
}

export class TrainingScreen extends React.Component<NativeStackScreenProps<ScreenParams, 'Training'>> {
    private _cameraRef = React.createRef<CameraView>()

    componentDidMount() {
        Orientation.lockToLandscape();
        this._cameraRef?.current?.start?.()

        this.props.navigation.addListener('blur', () => {
            Orientation.lockToPortrait();
            this._cameraRef?.current?.stop?.()
        })

        this.props.navigation.addListener('focus', () => {
            const challengeType = this.props.route.params?.challengeType || ChallangeTypeEnum.dribbling;
            this.props.navigation.setOptions({
                title: TrainNamesMap[challengeType],
            })

            Orientation.lockToLandscape();
            this._cameraRef?.current?.start?.()
        })
    }

    componentWillUnmount() {
        this._cameraRef?.current?.stop?.()
        Orientation.lockToPortrait();
    }

    render() {
        return (
            <>
                <CameraView
                    ref={this._cameraRef}
                    onFinish={(event) => {
                        this.props.navigation.reset({
                            routes: [{ name: 'Result', params: event }],
                        });
                    }}
                    challangeType={this.props.route.params.challengeType}
                    style={{ flex: 1 }} />

                <TouchableOpacity
                    onPress={() => {
                        // Orientation.lockToPortrait();
                        this._cameraRef.current?.stop?.();
                    }}
                    style={{ zIndex: 999, elevation: 999, position: 'absolute', top: 20, right: 50, borderRadius: 100, width: 50, height: 50, backgroundColor: "#FFD551", alignItems: 'center', justifyContent: 'center' }}>
                    <Text>X</Text>
                </TouchableOpacity>
            </>
        );
    }
};