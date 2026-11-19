const fs=require('fs');
const h=fs.readFileSync(process.argv[2],'utf8');
const scripts=[...h.matchAll(/<script>([\s\S]*?)<\/script>/g)].map(m=>m[1]);
function el(id){return {id,innerHTML:'',value:'',checked:false,disabled:false,dataset:{},style:{},
  addEventListener(){},setAttribute(){},appendChild(){},classList:{toggle(){}},
  querySelector(){return el('q')},querySelectorAll(){return []}};}
const els={};
global.window=global; global.localStorage={getItem(){return null},setItem(){}};
global.location={hash:''}; global.addEventListener=()=>{};
global.document={body:el('body'),getElementById(id){return els[id]||(els[id]=el(id))},createElement(){return el('x')}};
new Function(scripts[0]).call(global);
// expose render via re-running main script per state
const main=scripts[1];
const DATA_IDS=[...main.matchAll(/"id":"([a-z0-9_]+)","name"/g)].map(m=>m[1]);
console.log('dungeons:',DATA_IDS.length);
let errs=0;
for (const fac of ['A','H']) for (const opt of [false,true]) {
  for (const d of DATA_IDS) {
    location.hash='#'+d;
    global.localStorage={getItem(){return JSON.stringify({faction:fac,start:fac==='A'?'SW':'ORG',opt,players:[{name:'Ana',cls:'mage',eng:'none'},{name:'Bo',cls:'warlock',eng:'goblin'},{name:'Cy',cls:'paladin',eng:'none'},{name:'Di',cls:'shaman',eng:'gnomish'}]})},setItem(){}};
    try{ new Function(main).call(global); const v=els.view.innerHTML; if(!v.includes('<h2>')) throw new Error('no h2'); if(/undefined|NaN/.test(v.replace(/data-[a-z]+="[^"]*"/g,''))) {console.log('suspicious text in',d,fac,opt, (v.match(/.{40}(undefined|NaN).{40}/)||[''])[0]); errs++;} }
    catch(e){console.log('ERR',d,fac,opt,e.message);errs++;}
  }
}
console.log('done, issues:',errs);
console.log(els.view.innerHTML.replace(/<[^>]+>/g,' ').replace(/\s+/g,' ').slice(0,1500));
