import { NativeStackScreenProps } from "@react-navigation/native-stack"
import React, { useEffect, useMemo, useRef, useState } from "react"
import { Image, StyleSheet, Text, TouchableOpacity, View } from "react-native"
import { ScrollView } from "react-native-gesture-handler"
import { ScreenParams } from "../navigation/Root.navigation"
import { CHALLENGES } from "./ChallengesList.screen"
// @ts-ignore
import VideoPlayer from 'react-native-video-controls'
import { BurgerMenu, TopButtonsWrapper } from "../components/BurgerMenu"

export const ChallengeOwerviewScreen = ({ route, navigation }: NativeStackScreenProps<ScreenParams, 'ChallengeOwerview'>) => {
    const challengeType = route.params?.challengeType

    const challenge = useMemo(() => CHALLENGES[challengeType], [challengeType])

    const videoRef = useRef()

    const [paused, setPaused] = useState(true);

    useEffect(() => () => setPaused(true), [])

    return (
        <View style={{ flex: 1 }}>
            <TopButtonsWrapper onPress={navigation.goBack}>
                <Image source={require('../assets/backArrow.png')} />
            </TopButtonsWrapper>

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
                        {challenge.name}
                    </Text>
                </View>
            </View>
            <ScrollView style={{ flex: 1 }} contentContainerStyle={{ height: '120%', justifyContent: 'space-between' }}>
                <View>

                    <Text
                        style={{
                            fontWeight: "500",
                            fontSize: 14,
                            width: '90%',
                            alignSelf: 'center',
                            marginTop: 20
                        }}
                    >
                        {challenge.description}
                    </Text>

                    <View style={{ backgroundColor: 'black', height: 210, marginTop: 20, width: '90%', alignSelf: 'center', borderRadius: 25, borderWidth: StyleSheet.hairlineWidth }}>
                        <VideoPlayer
                            ref={videoRef}
                            onPlay={() => setPaused(false)}
                            onPause={() => setPaused(false)}
                            paused={paused}
                            source={{ uri: challenge.videoUrl }}
                            disableFullscreen
                            disableBack
                            style={{
                                width: '100%',
                                alignSelf: 'center',
                                height: '100%',
                                borderRadius: 25,
                                backgroundColor: '#A0A0A0'
                            }}
                        />
                    </View>
                </View>

                <View style={{ flex: 0.3 }} />

                <TouchableOpacity
                    onPress={() => navigation.reset({ routes: [{ name: 'Training', params: { challengeType } }] })}
                    style={{ backgroundColor: '#2ECC71', width: '90%', height: 60, alignSelf: 'center', alignItems: 'center', justifyContent: 'center', borderRadius: 25 }}
                >
                    <Text style={{ fontWeight: '700', fontSize: 18, color: '#ffffff' }} >Начать челлендж</Text>
                </TouchableOpacity>

                <View style={{ flex: 1 }} />
            </ScrollView>
        </View>
    )
}