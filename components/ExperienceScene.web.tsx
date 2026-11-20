import React from 'react';
import { Canvas } from '@react-three/fiber';
import { EffectComposer, Bloom, Noise, Vignette } from '@react-three/postprocessing';
import TransitWorld from './TransitWorld';

export default function ExperienceScene() {
  return <Canvas dpr={[1,1.5]} camera={{position:[4.8,3.2,7.2],fov:36,near:.1,far:100}} gl={{antialias:false,alpha:false,powerPreference:'high-performance'}}>
    <TransitWorld/>
    <EffectComposer multisampling={0} disableNormalPass>
      <Bloom mipmapBlur intensity={1.05} luminanceThreshold={.58} luminanceSmoothing={.25} radius={.8}/>
      <Noise opacity={.13}/>
      <Vignette offset={.24} darkness={.78}/>
    </EffectComposer>
  </Canvas>;
}