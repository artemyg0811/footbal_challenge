import { NativeStackScreenProps } from "@react-navigation/native-stack"
import React, { useMemo } from "react"
import { Text, View } from "react-native"
import { TouchableOpacity } from "react-native"
import { ChallangeTypeEnum } from "../components"
import { ScreenParams } from "../navigation/Root.navigation"
import { CHALLENGES } from "./ChallengesList.screen"

export const ResultScreen = ({ navigation, route }: NativeStackScreenProps<ScreenParams, 'Result'>) => {
    const challangeType = route.params?.challangeType || ChallangeTypeEnum.dribbling
    const challenge = useMemo(() => CHALLENGES[challangeType], [challangeType])

    return (
        <>
            <View style={{ flex: 1 }}>
                <View
                    style={[{
                        backgroundColor: '#FFD551',
                        height: 200,
                    }]}
                >
                    <View style={{ marginTop: 130, marginLeft: 30 }}>
                        <Text
                            style={{
                                fontWeight: "700",
                                fontSize: 28,
                            }}
                        >
                            Результат
                        </Text>
                        <Text
                            style={{
                                fontWeight: "500",
                                fontSize: 16,
                            }}
                        >
                            {challenge.name}
                        </Text>
                    </View>
                </View>
                <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', }}>
                    <Text
                        style={{
                            fontWeight: "700",
                            fontSize: 20,
                            alignSelf: 'center',
                        }}
                    >
                        Ваш результат
                    </Text>
                    <Text
                        style={{
                            fontWeight: "700",
                            fontSize: 100,
                            alignSelf: 'center',
                        }}
                    >
                        {route.params?.touches || 0}
                    </Text>
                </View>

                <TouchableOpacity
                    onPress={() => navigation.reset({
                        routes: [{ name: 'Auth' }, { name: 'Main' }],
                    })}
                    style={{ backgroundColor: '#2ECC71', width: '90%', height: 60, alignSelf: 'center', bottom: 35, alignItems: 'center', justifyContent: 'center', borderRadius: 25, zIndex: 999, elevation: 999 }}
                >
                    <Text style={{ fontWeight: '700', fontSize: 18, color: '#ffffff' }} >На главную</Text>
                </TouchableOpacity>
            </View>
        </>
    )
}