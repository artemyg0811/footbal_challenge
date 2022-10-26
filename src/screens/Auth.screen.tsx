import { CompositeScreenProps } from "@react-navigation/native";
import React from "react";
import { Image, TouchableOpacity, View } from "react-native";
import { BurgerMenu, TopButtonsWrapper } from "../components/BurgerMenu";

export const AuthScreen = ({ navigation }: CompositeScreenProps<any, any>) => {

    return (
        <View style={{ flex: 1 }}>
            <TopButtonsWrapper onPress={() => navigation.navigate('Main')}>
                <BurgerMenu />
            </TopButtonsWrapper>

            <TouchableOpacity onPress={() => navigation.navigate('Main')}>
                <Image style={{ position: 'absolute', right: 30, top: 150 }} source={require('../assets/ballFace.png')}></Image>
            </TouchableOpacity>
        </View>
    )
}