import { CompositeScreenProps } from "@react-navigation/native"
import React from "react"
import { Button, Image, Text, TouchableOpacity, View } from "react-native"
import { ChallangeTypeEnum } from "../components"
import { BurgerMenu, TopButtonsWrapper } from "../components/BurgerMenu"

export const MainScreen = ({ navigation }: CompositeScreenProps<any, any>) => {

    return (
        <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
            <TopButtonsWrapper onPress={navigation.goBack}>
                <BurgerMenu />
            </TopButtonsWrapper>

            <TouchableOpacity onPress={navigation.goBack}>
                <Image source={require('../assets/ball.png')} />
            </TouchableOpacity>

            <TouchableOpacity
                onPress={navigation.goBack}
                style={{ marginTop: 70, backgroundColor: '#2ECC71', width: '90%', height: 60, alignSelf: 'center', alignItems: 'center', justifyContent: 'center', borderRadius: 25 }}
            >
                <Text style={{ fontWeight: '700', fontSize: 18, color: '#ffffff' }} >На главную</Text>
            </TouchableOpacity>

            <TouchableOpacity
                onPress={() => navigation.navigate('ChallangesList')}
                style={{ backgroundColor: '#FFD551', width: '90%', marginTop: 20, height: 60, alignSelf: 'center', alignItems: 'center', justifyContent: 'center', borderRadius: 25 }}
            >
                <Text style={{ fontWeight: '700', fontSize: 18, color: '#ffffff' }} >К челленджам</Text>
            </TouchableOpacity>
        </View>
    )
}