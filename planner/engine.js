/* Forever dungeon quest planner engine. Pure functions; browser (window.Planner) or Node (module.exports). */
(function (root) {
  var FLY_SPEED = 6;      // map units per minute on a flight path
  var RIDE_SPEED = 2.6;   // map units per minute on a ground mount
  var FOOT = 1.6;         // a mount is about 60% faster than running
  var FP_OVERHEAD = 1;    // flight master, landing
  var CAST = 0.5;         // teleport / portal cast
  var SUMMON = 1.5;       // one Ritual of Summoning
  var ACT = 0.5;          // talking to an NPC
  var CITIES = { A: ["SW", "IF", "DARN"], H: ["ORG", "UC", "TB"] };
  // Levels at which travel abilities unlock (Classic values unless data overrides them).
  var RULES = {
    teleport: { SW: 20, IF: 20, ORG: 20, UC: 20, DARN: 30, TB: 30 },
    portal: { SW: 40, IF: 40, ORG: 40, UC: 40, DARN: 50, TB: 50 },
    mount: 40, summon: 20, moonglade: 10
  };
  var BOATS = [];          // [{a, b, f: "A"|"H"|"both", min}]
  var CTX = { level: 60, mounted: true };
  var memo = {}, nets = {};

  function setRules(r) { if (r) Object.keys(r).forEach(function (k) { RULES[k] = r[k]; }); memo = {}; nets = {}; }
  function setBoats(b) { BOATS = b || []; memo = {}; nets = {}; }
  function setLevel(lvl) {
    CTX.level = lvl || 60; CTX.mounted = CTX.level >= RULES.mount;
  }
  function can(kind, city) { var t = RULES[kind]; return CTX.level >= (typeof t === "object" ? (t[city] || 99) : t); }

  function dist(a, b) { var dx = a.x - b.x, dy = a.y - b.y; return Math.sqrt(dx * dx + dy * dy); }
  function rideOf(h, f) { var r = h.ride && h.ride[f]; r = r == null ? 4 : r; return CTX.mounted ? r : r * FOOT; }
  function flySame(H, a, b, f) { return FP_OVERHEAD + rideOf(H[a], f) + dist(H[a], H[b]) / FLY_SPEED + rideOf(H[b], f); }
  function rideSame(H, a, b) { return 0.3 + dist(H[a], H[b]) / (CTX.mounted ? RIDE_SPEED : RIDE_SPEED / FOOT); }
  function sameCont(H, a, b) {
    if (a === b) return { min: 0, via: "Here" };
    var fly = flySame(H, a, b, f0), ride = rideSame(H, a, b);
    return ride <= fly ? { min: ride, via: CTX.mounted ? "Ride" : "Run" } : { min: fly, via: "Fly" };
  }
  var f0 = "A";

  // Shortest paths between boat/zeppelin docks for a faction (Floyd-Warshall on a handful of nodes).
  function network(H, f) {
    var key = f + (CTX.mounted ? "m" : "w");
    if (nets[key]) return nets[key];
    var nodes = [], edges = [];
    BOATS.forEach(function (b) {
      if (!(b.f === "both" || b.f === f) || !H[b.a] || !H[b.b]) return;
      [b.a, b.b].forEach(function (n) { if (nodes.indexOf(n) < 0) nodes.push(n); });
      edges.push(b);
    });
    var D = {};
    nodes.forEach(function (i) { D[i] = {}; nodes.forEach(function (j) {
      D[i][j] = i === j ? 0 : (H[i].cont === H[j].cont ? (f0 = f, sameCont(H, i, j).min) : Infinity);
    }); });
    edges.forEach(function (e) { D[e.a][e.b] = Math.min(D[e.a][e.b], e.min); if (!e.oneWay) D[e.b][e.a] = Math.min(D[e.b][e.a], e.min); });
    nodes.forEach(function (k) { nodes.forEach(function (i) { nodes.forEach(function (j) {
      if (D[i][k] + D[k][j] < D[i][j]) D[i][j] = D[i][k] + D[k][j];
    }); }); });
    nets[key] = { nodes: nodes, D: D };
    return nets[key];
  }

  function baseTravel(H, a, b, f) {
    var key = a + ">" + b + ">" + f + (CTX.mounted ? "m" : "w");
    if (memo[key]) return memo[key];
    var r;
    f0 = f;
    if (a === b) r = { min: 0, via: "Here" };
    else if (H[a].cont === H[b].cont) r = sameCont(H, a, b);
    else {
      var net = network(H, f), best = null;
      f0 = f;
      net.nodes.forEach(function (pa) {
        if (H[pa].cont !== H[a].cont) return;
        net.nodes.forEach(function (pb) {
          if (H[pb].cont !== H[b].cont || net.D[pa][pb] === Infinity) return;
          var t = sameCont(H, a, pa).min + net.D[pa][pb] + sameCont(H, pb, b).min;
          if (best == null || t < best) best = t;
        });
      });
      r = { min: best == null ? 40 : best, via: f === "H" ? "Travel + zeppelin/boat" : "Travel + boat" };
    }
    memo[key] = r;
    return r;
  }

  // Cheapest way for someone with `abil` to get from `from` to `to`. extra = [{via,min}] (hearth etc.)
  function travel(H, from, to, f, abil, extra) {
    if (from === to) return { min: 0, via: "Here" };
    var opts = [baseTravel(H, from, to, f)];
    CITIES[f].forEach(function (c) {
      if (!H[c]) return;
      var leg = c === to ? 0 : baseTravel(H, c, to, f).min;
      if (abil.portalAll && abil.portalFromMage && can("portal", c)) { opts.push({ min: CAST + leg, via: "Mage portal: " + H[c].name }); return; }
      if (abil.mage && can("teleport", c)) opts.push({ min: CAST + leg, via: "Teleport: " + H[c].name });
      else if (abil.portalFromMage && can("portal", c)) opts.push({ min: CAST + leg, via: "Mage portal: " + H[c].name });
    });
    if (abil.gnomish && H.GADGETZAN) opts.push({ min: 1 + (to === "GADGETZAN" ? 0 : baseTravel(H, "GADGETZAN", to, f).min), via: "Ultrasafe Transporter: Gadgetzan" });
    if (abil.goblin && H.EVERLOOK) opts.push({ min: 1 + (to === "EVERLOOK" ? 0 : baseTravel(H, "EVERLOOK", to, f).min), via: "Dimensional Ripper: Everlook" });
    if (abil.druid && H.MOONGLADE && can("moonglade")) opts.push({ min: CAST + (to === "MOONGLADE" ? 0 : baseTravel(H, "MOONGLADE", to, f).min), via: "Teleport: Moonglade" });
    (extra || []).forEach(function (o) { opts.push(o); });
    opts.sort(function (x, y) { return x.min - y.min; });
    return opts[0];
  }

  // ---------- quest helpers ----------
  function isLive(q) { return !q.status || q.status === "live"; }
  function forFaction(q, f) { return q.f === f || q.f === "B"; }
  function isOptional(q) { return q.cat === "optional" || q.cat === "class"; }
  function pathOf(q, f) { if (!q.path) return null; return Array.isArray(q.path) ? q.path : (q.path[f] || null); }
  function classOk(q, classes) {
    if (q.cat !== "class") return true;
    if (!classes || !q.cls) return false;
    if (q.cls === "All") return true;
    return q.cls.toLowerCase().split("/").some(function (c) { return classes.indexOf(c.trim()) >= 0; });
  }
  function routable(q, f, incl, classes) {
    return forFaction(q, f) && isLive(q) && !!pathOf(q, f) && (incl || (!isOptional(q) && !q.optRoute)) && classOk(q, classes);
  }

  function levelInfo(d, f) {
    function mx(filter) {
      var best = null, who = null;
      d.quests.forEach(function (q) {
        if (!forFaction(q, f) || !isLive(q) || q.req == null || !filter(q)) return;
        if (best == null || q.req > best) { best = q.req; who = q.n; }
      });
      return { lvl: best, q: who };
    }
    return {
      firstRun: mx(function (q) { return !isOptional(q) && q.cat !== "followup" && !q.optRoute; }),
      full: mx(function (q) { return !isOptional(q); }),
      cls: mx(function (q) { return q.cat === "class"; }),
      optional: mx(function (q) { return q.cat === "optional"; })
    };
  }

  // The level a party would do this dungeon at: when everything can be picked up, or the dungeon's minimum.
  function plannedLevel(d, f) {
    var L = levelInfo(d, f), min = parseInt(String(d.range).split("-")[0], 10) || 1;
    return Math.max(L.firstRun.lvl || 0, min);
  }
  function abilitiesAt(lvl) {
    setLevel(lvl);
    return { mounted: CTX.mounted, teleport: can("teleport", "SW"), teleportFar: can("teleport", "DARN"),
      portal: can("portal", "SW"), portalFar: can("portal", "DARN"), summon: can("summon"), moonglade: can("moonglade") };
  }

  // Build task list: one task per routable quest; `after` turns into indexes.
  function buildTasks(d, f, incl, classes) {
    var tasks = [];
    var byName = {};
    d.quests.forEach(function (q) {
      if (!routable(q, f, incl, classes)) return;
      var key = q.n + "|" + q.f;
      var t = { q: q, steps: pathOf(q, f), after: [] };
      byName[q.n] = byName[q.n] || [];
      byName[q.n].push(tasks.length);
      tasks.push(t);
    });
    tasks.forEach(function (t) {
      (t.q.after || []).forEach(function (n) { (byName[n] || []).forEach(function (i) { t.after.push(i); }); });
    });
    return tasks;
  }

  // Greedy tour through tasks, honoring step order and `after`, trying each first hub.
  function tour(H, f, start, tasks, abilFn, endHub) {
    if (!tasks.length) {
      var fin0 = endHub ? travel(H, start, endHub, f, abilFn(0), null) : { min: 0, via: "Here" };
      return { visits: [], time: fin0.min, final: fin0, end: endHub || start };
    }
    function readyIdx(ptr) {
      var out = [];
      tasks.forEach(function (t, i) {
        if (ptr[i] >= t.steps.length) return;
        if (t.after.every(function (a) { return ptr[a] >= tasks[a].steps.length; })) out.push(i);
      });
      return out;
    }
    function run(firstHub) {
      var ptr = tasks.map(function () { return 0; });
      var cur = start, t = 0, visits = [], n = 0, guard = 0, hearthUsed = false;
      while (guard++ < 200) {
        var ready = readyIdx(ptr);
        if (!ready.length) break;
        var abil = abilFn(n);
        var hub = null, best = null, bestTr = null;
        ready.forEach(function (i) {
          var s = tasks[i].steps[ptr[i]];
          var tr = travel(H, cur, s.hub, f, abil, hearthUsed ? null : s.opts);
          var score = tr.min + i * 1e-4;
          if (n === 0 && firstHub) score = s.hub === firstHub ? -1 : score + 1e6;
          if (best == null || score < best) { best = score; hub = s.hub; bestTr = tr; }
        });
        if (/^Hearth/.test(bestTr.via)) hearthUsed = true;
        var visit = { hub: hub, travel: bestTr, acts: [], work: 0 };
        var moved = true;
        while (moved) {
          moved = false;
          readyIdx(ptr).forEach(function (i) {
            var s = tasks[i].steps[ptr[i]];
            if (s.hub !== hub) return;
            visit.acts.push({ q: tasks[i].q.n, a: s.a, t: s.t || "", share: tasks[i].q.share, cls: tasks[i].q.cat === "class" ? tasks[i].q.cls : null });
            visit.work += ACT + (s.work || 0);
            ptr[i]++; moved = true;
          });
        }
        t += bestTr.min + visit.work; cur = hub; visits.push(visit); n++;
      }
      var fin = endHub ? travel(H, cur, endHub, f, abilFn(n), null) : { min: 0, via: "Here" };
      return { visits: visits, time: t + fin.min, final: fin, end: endHub || cur };
    }
    var firsts = {};
    readyIdx(tasks.map(function () { return 0; })).forEach(function (i) { firsts[tasks[i].steps[0].hub] = true; });
    var best = null;
    Object.keys(firsts).forEach(function (h) {
      var r = run(h);
      if (!best || r.time < best.time) best = r;
    });
    return best;
  }

  // players: [{name, cls: 'mage'|'warlock'|'druid'|'other', eng: 'none'|'gnomish'|'goblin'}]
  function plan(H, d, opt) {
    var f = opt.faction, players = opt.players, start = opt.start, N = players.length;
    setLevel(opt.level || plannedLevel(d, f));
    var classes = players.map(function (p) { return p.cls; });
    var tasks = buildTasks(d, f, opt.includeOptional, classes);
    var anyMage = players.some(function (p) { return p.cls === "mage"; });
    var warlockIdx = -1;
    players.forEach(function (p, i) { if (warlockIdx < 0 && p.cls === "warlock") warlockIdx = i; });
    // A mage can only bring the group along once portals unlock; otherwise the group travels normally.
    var groupAbil = { portalFromMage: anyMage, portalAll: true };
    if (N === 1) {
      var p0 = players[0];
      groupAbil = { mage: p0.cls === "mage", druid: p0.cls === "druid", gnomish: p0.eng === "gnomish", goblin: p0.eng === "goblin" };
    }
    function abilOf(p, first) {
      return { mage: p.cls === "mage", druid: p.cls === "druid", gnomish: p.eng === "gnomish", goblin: p.eng === "goblin", portalFromMage: first && anyMage && p.cls !== "mage" };
    }
    var dependedOn = {};
    tasks.forEach(function (t) { t.after.forEach(function (a) { dependedOn[a] = true; }); });

    // Everyone together.
    var all = tour(H, f, start, tasks, function () { return groupAbil; }, d.entrance);
    var together = { mode: "together", group: all, total: all.time, meet: all.visits.length ? all.visits[0].hub : d.entrance };
    if (N === 1) return finish(together, null);

    // Pickups one person can grab and share: single "take" of a shareable quest with no prerequisite.
    var cand = [], rest = [];
    tasks.forEach(function (t, i) {
      var single = t.steps.length === 1 && t.steps[0].a === "take" && !t.after.length && !dependedOn[i];
      var ok = single && (t.q.cat === "class" || (t.q.share === true && !t.q.pre));
      (ok ? cand : rest).push(t);
    });
    function reindex(list) {
      // `after` only points inside `rest`; candidates have none and nobody depends on them.
      var map = {}; list.forEach(function (t, i) { map[tasks.indexOf(t)] = i; });
      return list.map(function (t) { return { q: t.q, steps: t.steps, after: t.after.map(function (a) { return map[a]; }).filter(function (x) { return x != null; }) }; });
    }
    var restT = reindex(rest);
    var grp = tour(H, f, start, restT, function () { return groupAbil; }, d.entrance);
    var groupHubs = {}; grp.visits.forEach(function (v) { groupHubs[v.hub] = true; });
    if (!rest.length) groupHubs = {};
    var units = {};
    var tagAlong = [];
    cand.forEach(function (t) {
      if (groupHubs[t.steps[0].hub]) { tagAlong.push(t); return; }
      var key = t.steps[0].hub + (t.q.cat === "class" ? "|" + t.q.cls : "");
      (units[key] = units[key] || []).push(t);
    });
    if (tagAlong.length) { restT = reindex(rest.concat(tagAlong)); grp = tour(H, f, start, restT, function () { return groupAbil; }, d.entrance); }
    var unitList = Object.keys(units).map(function (k) {
      var ts = units[k], allowed = null;
      ts.forEach(function (t) {
        if (t.q.cat !== "class") return;
        var ok = players.map(function (p, i) { return classOk(t.q, [p.cls]) ? i : -1; }).filter(function (i) { return i >= 0; });
        allowed = allowed ? allowed.filter(function (i) { return ok.indexOf(i) >= 0; }) : ok;
      });
      return { hub: ts[0].steps[0].hub, tasks: ts, allowed: allowed };
    });
    if (!unitList.length) return finish(together, null);

    var meet = grp.visits.length ? grp.visits[0].hub : d.entrance;
    // Group phase starts at the meeting point (everyone is already there).
    var grpFromMeet = tour(H, f, meet, restT, function () { return groupAbil; }, d.entrance);

    function evalAssign(assign) {
      for (var u = 0; u < assign.length; u++) if (unitList[u].allowed && unitList[u].allowed.indexOf(assign[u]) < 0) return { per: [], time: Infinity };
      var per = players.map(function () { return []; });
      assign.forEach(function (pi, i) { per[pi] = per[pi].concat(unitList[i].tasks.map(function (t) { return { q: t.q, steps: t.steps, after: [] }; })); });
      var res = per.map(function (list, pi) {
        var p = players[pi];
        var tr = tour(H, f, start, list, function (n) { return abilOf(p, n === 0); }, meet);
        return { player: p, pi: pi, visits: tr.visits, toMeet: tr.final, arrive: tr.time };
      });
      if (warlockIdx >= 0 && N >= 3 && can("summon")) {
        var tw = res[warlockIdx].arrive;
        var others = res.filter(function (r) { return r.pi !== warlockIdx; });
        var sorted = others.map(function (r) { return r.arrive; }).sort(function (a, b) { return a - b; });
        var ready = Math.max(tw, sorted[1]);
        var k = 0;
        others.slice().sort(function (a, b) { return a.arrive - b.arrive; }).forEach(function (r) {
          var doneAt = r.arrive - r.toMeet.min;   // finished own pickups
          var at = Math.max(doneAt, ready + SUMMON * k) + SUMMON;
          if (at < r.arrive - 0.01) {
            k++;
            r.toMeet = { min: at - doneAt, via: "Warlock summon" };
            r.arrive = at; r.summoned = true;
          }
        });
      }
      var make = 0; res.forEach(function (r) { if (r.arrive > make) make = r.arrive; });
      return { per: res, time: make };
    }
    var C = unitList.length, best = null;
    var total = Math.pow(N, C);
    if (total <= 4000) {
      var a = new Array(C).fill(0);
      for (var n = 0; n < total; n++) {
        var x = n; for (var i = 0; i < C; i++) { a[i] = x % N; x = Math.floor(x / N); }
        var r = evalAssign(a);
        if (!best || r.time < best.time - 1e-9) { best = r; best.assign = a.slice(); }
      }
    } else {
      var ga = unitList.map(function (u) { return u.allowed ? u.allowed[0] : 0; });
      for (var j = 0; j < C; j++) {
        var bj = null;
        for (var pi = 0; pi < N; pi++) { if (unitList[j].allowed && unitList[j].allowed.indexOf(pi) < 0) continue; ga[j] = pi; var rr = evalAssign(ga.slice(0, C)); if (!bj || rr.time < bj.time) bj = { time: rr.time, pi: pi }; }
        ga[j] = bj.pi;
      }
      best = evalAssign(ga); best.assign = ga;
    }
    var split = { mode: "split", players: best.per, splitTime: best.time, meet: meet, group: grpFromMeet, total: best.time + grpFromMeet.time };
    split.shares = [];
    best.per.forEach(function (r) { r.visits.forEach(function (v) { v.acts.forEach(function (ac) { if (!ac.cls) split.shares.push({ q: ac.q, from: r.player.name }); }); }); });
    if (split.total >= together.total - 0.5) return finish(together, split.total);
    return finish(split, together.total);

    function finish(res, other) { res.compare = other; res.tasks = tasks.length; return res; }
  }

  var api = { setRules: setRules, setBoats: setBoats, plannedLevel: plannedLevel, abilitiesAt: abilitiesAt, RULES: RULES, plan: plan, levelInfo: levelInfo, travel: travel, baseTravel: baseTravel, isLive: isLive, forFaction: forFaction, isOptional: isOptional, pathOf: pathOf, routable: routable, CITIES: CITIES };
  if (typeof module !== "undefined" && module.exports) module.exports = api; else root.Planner = api;
})(this);
