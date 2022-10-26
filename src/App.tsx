import { NavigationContainer } from '@react-navigation/native';
import React, { useEffect } from 'react';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import Orientation from 'react-native-orientation';

import { RootNavigation } from './navigation/Root.navigation';

export const App = () => {
  useEffect(() => {
    Orientation.lockToPortrait();
  }, [])
  
  return (
    <GestureHandlerRootView style={{ flex: 1, backgroundColor: 'white' }}>
      <NavigationContainer>
          <RootNavigation />
      </NavigationContainer>
    </GestureHandlerRootView>
  );
};
