import React, { useMemo, useRef } from 'react';
import { Canvas, useFrame } from '@react-three/fiber';
import { Float, PerspectiveCamera, Stars } from '@react-three/drei';
import * as THREE from 'three';

function Bus({ position = [0, 0, 0], scale = 1, accent = '#6cf5d2' }) {
  const group = useRef();
  const wheels = useRef([]);
  useFrame((state, delta) => {
    if (group.current) {
      group.current.position.y = position[1] + Math.sin(state.clock.elapsedTime * 1.25) * 0.055;
      group.current.rotation.z = Math.sin(state.clock.elapsedTime * .7) * .012;
    }
    wheels.current.forEach((wheel) => { if (wheel) wheel.rotation.x -= delta * 1.8; });
  });
  return <group ref={group} position={position} scale={scale}>
    <mesh castShadow position={[0, .34, 0]}><boxGeometry args={[2.45, .72, 1.04]} /><meshStandardMaterial color="#d9e8e7" metalness={.42} roughness={.28} /></mesh>
    <mesh position={[.04, .39, .535]}><boxGeometry args={[1.72, .39, .018]} /><meshStandardMaterial color="#102c37" metalness={.55} roughness={.18} emissive="#173b46" emissiveIntensity={.45} /></mesh>
    <mesh position={[-.94, .37, .548]}><boxGeometry args={[.28, .4, .025]} /><meshStandardMaterial color="#102b35" metalness={.4} roughness={.2} /></mesh>
    <mesh position={[0, -.04, .535]}><boxGeometry args={[2.35, .105, .025]} /><meshStandardMaterial color={accent} emissive={accent} emissiveIntensity={1.8} /></mesh>
    <mesh position={[1.23, .23, .25]}><boxGeometry args={[.035, .16, .2]} /><meshStandardMaterial color="#fff1ca" emissive="#ffdfa0" emissiveIntensity={2.5} /></mesh>
    <mesh position={[-1.23, .22, .25]}><boxGeometry args={[.035, .13, .2]} /><meshStandardMaterial color="#ff5f76" emissive="#ff365e" emissiveIntensity={2} /></mesh>
    {[[-.78,-.13,.53],[.82,-.13,.53]].map((p,i)=><group key={i} position={p} ref={el=>wheels.current[i]=el}><mesh rotation={[Math.PI/2,0,0]}><cylinderGeometry args={[.22,.22,.12,24]} /><meshStandardMaterial color="#101c22" roughness={.85} /></mesh><mesh rotation={[Math.PI/2,0,0]}><cylinderGeometry args={[.105,.105,.125,16]} /><meshStandardMaterial color="#82999b" metalness={.8} roughness={.25} /></mesh></group>)}
    <mesh position={[0,.74,0]}><boxGeometry args={[.72,.045,.75]} /><meshStandardMaterial color="#d9e8e7" metalness={.4} /></mesh>
  </group>;
}
function City() {
  const blocks = useMemo(() => Array.from({length:34},(_,i)=>({x:(i%9-4)*1.3,z:(Math.floor(i/9)-1.5)*1.55,h:.35+((i*17)%9)*.17,w:.48+((i*7)%4)*.13})),[]);
  return <group>
    {blocks.map((b,i)=><group key={i} position={[b.x,0,b.z]}>
      <mesh position={[0,b.h/2-.04,0]}><boxGeometry args={[b.w,b.h,b.w]} /><meshStandardMaterial color={i%4===0?'#173a43':'#102832'} metalness={.35} roughness={.55} /></mesh>
      {Array.from({length:Math.max(1,Math.floor(b.h*5))},(_,j)=><mesh key={j} position={[0,.12+j*.16,b.w/2+.006]}><planeGeometry args={[.075,.045]} /><meshBasicMaterial color={i%3===0?'#6cf5d2':'#2c6470'} transparent opacity={.75} /></mesh>)}
    </group>)}
  </group>;
}
function SceneContent() {
  const ring = useRef();
  useFrame((state,delta)=>{ if(ring.current) ring.current.rotation.z += delta*.055; });
  return <>
    <PerspectiveCamera makeDefault position={[4.5,3.1,6.7]} fov={36} />
    <ambientLight intensity={1.1} />
    <directionalLight position={[4,7,4]} intensity={2.3} color="#d7fff4" />
    <pointLight position={[-3,2,1]} intensity={28} color="#39d9c0" distance={10} />
    <pointLight position={[3,1,-3]} intensity={18} color="#3986ff" distance={9} />
    <Stars radius={32} depth={24} count={500} factor={2} saturation={.2} fade speed={.35} />
    <gridHelper args={[28,38,'#1b5960','#102a33']} position={[0,-.31,0]} />
    <City />
    <Float speed={1.2} rotationIntensity={.04} floatIntensity={.12}>
      <Bus position={[0,.05,.2]} scale={1.12} />
    </Float>
    <mesh ref={ring} rotation={[-Math.PI/2,0,0]} position={[0,-.27,0]}>
      <torusGeometry args={[2.2,.012,8,100]} /><meshBasicMaterial color="#4ee8c8" transparent opacity={.75} />
    </mesh>
    <mesh rotation={[-Math.PI/2,0,0]} position={[0,-.29,0]}><ringGeometry args={[2.32,2.34,100]} /><meshBasicMaterial color="#3386a0" transparent opacity={.55} side={THREE.DoubleSide} /></mesh>
  </>;
}
export default function TransitScene() {
  return <Canvas dpr={[1,1.5]} gl={{ antialias:true, alpha:true, powerPreference:'high-performance' }} shadows>
    <SceneContent />
  </Canvas>;
}