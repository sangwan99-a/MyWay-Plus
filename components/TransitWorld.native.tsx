import React, { useMemo, useRef } from 'react';
import { useFrame } from '@react-three/fiber/native';
import * as THREE from 'three';

function Bus() {
  const root = useRef<THREE.Group>(null);
  const wheelRefs = useRef<THREE.Mesh[]>([]);
  useFrame((state, dt) => {
    if (root.current) {
      root.current.position.y = Math.sin(state.clock.elapsedTime * 1.25) * 0.055;
      root.current.rotation.z = Math.sin(state.clock.elapsedTime * .55) * .018;
    }
    wheelRefs.current.forEach(w => { if (w) w.rotation.x -= dt * 1.5; });
  });
  return <group ref={root} position={[0, .1, 0]}>
    <mesh castShadow position={[0,.25,0]}><boxGeometry args={[2.45,.72,1.02]}/><meshStandardMaterial color="#c9c9cd" metalness={.48} roughness={.3}/></mesh>
    <mesh position={[0,.31,.515]}><boxGeometry args={[1.82,.39,.018]}/><meshStandardMaterial color="#151519" metalness={.5} roughness={.16} emissive="#24242b" emissiveIntensity={.6}/></mesh>
    <mesh position={[0,-.13,.52]}><boxGeometry args={[2.34,.08,.025]}/><meshStandardMaterial color="#dedee2" emissive="#c6c6d2" emissiveIntensity={.55}/></mesh>
    <mesh position={[1.22,.2,.25]}><boxGeometry args={[.025,.13,.18]}/><meshBasicMaterial color="#fff1d6"/></mesh>
    <mesh position={[-1.22,.2,.25]}><boxGeometry args={[.025,.13,.18]}/><meshBasicMaterial color="#ff596b"/></mesh>
    {[[-.78,-.18,.51],[.82,-.18,.51]].map((p,i)=><group key={i} position={p as [number,number,number]}><mesh ref={el=>{if(el)wheelRefs.current[i]=el}} rotation={[Math.PI/2,0,0]}><cylinderGeometry args={[.22,.22,.13,24]}/><meshStandardMaterial color="#111115" roughness={.9}/></mesh><mesh rotation={[Math.PI/2,0,0]}><cylinderGeometry args={[.1,.1,.14,18]}/><meshStandardMaterial color="#a3a3aa" metalness={.85} roughness={.25}/></mesh></group>)}
    <mesh position={[0,.63,0]}><boxGeometry args={[.65,.04,.68]}/><meshStandardMaterial color="#bdbdc3" metalness={.5}/></mesh>
  </group>;
}
function City() {
  const blocks = useMemo(()=>Array.from({length:56},(_,i)=>({x:(i%8-3.5)*1.45,z:(Math.floor(i/8)-3)*1.55,h:.35+((i*17)%11)*.15,w:.42+((i*7)%4)*.12})),[]);
  return <group>{blocks.map((b,i)=><group key={i} position={[b.x,0,b.z]}>
    <mesh position={[0,b.h/2-.1,0]}><boxGeometry args={[b.w,b.h,b.w]}/><meshStandardMaterial color={i%5===0?'#29292f':'#17171d'} metalness={.35} roughness={.62}/></mesh>
    {Array.from({length:Math.max(1,Math.floor(b.h*4))},(_,j)=><mesh key={j} position={[0,.08+j*.14,b.w/2+.006]}><planeGeometry args={[.055,.035]}/><meshBasicMaterial color={i%4===0?'#e5e5eb':'#777780'} transparent opacity={.65}/></mesh>)}
  </group>)}</group>;
}
function Dust() {
  const ref=useRef<THREE.Points>(null);
  const positions=useMemo(()=>{const a=new Float32Array(420*3);for(let i=0;i<420;i++){a[i*3]=(Math.random()-.5)*18;a[i*3+1]=(Math.random()-.5)*8;a[i*3+2]=(Math.random()-.5)*18;}return a;},[]);
  useFrame((_,dt)=>{if(ref.current)ref.current.rotation.y+=dt*.008;});
  return <points ref={ref}><bufferGeometry><bufferAttribute attach="attributes-position" args={[positions,3]}/></bufferGeometry><pointsMaterial color="#d9d9e0" size={.018} transparent opacity={.62} sizeAttenuation/></points>;
}
export default function TransitWorld() {
  const orbit=useRef<THREE.Group>(null);
  useFrame((_,dt)=>{if(orbit.current)orbit.current.rotation.z+=dt*.035;});
  return <>
    <color attach="background" args={['#09090a']}/><fogExp2 attach="fog" args={['#09090a',.045]}/>
    <ambientLight intensity={.28}/><hemisphereLight args={['#b9b9c7','#08080a',.32]}/>
    <directionalLight position={[4,7,5]} intensity={2.1} color="#f1f0f4"/>
    <pointLight position={[-3,2,1]} intensity={22} color="#b7b7d0" distance={10}/>
    <pointLight position={[3,1,-3]} intensity={15} color="#77778d" distance={9}/>
    <group position={[0,-.2,-1]}><City/></group>
    <Bus/>
    <group ref={orbit} rotation={[-Math.PI/2,0,0]} position={[0,-.19,0]}>
      <mesh><torusGeometry args={[2.15,.009,8,120]}/><meshBasicMaterial color="#d6d6df" transparent opacity={.6}/></mesh>
      <mesh rotation={[0,0,1.3]}><torusGeometry args={[2.55,.006,8,120]}/><meshBasicMaterial color="#777784" transparent opacity={.42}/></mesh>
    </group>
    <gridHelper args={[28,42,'#33333b','#17171d']} position={[0,-.27,0]}/>
    <Dust/>
  </>;
}