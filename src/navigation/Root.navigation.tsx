import { ParamListBase } from '@react-navigation/native'
import { createStackNavigator } from '@react-navigation/stack'
import React from 'react'
import { ChallangeTypeEnum, OnFinishEvent } from '../components/CameraView'
import { AuthScreen } from '../screens/Auth.screen'
import { ChallengeOwerviewScreen } from '../screens/ChallengeOwerview.screen'
import { ChallangesListScreen } from '../screens/ChallengesList.screen'
import { MainScreen } from '../screens/Main.screen'
import { ResultScreen } from '../screens/Result.screen'
import { TrainingScreen } from '../screens/Training.screen'


export interface ScreenParams extends ParamListBase {
    Training: { challengeType: ChallangeTypeEnum },
    Result: OnFinishEvent;
    ChallengeOwerview: { challengeType: ChallangeTypeEnum }
}

const Root = createStackNavigator<ScreenParams>()

export const RootNavigation = () => {

    return (
        <Root.Navigator screenOptions={{ headerShown: false }}>
            <Root.Screen name='Auth' component={AuthScreen} />
            <Root.Screen name='Main' component={MainScreen} />
            <Root.Screen name='ChallangesList' component={ChallangesListScreen} />
            <Root.Screen name='ChallengeOwerview' component={ChallengeOwerviewScreen} />
            <Root.Screen name='Training' component={TrainingScreen} />
            <Root.Screen name='Result' component={ResultScreen} />
        </Root.Navigator>
    )
}
