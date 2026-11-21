const P = require('../../planner/engine.js'); const D = require('../../planner/data.json');
P.setBoats(D.boats);
const parties = [
  [{name:'M',cls:'mage',eng:'none'}], [{name:'W',cls:'warrior',eng:'none'}],
  [{name:'M',cls:'mage',eng:'none'},{name:'W',cls:'warrior',eng:'none'},{name:'P',cls:'priest',eng:'none'}],
  [{name:'M',cls:'mage',eng:'none'},{name:'W',cls:'warrior',eng:'none'},{name:'L',cls:'warlock',eng:'goblin'},{name:'D',cls:'druid',eng:'gnomish'},{name:'R',cls:'rogue',eng:'none'}]];
for (const d of D.dungeons) for (const f of ['A','H']) parties.forEach((party, i) => { for (const opt of [false, true]) {
  const r = P.plan(D.hubs, d, {faction:f, players:party, start: f==='A'?'SW':'ORG', includeOptional: opt});
  let split = '';
  if (r.mode === 'split') r.players.forEach(p => { split += p.player.name + ':' + p.visits.map(v=>v.hub).join(',') + ';'; });
  console.log(`${d.id} ${f} p${i+1} o${opt} ${r.mode} ${r.total.toFixed(2)} ${r.group.visits.map(v=>v.hub).join(',')} | ${split}`);
}});
