import { NavigationProp, useNavigation } from "@react-navigation/native";
import React from "react";
import { Image, Platform, Text, TouchableOpacity, View } from "react-native";
import { ScrollView } from "react-native-gesture-handler";
import { SafeAreaView } from "react-native-safe-area-context";
import { ChallangeTypeEnum } from "../components";
import { BurgerMenu, TopButtonsWrapper } from "../components/BurgerMenu";
import { ScreenParams } from "../navigation/Root.navigation";

export interface IChallenge {
    id: ChallangeTypeEnum;
    name: string;
    shortDescription: string;
    description: string;
    videoUrl: string;
}

export const CHALLENGES: Record<ChallangeTypeEnum, IChallenge> = {
    [ChallangeTypeEnum.dribbling]: {
        id: ChallangeTypeEnum.dribbling,
        name: "Контроль и дриблинг",
        shortDescription: "Улучши технику ведения мяча",
        description: "Твоя задача - коснуться мячом точек на экране максимальное количество раз за одну минуту. Если телефон не определяет мяч,  попробуй изменить фон - скорее всего",
        videoUrl: "https://firebasestorage.googleapis.com/v0/b/cityfootball-4c767.appspot.com/o/%231vedenie.mp4?alt=media&token=cea06c5b-8096-420b-b159-4c52c9fdfdfe"
    },
    [ChallangeTypeEnum.juggling]: {
        id: ChallangeTypeEnum.juggling,
        name: "Чеканка",
        shortDescription: "Соревнуйся с друзьями за первое место!",
        description: "Твоя задача - коснуться мячом точек на экране максимальное количество раз за одну минуту.  Установи телефон так, чтобы желтая линия была на уровне твоей талии или чуть выше. Если телефон не определяет мяч, попробуй изменить фон - скорее всего",
        videoUrl: "https://firebasestorage.googleapis.com/v0/b/cityfootball-4c767.appspot.com/o/%232chekanka.mp4?alt=media&token=1eb7a3b9-f7a2-4065-b22d-f24d9e01ac3a"
    },
}

export const ChallangesListScreen = () => {
    const { goBack } = useNavigation<NavigationProp<ScreenParams>>();

    if (Platform.OS === 'android') {
        return (
            <SafeAreaView style={{ flex: 1 }}>
                <TopButtonsWrapper onPress={goBack}>
                    <BurgerMenu />
                </TopButtonsWrapper>

                <ScrollView contentContainerStyle={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
                    <Image
                        source={require('../assets/footbollPlayerBig.png')}
                        style={{}}
                    />
                    <Text
                        style={{
                            marginTop: 20,
                            width: 290,
                            fontWeight: '400',
                            fontSize: 16,
                            textAlign: 'center',
                            color: 'black'
                        }}
                    >
                        Функционал доступен только пользователям устройств на iOS.
                    </Text>
                </ScrollView>
            </SafeAreaView>
        )
    }

    return (
        <View>
            <TopButtonsWrapper onPress={goBack}>
                <BurgerMenu color="white" />
            </TopButtonsWrapper>

            <View
                style={[{
                    backgroundColor: '#2ECC71',
                    height: 200,
                }]}
            >
                <View style={{ marginTop: 85, marginLeft: 30 }}>
                    <Text
                        style={{
                            fontWeight: "700",
                            fontSize: 28,
                            color: "#ffffff"
                        }}
                    >
                        Проходи{'\n'}
                        челленджи!
                    </Text>
                    <Text
                        style={{
                            fontWeight: "500",
                            fontSize: 15,
                            color: "#ffffff"
                        }}
                    >
                        Соревнуйся с друзьями!
                    </Text>
                </View>
            </View>
            <ScrollView style={{ height: '120%' }}>
                {Object.values(CHALLENGES).map(item => <ChallengeItem key={item.id} item={item} />)}
            </ScrollView>
        </View>
    )
}

const ChallengeItem = ({ item }: { item: IChallenge }) => {
    const { navigate } = useNavigation<NavigationProp<ScreenParams>>();

    return (
        <TouchableOpacity onPress={() => navigate('ChallengeOwerview', { challengeType: item.id })}>
            <View
                style={{
                    marginVertical: 15,
                    width: '90%',
                    backgroundColor: '#ffffff',
                    alignSelf: 'center',
                    borderRadius: 25,
                    height: 160,
                }}
            >
                <View
                    style={{
                        width: '100%',
                        height: 80,
                        backgroundColor: '#FFD551',
                        borderTopEndRadius: 25,
                        borderTopStartRadius: 25,
                    }}
                />
                <View style={{ marginTop: 15, marginLeft: 20 }}>
                    <Text
                        style={{
                            fontWeight: "700",
                            fontSize: 15
                        }}
                    >
                        {item.name}
                    </Text>
                    <Text
                        style={{
                            fontWeight: "400",
                            fontSize: 12
                        }}
                    >
                        {item.shortDescription}
                    </Text>
                </View>
                <Image
                    source={require('../assets/footbollPlayer.png')}
                    style={{ position: 'absolute', right: 5, top: 15 }}
                />
            </View>
        </TouchableOpacity>
    )
}