import json
C = [
 ("a","Services-native","Bare Metal looks like the rest of your portal: the My Services hero, category tiles and service-card layout, with per-class art and status-style tags."),
 ("b","Calm glass","Less blue. Neutral glass surfaces with violet only on buttons, more space, the three numbers people compare made biggest. Tags are real notched tags."),
 ("c","Showcase","Led by the art. Each class gets its own render, the card leads with it and the name sits on the art. Closest to the marketing site."),
 ("d","Operator","For people comparing lots of builds: the standard portal header with live stock per location, a left filter rail, rows, and badge tags."),
]
E = [("hero","Portal hero"),("mhero","Marketing hero"),("filter","Filter"),("cards","Catalogue cards"),("owned","Your servers card"),("tags","Tags")]
HTML = r"""<title>Bare Metal Concepts</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600;700&family=Geist+Mono:wght@400;500&display=swap">
<style>
:root{color-scheme:dark;--bg:#000816;--surf:#010f22;--rim:#002049;--rim2:#0a2d63;--tx:#fff;--tx2:#c4d2f0;--tx3:#93aede;--violet:#8c3ae9;--cyan:#14c5e4;--mag:#f21cff;--f:"Geist",ui-sans-serif,system-ui,sans-serif}
@media (prefers-color-scheme:light){:root:not([data-theme="light"]){color-scheme:dark}}
:root[data-theme="dark"]{color-scheme:dark}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--tx);font:15px/1.5 var(--f);padding-inline:16px}
.wrap{max-width:1240px;margin:0 auto;padding:28px 0 90px}
h1{font-size:30px;font-weight:700;letter-spacing:-.03em;margin:0}
.lead{color:var(--tx2);max-width:72ch;margin:.5em 0 0}
.st{font:12px "Geist Mono",monospace;color:var(--tx3);margin-top:10px}
.tabs{position:sticky;top:0;z-index:5;display:flex;flex-wrap:wrap;gap:8px;padding:14px 0;background:linear-gradient(var(--bg) 75%,transparent)}
.tabs a{color:var(--tx2);text-decoration:none;border:1px solid var(--rim2);border-radius:999px;padding:7px 14px;font-size:13px;font-weight:600;background:var(--surf)}
.tabs a:hover{color:#fff;border-color:var(--violet)}
.band{margin-top:48px;padding-top:24px;border-top:1px solid var(--rim)}
.bh{display:flex;flex-wrap:wrap;align-items:baseline;gap:6px 14px}
.k{font:700 11px var(--f);letter-spacing:.2em;text-transform:uppercase;color:var(--mag)}
.bh h2{margin:0;font-size:24px;letter-spacing:-.02em}
.bh p{flex-basis:100%;margin:0;color:var(--tx2);max-width:80ch}
.el{margin-top:22px;border:1px solid var(--rim);border-radius:16px;background:var(--surf);overflow:hidden}
.eb{display:flex;flex-wrap:wrap;align-items:center;gap:10px;padding:10px 12px;border-bottom:1px solid var(--rim)}
.eb .lab{font-weight:700;font-size:14px}
.seg{display:inline-flex;border:1px solid var(--rim2);border-radius:9px;overflow:hidden;margin-left:auto}
.seg button{background:transparent;border:0;color:var(--tx3);font:600 12px var(--f);padding:6px 11px;cursor:pointer}
.seg button[aria-pressed="true"]{background:#0b2350;color:#fff}
.pick{border:1px solid var(--rim2);background:transparent;color:var(--tx2);font:600 13px var(--f);border-radius:9px;padding:6px 14px;cursor:pointer}
.pick[aria-pressed="true"]{background:linear-gradient(100deg,#7b4dff,#2f7eef);border-color:transparent;color:#fff}
.pick:focus-visible,.seg button:focus-visible,textarea:focus-visible{outline:2px solid var(--cyan);outline-offset:2px}
.shot{display:block;padding:12px;background:#000816;text-align:center}
.shot img{max-width:100%;height:auto;border-radius:8px;display:inline-block}
.shot.m img{max-width:390px;width:100%}
textarea{width:100%;margin-top:16px;min-height:46px;resize:vertical;background:var(--surf);color:#fff;border:1px solid var(--rim2);border-radius:12px;padding:10px 12px;font:14px var(--f)}
.sum{margin-top:44px;padding:18px;border:1px solid var(--rim2);border-radius:16px;background:var(--surf)}
.sum h3{margin:0 0 8px;font-size:16px}.sum ul{margin:0;padding-left:18px;color:var(--tx2)}
</style>
<div class="wrap">
<h1>Bare Metal concepts, round 3</h1>
<p class="lead">These are screenshots of the real portal, not mockups. Each one is rendered in the live app's code with your new 1, 3 and 5 unit server renders as a size scale (small builds get the small stack, big builds the tall one), your aurora backgrounds, fonts, buttons and service-card layout. Press <b>Pick</b> on anything you like (you can mix pieces from different concepts), switch any piece to <b>Phone</b> to see it at mobile width, and leave a note under each concept. Prices and specs are example data.</p>
<div class="st" id="st">Connecting…</div>
<nav class="tabs">__TABS__</nav>
__BANDS__
<div class="sum"><h3>Your picks so far</h3><ul id="sumlist"><li>Nothing picked yet.</li></ul></div>
</div>
<script>
const C=__C__, E=__E__;
const picks={}, notes={}, pending=new Set(); let db=null;
const st=t=>document.getElementById('st').textContent=t;
function paint(){
 document.querySelectorAll('.pick').forEach(b=>{const on=!!picks[b.dataset.c+'-'+b.dataset.e];b.setAttribute('aria-pressed',on);b.textContent=on?'Picked':'Pick'});
 C.forEach(([id])=>{const t=document.getElementById('note-'+id);if(t&&document.activeElement!==t)t.value=notes[id]||''});
 const items=[];C.forEach(([id,name])=>E.forEach(([e,l])=>{if(picks[id+'-'+e])items.push(l+' from '+name)}));
 const ul=document.getElementById('sumlist');ul.replaceChildren(...(items.length?items:['Nothing picked yet.']).map(t=>{const li=document.createElement('li');li.textContent=t;return li}));
 if(db)st(items.length?items.length+' picked · saved for Claude':'Picks save automatically')}
async function write(col,id,data){if(!db){st('Sign in to claude.ai to save picks');return}
 const key=col+'/'+id;pending.add(key);
 try{await db.doc(key).set({...data,updatedAt:new Date().toISOString()})}catch(e){st('Could not save ('+(e.code||'error')+'), try again')}finally{pending.delete(key)}}
document.addEventListener('click',e=>{
 const b=e.target.closest('.pick');if(b){const k=b.dataset.c+'-'+b.dataset.e;picks[k]=!picks[k];paint();write('picks3',k,{on:picks[k]});return}
 const v=e.target.closest('.seg button');if(v){const el=v.closest('.el');el.querySelectorAll('.seg button').forEach(x=>x.setAttribute('aria-pressed',x===v));const img=el.querySelector('img');img.src=img.dataset[v.dataset.v];el.querySelector('.shot').classList.toggle('m',v.dataset.v==='m')}
});
document.addEventListener('input',e=>{const t=e.target;if(t.tagName!=='TEXTAREA')return;const id=t.id.slice(5);notes[id]=t.value;clearTimeout(t._t);t._t=setTimeout(()=>write('notes3',id,{text:t.value}),700)});
paint();
(async()=>{try{db=await claude.use('db');if(!db){st('Read-only: sign in to claude.ai to save picks');return}
 db.collection('picks3').onSnapshot(s=>{for(const d of s.docs){if(pending.has('picks3/'+d.id))continue;const v=d.data();if(v)picks[d.id]=!!v.on}paint()},()=>st('Live sync paused'));
 db.collection('notes3').onSnapshot(s=>{for(const d of s.docs){if(pending.has('notes3/'+d.id))continue;const v=d.data();if(v)notes[d.id]=String(v.text||'')}paint()},()=>{});
 paint()}catch(e){st('Read-only right now')}})();
</script>
"""
tabs = "".join(f'<a href="#{c}">{c.upper()} · {n}</a>' for c,n,_ in C)
bands = ""
for c,n,d in C:
    els = ""
    for e,l in E:
        els += f'''<div class="el"><div class="eb"><span class="lab">{l}</span><div class="seg" role="group" aria-label="View"><button type="button" data-v="d" aria-pressed="true">Desktop</button><button type="button" data-v="m" aria-pressed="false">Phone</button></div><button type="button" class="pick" data-c="{c}" data-e="{e}" aria-pressed="false">Pick</button></div><div class="shot"><img loading="lazy" alt="{n}: {l}" src="img/{c}-{e}-d.jpg" data-d="img/{c}-{e}-d.jpg" data-m="img/{c}-{e}-m.jpg"></div></div>'''
    bands += f'<section class="band" id="{c}"><div class="bh"><span class="k">Concept {c.upper()}</span><h2>{n}</h2><p>{d}</p></div>{els}<textarea id="note-{c}" placeholder="Notes on {n} (optional)"></textarea></section>'
out = HTML.replace("__TABS__",tabs).replace("__BANDS__",bands).replace("__C__",json.dumps([[c,n] for c,n,_ in C])).replace("__E__",json.dumps(E))
open("/root/agent-notes/bm-concepts/index.html","w").write(out)
print("ok", len(out))
