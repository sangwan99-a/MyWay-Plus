import React, { useMemo, useState } from 'react';
import { motion } from 'framer-motion';
import { Activity, ArrowDownLeft, ArrowLeftRight, ArrowRight, ArrowUpRight, Bell, Bike, Bus, CalendarClock, Check, ChevronDown, Clock3, Compass, CreditCard, LocateFixed, MapPin, Menu, Navigation, Plus, Search, ShieldCheck, Sparkles, TrainFront, Wallet, X } from 'lucide-react';
import TransitScene from './components/TransitScene.jsx';

const routes = [
  { id:'R2', name:'City ↔ Belconnen', color:'#6cf5d2', eta:'4 min', destination:'Belconnen Interchange', status:'On time', occupancy:42 },
  { id:'R4', name:'City ↔ Woden', color:'#8aa8ff', eta:'8 min', destination:'Woden Interchange', status:'On time', occupancy:68 },
  { id:'R5', name:'City ↔ Tuggeranong', color:'#ffb86b', eta:'12 min', destination:'Tuggeranong', status:'On time', occupancy:31 },
];
const quickPlaces = ['Civic interchange','Canberra Centre','Australian National University','Woden interchange'];
function App() {
  const [tab,setTab] = useState('Overview');
  const [from,setFrom] = useState('Civic interchange');
  const [to,setTo] = useState('Australian National University');
  const [query,setQuery] = useState('');
  const [planned,setPlanned] = useState(false);
  const [menu,setMenu] = useState(false);
  const [saved,setSaved] = useState(['R2']);
  const [notice,setNotice] = useState(false);
  const filtered = useMemo(()=>quickPlaces.filter(p=>p.toLowerCase().includes(query.toLowerCase())),[query]);
  const swap = ()=>{setFrom(to);setTo(from);setPlanned(false);};
  const plan = (e)=>{e.preventDefault();setPlanned(true);setTab('Plan a trip');};
  return <div className="app-shell">
    <aside className={menu?'sidebar sidebar-open':'sidebar'}>
      <div className="brand"><div className="brand-mark"><Navigation size={20}/><span>+</span></div><div><b>myway<span>+</span></b><small>MOVE BEYOND</small></div><button className="close-menu" onClick={()=>setMenu(false)}><X size={18}/></button></div>
      <div className="network-pill"><span className="pulse-dot"/> CANBERRA NETWORK <ChevronDown size={13}/></div>
      <div className="nav-label">YOUR SPACE</div>
      {[[Compass,'Overview'],[Navigation,'Plan a trip'],[MapPin,'Explore map'],[Bus,'Live services'],[CreditCard,'My travel']].map(([Icon,label])=><button key={label} className={'nav-link '+(tab===label?'active':'')} onClick={()=>{setTab(label);setMenu(false)}}><Icon size={18}/>{label}{label==='Live services'&&<span className="nav-live"/>}</button>)}
      <div className="sidebar-bottom"><div className="upgrade-card"><div className="upgrade-icon"><Sparkles size={16}/></div><b>Your city. In motion.</b><p>One smarter view of every journey.</p><span>MYWAY+ EXPERIENCE <ArrowUpRight size={13}/></span></div><div className="profile"><div className="avatar">S</div><div><b>Guest traveller</b><small>Canberra, ACT</small></div><button aria-label="Profile options"><Menu size={17}/></button></div></div>
    </aside>
    {menu&&<button className="scrim" onClick={()=>setMenu(false)} aria-label="Close navigation"/>}
    <main className="main-area">
      <header className="topbar"><button className="mobile-menu" onClick={()=>setMenu(true)}><Menu/></button><div className="breadcrumb">CANBERRA <span>/</span> <b>{tab.toUpperCase()}</b></div><div className="top-actions"><div className="service-status"><span className="pulse-dot"/> NETWORK STATUS <b>DEMO</b></div><button className="icon-button" onClick={()=>setNotice(!notice)} aria-label="Notifications"><Bell size={18}/>{notice&&<i/>}</button><div className="top-avatar">S</div></div></header>
      {notice&&<div className="notice-pop"><b>You're all caught up</b><p>Service alerts will appear here when a live feed is connected.</p></div>}
      <section className="welcome-row"><div><div className="eyebrow"><span/> THE CITY, CONNECTED</div><h1>Move beyond<span>.</span></h1><p className="subhead">Your next journey starts here. Explore Canberra with a little more clarity.</p></div><div className="date-chip"><CalendarClock size={16}/><span>YOUR DAY, SIMPLIFIED</span></div></section>
      <section className="hero-card"><div className="hero-copy"><div className="hero-kicker"><span className="live-line"/> THE FUTURE OF GETTING THERE</div><h2>Every route.<br/><em>One clear view.</em></h2><p>See the network differently. Find your way across Canberra with smarter journeys and a real-time view built for you.</p><div className="hero-tags"><span><Activity size={13}/> Live-ready network</span><span><ShieldCheck size={13}/> Journey-first design</span></div><button className="hero-cta" onClick={()=>{setTab('Explore map');document.getElementById('network')?.scrollIntoView({behavior:'smooth'})}}>Explore the network <ArrowUpRight size={16}/></button></div><div className="hero-visual"><div className="orbit orbit-one"/><div className="orbit orbit-two"/><div className="scene-label"><span className="pulse-dot"/> 3D NETWORK PREVIEW <small>CONCEPT MODE</small></div><TransitScene/><div className="scene-coordinate">35° 16' S &nbsp; 149° 08' E</div><div className="floating-metric"><span>NETWORK DESIGN</span><b>01 <small>/ 03</small></b><i>CANBERRA REGION</i></div></div><div className="hero-index">01 — 03</div></section>
      <section className="trip-section" id="network"><div className="section-heading"><div><div className="eyebrow">MAKE IT YOURS</div><h2>Where to next?</h2></div><button className="text-button" onClick={()=>{setFrom('');setTo('');setPlanned(false)}}>Clear planner <X size={14}/></button></div>
        <form className="planner-card" onSubmit={plan}><div className="field-wrap"><label><span className="origin-dot"/> FROM</label><div className="field"><MapPin size={17}/><input value={from} onChange={e=>{setFrom(e.target.value);setPlanned(false)}} placeholder="Choose starting point" list="places"/></div></div><button type="button" className="swap-button" onClick={swap} aria-label="Swap locations"><ArrowLeftRight size={17}/></button><div className="field-wrap"><label><span className="destination-dot"/> TO</label><div className="field"><LocateFixed size={17}/><input value={to} onChange={e=>{setTo(e.target.value);setPlanned(false)}} placeholder="Where do you want to go?" list="places"/></div></div><datalist id="places">{quickPlaces.map(p=><option key={p} value={p}/>)}</datalist><button className="plan-button" type="submit" disabled={!from.trim()||!to.trim()}>Find a journey <ArrowRight size={16}/></button></form>
        {planned&&<motion.div initial={{opacity:0,y:8}} animate={{opacity:1,y:0}} className="plan-result"><div className="result-icon"><Check size={17}/></div><div><b>Journey request ready</b><p>{from} <ArrowRight size={12}/> {to} — connect a Transport Canberra journey-planning feed to calculate live routes and fares.</p></div><span>PREVIEW</span></motion.div>}
      </section>
      <section className="network-section"><div className="section-heading"><div><div className="eyebrow">ACROSS THE NETWORK</div><h2>Moving right now<span>.</span></h2></div><button className="view-all" onClick={()=>setTab('Live services')}>All services <ArrowUpRight size={15}/></button></div><div className="route-grid">{routes.map((r,i)=><motion.article key={r.id} className="route-card" initial={{opacity:0,y:12}} whileInView={{opacity:1,y:0}} viewport={{once:true}} transition={{delay:i*.08}}><div className="route-top"><span className="route-badge" style={{'--route':r.color}}>{r.id}</span><button className={'save-route '+(saved.includes(r.id)?'saved':'')} onClick={()=>setSaved(s=>s.includes(r.id)?s.filter(x=>x!==r.id):[...s,r.id])} aria-label="Save route"><Plus size={16}/></button></div><h3>{r.name}</h3><p className="route-destination"><MapPin size={13}/>{r.destination}</p><div className="route-bottom"><div><small>NEXT ARRIVAL</small><b>{r.eta}</b></div><div className="route-status"><span/> {r.status}</div></div><div className="occupancy"><span style={{width:r.occupancy+'%'}}/></div><small className="occupancy-label">ESTIMATED CAPACITY <b>{r.occupancy}%</b></small></motion.article>)}</div><p className="data-note"><Activity size={13}/> Sample interface data · Live departures, vehicle positions and capacity require an official data integration.</p></section>
      <footer><div className="footer-brand">myway<span>+</span></div><p>Designed to move you forward.</p><div className="footer-right">AN INDEPENDENT TRANSIT EXPERIENCE <span>•</span> CANBERRA, AU</div></footer>
    </main>
  </div>;
}
export default App;