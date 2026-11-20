import React from 'react';
import { Canvas } from '@react-three/fiber/native';
import TransitWorld from './TransitWorld';

export default function ExperienceScene() {
  return <Canvas dpr={1} camera={{position:[4.8,3.2,7.2],fov:36,near:.1,far:100}} gl={{antialias:true,alpha:false}}>
    <TransitWorld/>
  </Canvas>;
}