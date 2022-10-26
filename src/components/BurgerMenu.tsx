import React from "react"
import { TouchableOpacity, View } from "react-native"

export const BurgerMenu = ({ color = '#000000' }) => {
    return (
        <View style={{ height: 21, justifyContent: 'space-around' }}>
            <View style={{ width: 25, borderRadius: 12, height: 3.34, backgroundColor: color }} />
            <View style={{ width: 25, borderRadius: 12, height: 3.34, backgroundColor: color }} />
            <View style={{ width: 25, borderRadius: 12, height: 3.34, backgroundColor: color }} />
        </View >
    )
}

export const TopButtonsWrapper = ({ children = <></>, onPress = () => { } }) => {
    return (
        <TouchableOpacity onPress={onPress} style={{ position: 'absolute', top: 50, left: 30, zIndex: 999, elevation: 999 }}>
            {children}
        </TouchableOpacity>
    )
}