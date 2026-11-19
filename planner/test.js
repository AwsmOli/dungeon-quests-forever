const P = require('./engine.js');
const D = require('./data.json');
const H = D.hubs;
const only = process.argv[2];
const M={name:'Mage',cls:'mage',eng:'none'}, O=(n)=>({name:'P'+n,cls:'warrior',eng:'none'}), W={name:'Lock',cls:'warlock',eng:'none'}, G={name:'Gob',cls:'rogue',eng:'goblin'}, Dr={name:'Druid',cls:'druid',eng:'none'};
const f1 = (x)=>x.toFixed(1);
function show(d, f, players, start, opt) {
  const t0 = Date.now();
  const r = P.plan(H, d, {faction: f, players, start, includeOptional: !!opt});
  const ms = Date.now()-t0;
  console.log(`\n== ${d.short} ${f} [${players.map(p=>p.name).join(',')}] opt=${!!opt}: ${r.mode} total ${f1(r.total)} (other ${r.compare!=null?f1(r.compare):'-'}) ${ms}ms`);
  if (r.mode==='split') r.players.forEach(s => console.log(`  ${s.player.name}: ${s.visits.map(v=>v.hub+'('+v.travel.via+' '+f1(v.travel.min)+')').join(' > ')||'-'} -> ${r.meet} ${s.toMeet.via} ${f1(s.toMeet.min)} @${f1(s.arrive)}`));
  console.log('  group:', r.group.visits.map(v=>v.hub+'('+v.travel.via+' '+f1(v.travel.min)+')').join(' > ')||'-', '-> entrance', r.group.final.via, f1(r.group.final.min));
}
for (const d of D.dungeons) {
  if (only && d.id !== only) continue;
  const L = {A: P.levelInfo(d,'A'), H: P.levelInfo(d,'H')};
  console.log(`\n######## ${d.short}  A first ${L.A.firstRun.lvl} full ${L.A.full.lvl} | H first ${L.H.firstRun.lvl} full ${L.H.full.lvl}`);
  show(d,'A',[M],'SW');
  show(d,'A',[O(1),O(2),O(3)],'SW');
  show(d,'A',[M,O(2),W,O(4),O(5)],'SW', true);
  show(d,'H',[M],'ORG');
  show(d,'H',[O(1),O(2)],'ORG');
  show(d,'H',[M,O(2),W,G,Dr],'ORG', true);
}
