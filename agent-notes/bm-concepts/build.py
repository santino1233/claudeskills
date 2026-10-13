#!/usr/bin/env python3
# Builds index.html: 5 visual concepts for Bare Metal (hero, filter, marketing card, portal card).
logos = open("/root/agent-notes/bm-concepts/logos.css").read()

HTML = r"""<title>Bare Metal Concepts</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Geist:wght@300;400;500;600;700&family=Geist+Mono:wght@400;500&display=swap">
<style>
/* Layout: a review board. Five concept bands stacked; each shows hero, filter, marketing card, portal card with a pick toggle. */
:root{
  color-scheme:dark;
  --bg:#060913; --bg2:#080D1C; --ink:#EEF2FF; --ink2:#AEB9D6; --ink3:#7D8AAE;
  --line:rgba(255,255,255,.085); --line2:rgba(255,255,255,.14);
  --blue:#1463FF; --bluehi:#3B7DFF; --cyan:#3EDCF2; --violet:#9B6BFF; --magenta:#E04BD6; --green:#3FD89A; --amber:#F2B64B;
  /* portal tokens */
  --p-bg:#000816; --p-surf:#010f22; --p-well:#000c1e; --p-rim:#002049; --p-tx:#ffffff; --p-tx2:#cbdcff; --p-tx3:#93aede; --p-violet:#8c3ae9; --p-blue:#2f7eef;
  --f:"Geist",ui-sans-serif,system-ui,-apple-system,"Segoe UI",sans-serif;
  --m:"Geist Mono",ui-monospace,SFMono-Regular,Menlo,monospace;
}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--ink);font:15px/1.5 var(--f);padding-inline:16px}
.wrap{max-width:1240px;margin:0 auto;padding-block:28px 80px}
h1,h2,h3{text-wrap:balance;margin:0}
.intro h1{font-size:28px;font-weight:600;letter-spacing:-.02em}
.intro p{color:var(--ink2);max-width:68ch;margin:.4em 0 0}
.status{font:12px var(--m);color:var(--ink3);margin-top:10px}
.nav{display:flex;flex-wrap:wrap;gap:8px;margin:20px 0 6px}
.nav a{color:var(--ink2);text-decoration:none;border:1px solid var(--line2);border-radius:999px;padding:6px 12px;font-size:13px}
.nav a:hover{color:var(--ink);border-color:var(--ink3)}
.band{margin-top:56px;padding-top:28px;border-top:1px solid var(--line)}
.bandhead{display:flex;flex-wrap:wrap;align-items:baseline;gap:6px 16px;margin-bottom:18px}
.bandhead h2{font-size:22px;font-weight:600;letter-spacing:-.01em}
.bandhead .k{font:12px var(--m);color:var(--cyan);text-transform:uppercase;letter-spacing:.12em}
.bandhead p{color:var(--ink2);margin:0;flex-basis:100%;max-width:80ch}
.el{margin-top:18px}
.elbar{display:flex;align-items:center;justify-content:space-between;gap:10px;margin-bottom:8px}
.elbar .lab{font:11px var(--m);color:var(--ink3);text-transform:uppercase;letter-spacing:.14em}
.pick{display:inline-flex;align-items:center;gap:8px;font-size:13px;color:var(--ink2);cursor:pointer;border:1px solid var(--line2);border-radius:8px;padding:5px 10px;background:transparent;font-family:var(--f)}
.pick[aria-pressed="true"]{color:#06101f;background:var(--cyan);border-color:var(--cyan);font-weight:600}
.pick:focus-visible,.note:focus-visible{outline:2px solid var(--cyan);outline-offset:2px}
.note{width:100%;margin-top:14px;min-height:42px;resize:vertical;background:var(--bg2);color:var(--ink);border:1px solid var(--line2);border-radius:10px;padding:10px 12px;font:14px var(--f)}
.row{display:grid;gap:16px}
.r2{grid-template-columns:repeat(auto-fit,minmax(300px,1fr))}
.lg{display:inline-block;background:center/contain no-repeat;flex:none}
.flag{display:inline-block;width:20px;height:14px;border-radius:2px;overflow:hidden;vertical-align:-2px;flex:none;box-shadow:0 0 0 1px rgba(255,255,255,.12)}
.mono{font-family:var(--m);font-variant-numeric:tabular-nums}
input[type=range]{accent-color:var(--blue);width:100%}
.btn{display:inline-flex;align-items:center;gap:6px;border:0;border-radius:10px;padding:9px 14px;font:600 14px var(--f);cursor:pointer;color:#fff;background:var(--blue)}
.btn.ghost{background:transparent;border:1px solid var(--line2);color:var(--ink)}
@media (prefers-reduced-motion:reduce){*{animation:none!important;transition:none!important}}
LOGOS

/* ---------- C1 SPEC SHEET ---------- */
.c1 .hero{display:grid;grid-template-columns:1.1fr 1fr;gap:24px;align-items:center;background:var(--bg2);border:1px solid var(--line);border-radius:16px;padding:32px;overflow:hidden}
.c1 .hero h3{font-size:34px;line-height:1.1;font-weight:600;letter-spacing:-.025em}
.c1 .hero p{color:var(--ink2);margin:.6em 0 1.2em}
.c1 .brands{display:flex;gap:18px;align-items:center;margin-top:18px;opacity:.9}
.c1 .brands .lg{height:22px;width:70px}
.c1 svg.board{width:100%;height:auto}
.c1 .board .tr{fill:none;stroke:rgba(110,160,255,.28);stroke-width:1.2}
.c1 .board .pulse{fill:none;stroke:var(--cyan);stroke-width:1.6;stroke-dasharray:14 400;animation:c1p 4.8s linear infinite}
.c1 .board .pulse.b{stroke:var(--violet);animation-duration:6.2s;animation-delay:-2s}
@keyframes c1p{to{stroke-dashoffset:-414}}
.c1 .board text{font:9px var(--m);fill:var(--ink3);letter-spacing:.08em}
.c1 .filter{display:flex;flex-wrap:wrap;gap:12px 22px;align-items:center;border:1px solid var(--line);border-radius:12px;padding:14px 16px;background:var(--bg2)}
.c1 .fg{display:flex;align-items:center;gap:8px;font-size:13px;color:var(--ink2)}
.c1 .chip{display:inline-flex;align-items:center;gap:6px;border:1px solid var(--line2);border-radius:8px;padding:5px 9px;font-size:13px;color:var(--ink2);background:transparent;cursor:pointer}
.c1 .chip.on{border-color:var(--bluehi);color:var(--ink);background:rgba(20,99,255,.12)}
.c1 .chip .lg{height:18px;width:48px}
.c1 .rg{display:grid;gap:2px;min-width:170px}
.c1 .rg span{font:11px var(--m);color:var(--ink3)}
.c1 .mc{border:1px solid var(--line);border-radius:14px;background:var(--bg2);padding:22px}
.c1 .mc .top{display:flex;justify-content:space-between;align-items:center}
.c1 .mc .nx{font-size:20px;font-weight:600;letter-spacing:-.01em}
.c1 .mc .cpu{color:var(--ink2);font-size:13px;margin-top:2px}
.c1 .mc .lg{height:18px;width:60px}
.c1 .mc dl{display:grid;grid-template-columns:auto 1fr;gap:7px 18px;margin:18px 0;font-size:14px}
.c1 .mc dt{color:var(--ink3)} .c1 .mc dd{margin:0;text-align:right}
.c1 .mc .foot{display:flex;justify-content:space-between;align-items:end;border-top:1px solid var(--line);padding-top:14px}
.c1 .price{font-size:24px;font-weight:600} .c1 .price small{font-size:13px;color:var(--ink3);font-weight:400}
.c1 .tag{font:11px var(--m);text-transform:uppercase;letter-spacing:.1em;color:var(--cyan)}
.c1 .pc{background:var(--p-surf);border:1px solid var(--p-rim);border-radius:12px;padding:14px 16px;display:grid;grid-template-columns:1fr auto;gap:6px 14px;align-items:center}
.c1 .pc .nx{font-weight:600} .c1 .pc .sub{color:var(--p-tx3);font-size:13px;grid-column:1}
.c1 .pc .p{font-weight:600;text-align:right} .c1 .pc .mini{display:flex;gap:14px;font-size:12px;color:var(--p-tx2);grid-column:1/-1;border-top:1px solid var(--p-rim);padding-top:8px;margin-top:4px}

/* ---------- C2 RACK UNIT ---------- */
.c2 .hero{display:grid;grid-template-columns:1fr 1fr;gap:28px;align-items:center;padding:30px;border-radius:16px;background:linear-gradient(180deg,#0a1124,#060913);border:1px solid var(--line)}
.c2 .hero h3{font-size:32px;line-height:1.1;font-weight:600;letter-spacing:-.02em}
.c2 .hero p{color:var(--ink2);margin:.6em 0 1.2em}
.c2 .rack{display:grid;gap:6px;padding:14px;border-radius:10px;background:#03060d;border:1px solid var(--line2)}
.c2 .u{height:34px;border-radius:4px;background:linear-gradient(180deg,#141b2e,#0d1322);border:1px solid #1d2742;display:flex;align-items:center;gap:10px;padding:0 10px;font:10px var(--m);color:var(--ink3)}
.c2 .u .vent{flex:1;height:12px;background:repeating-linear-gradient(90deg,#1f2943 0 2px,transparent 2px 6px);border-radius:2px}
.c2 .led{width:6px;height:6px;border-radius:50%;background:#2b3552}
.c2 .led.g{background:var(--green);box-shadow:0 0 6px var(--green);animation:c2b 1.7s steps(2) infinite}
.c2 .led.b{background:var(--cyan);box-shadow:0 0 6px var(--cyan);animation:c2b .9s steps(2) infinite}
.c2 .u:nth-child(3) .led.b{animation-duration:1.3s} .c2 .u:nth-child(5) .led.g{animation-duration:2.3s}
@keyframes c2b{50%{opacity:.25}}
.c2 .u.you{border-color:var(--bluehi);background:linear-gradient(180deg,#14234a,#0d1730);color:var(--ink)}
.c2 .layout{display:grid;grid-template-columns:240px 1fr;gap:16px}
.c2 .rail{border:1px solid var(--line);border-radius:12px;padding:14px;background:var(--bg2);display:grid;gap:16px;align-content:start}
.c2 .rail h4{margin:0 0 6px;font:11px var(--m);text-transform:uppercase;letter-spacing:.12em;color:var(--ink3)}
.c2 .opt{display:flex;align-items:center;gap:8px;font-size:14px;color:var(--ink2);padding:4px 0}
.c2 .opt input{accent-color:var(--blue)}
.c2 .opt .lg{height:20px;width:64px}
.c2 .mc{display:grid;grid-template-columns:auto 1fr auto;gap:14px;align-items:center;border:1px solid var(--line);border-radius:10px;background:linear-gradient(180deg,#0e1529,#0a1020);padding:14px 16px;position:relative}
.c2 .mc::before{content:"";position:absolute;left:0;top:10px;bottom:10px;width:3px;border-radius:0 3px 3px 0;background:var(--cls)}
.c2 .mc .lg{height:22px;width:62px}
.c2 .mc .nx{font-weight:600} .c2 .mc .s{color:var(--ink2);font-size:13px}
.c2 .mc .specs{display:flex;flex-wrap:wrap;gap:6px 14px;font:12px var(--m);color:var(--ink3);margin-top:4px}
.c2 .mc .r{text-align:right} .c2 .mc .price{font-size:20px;font-weight:600}
.c2 .stack{display:grid;gap:10px}
.c2 .pc{display:flex;align-items:center;gap:12px;background:var(--p-surf);border:1px solid var(--p-rim);border-radius:10px;padding:12px 14px}
.c2 .pc .leds{display:flex;gap:4px} .c2 .pc .nx{font-weight:600} .c2 .pc .s{font-size:12px;color:var(--p-tx3)}
.c2 .pc .p{margin-left:auto;font-weight:600}

/* ---------- C3 AURORA GLASS ---------- */
.c3 .hero{position:relative;overflow:hidden;border-radius:18px;padding:40px 32px 90px;background:#050816;border:1px solid var(--line)}
.c3 .au{position:absolute;inset:-30%;background:radial-gradient(40% 30% at 30% 40%,rgba(62,220,242,.22),transparent 70%),radial-gradient(35% 28% at 65% 35%,rgba(155,107,255,.22),transparent 70%),radial-gradient(30% 25% at 50% 70%,rgba(20,99,255,.2),transparent 70%);filter:blur(30px);animation:c3d 18s ease-in-out infinite alternate}
@keyframes c3d{to{transform:translate3d(4%,-3%,0) rotate(6deg)}}
.c3 .hin{position:relative;display:grid;grid-template-columns:1.2fr 1fr;gap:20px;align-items:center}
.c3 .hero h3{font-size:36px;line-height:1.08;font-weight:600;letter-spacing:-.03em}
.c3 .hero p{color:var(--ink2);margin:.6em 0 1em;max-width:46ch}
.c3 .chipw{display:grid;place-items:center}
.c3 .cpu{width:200px;height:200px;border-radius:22px;position:relative;background:linear-gradient(145deg,#cfd6e6,#7f899f 45%,#c3cbdc 70%,#6c768c);box-shadow:0 30px 60px rgba(0,0,0,.5),inset 0 1px 0 rgba(255,255,255,.6);display:grid;place-items:center;overflow:hidden}
.c3 .cpu::after{content:"";position:absolute;inset:-40%;background:linear-gradient(105deg,transparent 40%,rgba(255,255,255,.55) 50%,transparent 60%);transform:translateX(-60%);animation:c3s 6s ease-in-out infinite}
@keyframes c3s{0%,55%{transform:translateX(-60%)}85%,100%{transform:translateX(60%)}}
.c3 .cpu b{font:600 26px var(--f);color:#3b4458;letter-spacing:.2em}
.c3 .cpu small{position:absolute;bottom:18px;font:10px var(--m);color:#4a5469;letter-spacing:.14em}
.c3 .pins{position:absolute;inset:-8px;border-radius:26px;border:2px dashed rgba(242,182,75,.35);z-index:-1}
.c3 .logos{display:flex;gap:10px;margin-top:14px}
.c3 .logos>span{display:grid;place-items:center;height:44px;width:96px;border-radius:12px;background:rgba(255,255,255,.04);border:1px solid var(--line2)}
.c3 .logos .lg{height:20px;width:66px}
.c3 .filter{position:relative;margin:-64px 16px 0;border-radius:16px;padding:18px;background:rgba(10,16,34,.72);backdrop-filter:blur(14px);border:1px solid var(--line2);display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:16px}
.c3 .el:has(>.filter){display:flex;flex-direction:column-reverse}.c3 .el:has(>.filter) .elbar{margin:10px 0 0}
.c3 .f h4{margin:0 0 6px;font-size:12px;color:var(--ink3);font-weight:500}
.c3 .f .val{font:13px var(--m);color:var(--ink)}
.c3 .brandt{display:flex;gap:6px}
.c3 .brandt button{flex:1;height:38px;border-radius:10px;border:1px solid var(--line2);background:rgba(255,255,255,.03);cursor:pointer}
.c3 .brandt button.on{border-color:var(--cyan);background:rgba(62,220,242,.08)}
.c3 .brandt .lg{height:14px;width:48px}
.c3 .flags{display:flex;flex-wrap:wrap;gap:6px}
.c3 .flags button{display:inline-flex;gap:6px;align-items:center;border:1px solid var(--line2);background:transparent;color:var(--ink2);border-radius:999px;padding:4px 9px;font-size:12px;cursor:pointer}
.c3 .flags button.on{border-color:var(--cyan);color:var(--ink)}
.c3 .mc{border-radius:16px;padding:20px;background:linear-gradient(180deg,rgba(255,255,255,.05),rgba(255,255,255,.015));border:1px solid var(--line2);position:relative}
.c3 .mc .glow{position:absolute;inset:-1px;border-radius:16px;padding:1px;background:linear-gradient(140deg,var(--cls),transparent 40%);-webkit-mask:linear-gradient(#000 0 0) content-box,linear-gradient(#000 0 0);-webkit-mask-composite:xor;mask-composite:exclude;pointer-events:none}
.c3 .mc .cls{font:11px var(--m);letter-spacing:.14em;text-transform:uppercase;color:var(--cls)}
.c3 .mc .nx{font-size:20px;font-weight:600;margin-top:4px}
.c3 .mc .cpu2{display:flex;align-items:center;gap:8px;color:var(--ink2);font-size:13px;margin-top:6px}
.c3 .mc .cpu2 .lg{height:14px;width:46px}
.c3 .mc .g{display:grid;grid-template-columns:repeat(3,1fr);gap:8px;margin:16px 0}
.c3 .mc .g div{border-radius:10px;background:rgba(255,255,255,.035);padding:8px 10px}
.c3 .mc .g b{display:block;font-size:16px} .c3 .mc .g span{font-size:11px;color:var(--ink3)}
.c3 .mc .foot{display:flex;justify-content:space-between;align-items:center}
.c3 .mc .price{font-size:22px;font-weight:600}
.c3 .pc{border-radius:14px;padding:16px;background:var(--p-surf);border:1px solid var(--p-rim);position:relative}
.c3 .pc .glow{position:absolute;inset:-1px;border-radius:14px;padding:1px;background:linear-gradient(140deg,var(--p-violet),transparent 45%);-webkit-mask:linear-gradient(#000 0 0) content-box,linear-gradient(#000 0 0);-webkit-mask-composite:xor;mask-composite:exclude}
.c3 .pc .nx{font-weight:600} .c3 .pc .s{color:var(--p-tx3);font-size:13px}
.c3 .pc .meta{display:flex;justify-content:space-between;margin-top:12px;font-size:13px;color:var(--p-tx2)}

/* ---------- C4 BENCHMARK ---------- */
.c4 .hero{display:grid;grid-template-columns:1fr 1.1fr;gap:28px;align-items:center;border:1px solid var(--line);border-radius:16px;padding:30px;background:var(--bg2)}
.c4 .hero h3{font-size:32px;line-height:1.1;font-weight:600;letter-spacing:-.02em}
.c4 .hero p{color:var(--ink2);margin:.6em 0 1.2em}
.c4 .term{background:#03060d;border:1px solid var(--line2);border-radius:12px;padding:14px 16px;font:12px var(--m);color:var(--ink3)}
.c4 .term .h{display:flex;justify-content:space-between;color:var(--ink2);margin-bottom:10px}
.c4 .cores{display:grid;grid-template-columns:repeat(8,1fr);gap:6px;height:120px;align-items:end}
.c4 .core{position:relative;height:100%;border-radius:4px;background:rgba(255,255,255,.04);overflow:hidden}
.c4 .core i{position:absolute;left:0;right:0;bottom:0;background:linear-gradient(0deg,var(--blue),var(--cyan));border-radius:4px;height:40%;animation:c4l 3.2s ease-in-out infinite alternate}
.c4 .core:nth-child(2n) i{animation-duration:2.6s;animation-delay:-1s}
.c4 .core:nth-child(3n) i{animation-duration:4.1s;animation-delay:-2s}
@keyframes c4l{0%{height:28%}50%{height:78%}100%{height:52%}}
.c4 .term .f{display:flex;justify-content:space-between;margin-top:10px}
.c4 .term b{color:var(--green);font-weight:500}
.c4 .tune{border:1px solid var(--line);border-radius:12px;padding:16px;background:var(--bg2);display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:18px}
.c4 .sort{display:flex;flex-wrap:wrap;gap:6px}
.c4 .sort button{border:1px solid var(--line2);background:transparent;color:var(--ink2);border-radius:8px;padding:5px 10px;font:12px var(--m);cursor:pointer}
.c4 .sort button.on{background:var(--ink);color:#060913;border-color:var(--ink)}
.c4 .hist{display:flex;align-items:end;gap:2px;height:26px;margin-bottom:4px}
.c4 .hist i{flex:1;background:rgba(62,220,242,.35);border-radius:1px}
.c4 .tune h4{margin:0 0 6px;font-size:12px;color:var(--ink3);font-weight:500;display:flex;justify-content:space-between}
.c4 .mc{border:1px solid var(--line);border-radius:12px;padding:18px;background:var(--bg2)}
.c4 .mc .top{display:flex;justify-content:space-between;align-items:start}
.c4 .mc .nx{font-weight:600;font-size:18px} .c4 .mc .s{color:var(--ink2);font-size:13px}
.c4 .mc .lg{height:16px;width:54px}
.c4 .bars{display:grid;gap:8px;margin:16px 0}
.c4 .bar{display:grid;grid-template-columns:70px 1fr 64px;gap:10px;align-items:center;font-size:12px;color:var(--ink3)}
.c4 .bar .t{height:6px;border-radius:3px;background:rgba(255,255,255,.06);overflow:hidden}
.c4 .bar .t i{display:block;height:100%;border-radius:3px;background:var(--cyan)}
.c4 .bar .v{text-align:right;color:var(--ink);font-family:var(--m)}
.c4 .mc .foot{display:flex;justify-content:space-between;align-items:center;border-top:1px solid var(--line);padding-top:12px}
.c4 .ppc{font:12px var(--m);color:var(--green)}
.c4 .tbl{width:100%;border-collapse:collapse;font-size:13px;background:var(--p-surf);border:1px solid var(--p-rim);border-radius:12px;overflow:hidden}
.c4 .tbl th{font:11px var(--m);text-transform:uppercase;letter-spacing:.1em;color:var(--p-tx3);text-align:left;padding:10px 12px;border-bottom:1px solid var(--p-rim)}
.c4 .tbl td{padding:10px 12px;border-bottom:1px solid var(--p-rim);color:var(--p-tx2)}
.c4 .tbl td:first-child{color:var(--p-tx);font-weight:600}
.c4 .tbl .r{text-align:right}

/* ---------- C5 CONCIERGE ---------- */
.c5 .hero{padding:44px 8px 30px;border-bottom:1px solid var(--line)}
.c5 .hero h3{font-size:clamp(34px,5.2vw,58px);line-height:1.02;font-weight:600;letter-spacing:-.035em;max-width:16ch}
.c5 .swap{display:inline-grid;height:1.05em;overflow:hidden;vertical-align:bottom;color:var(--cyan)}
.c5 .swap span{animation:c5w 9s infinite;display:block}
@keyframes c5w{0%,28%{transform:translateY(0)}33%,61%{transform:translateY(-100%)}66%,95%{transform:translateY(-200%)}100%{transform:translateY(0)}}
.c5 .hero p{color:var(--ink2);font-size:17px;max-width:56ch;margin:16px 0 22px}
.c5 .facts{display:flex;flex-wrap:wrap;gap:8px 24px;font:13px var(--m);color:var(--ink3)}
.c5 .facts .lg{height:16px;width:56px;vertical-align:-3px;margin-right:6px}
.c5 .guide{display:grid;gap:14px}
.c5 .q{font-size:15px;color:var(--ink2)}
.c5 .pills{display:flex;flex-wrap:wrap;gap:8px}
.c5 .pills button{border:1px solid var(--line2);background:transparent;color:var(--ink);border-radius:999px;padding:9px 16px;font:15px var(--f);cursor:pointer}
.c5 .pills button.on{background:var(--ink);color:#060913}
.c5 .more{font-size:13px;color:var(--ink3)}
.c5 .mc{border:1px solid var(--line);border-radius:16px;padding:26px;display:grid;gap:14px;background:linear-gradient(180deg,#0a1020,#070b17)}
.c5 .mc .bf{font-size:13px;color:var(--cyan)}
.c5 .mc .nx{font-size:24px;font-weight:600;letter-spacing:-.015em}
.c5 .mc .line{color:var(--ink2)}
.c5 .mc .specs{display:flex;flex-wrap:wrap;gap:6px 18px;font:13px var(--m);color:var(--ink3)}
.c5 .mc .foot{display:flex;justify-content:space-between;align-items:center;margin-top:6px}
.c5 .mc .price{font-size:26px;font-weight:600}
.c5 .pc{border:1px solid var(--p-rim);border-radius:14px;padding:18px;background:var(--p-surf);display:grid;gap:8px}
.c5 .pc .bf{font-size:12px;color:var(--p-tx3)} .c5 .pc .nx{font-size:18px;font-weight:600}
.c5 .pc .foot{display:flex;justify-content:space-between;align-items:center;font-size:13px;color:var(--p-tx2)}

@media (max-width:820px){
  .c1 .hero,.c2 .hero,.c3 .hin,.c4 .hero{grid-template-columns:1fr}
  .c2 .layout{grid-template-columns:1fr}
  .c2 .mc{grid-template-columns:1fr} .c2 .mc .r{text-align:left}
  .c4 .tbl{display:block;overflow-x:auto}
}
</style>

<div class="wrap">
  <header class="intro">
    <h1>Bare Metal concepts</h1>
    <p>Five directions for the hero, the filter card and the server cards, on the marketing site and in the portal. Press <b>Pick</b> on any element you like. You can mix pieces from different concepts, and add a note under each one. Prices and specs are examples to show the layout, not final catalogue data.</p>
    <div class="status" id="st">Connecting…</div>
    <nav class="nav">
      <a href="#c1">1 Spec Sheet</a><a href="#c2">2 Rack Unit</a><a href="#c3">3 Aurora Glass</a><a href="#c4">4 Benchmark</a><a href="#c5">5 Concierge</a>
    </nav>
  </header>
  <div id="bands"></div>
</div>

<script>
const FLAGS={
 sg:'<svg viewBox="0 0 30 20"><rect width="30" height="10" fill="#EF3340"/><rect y="10" width="30" height="10" fill="#fff"/><circle cx="7" cy="5" r="3" fill="#fff"/><circle cx="8.2" cy="5" r="3" fill="#EF3340"/></svg>',
 de:'<svg viewBox="0 0 30 20"><rect width="30" height="7" fill="#000"/><rect y="7" width="30" height="6" fill="#DD0000"/><rect y="13" width="30" height="7" fill="#FFCE00"/></svg>',
 fr:'<svg viewBox="0 0 30 20"><rect width="10" height="20" fill="#0055A4"/><rect x="10" width="10" height="20" fill="#fff"/><rect x="20" width="10" height="20" fill="#EF4135"/></svg>',
 ca:'<svg viewBox="0 0 30 20"><rect width="30" height="20" fill="#fff"/><rect width="7.5" height="20" fill="#D52B1E"/><rect x="22.5" width="7.5" height="20" fill="#D52B1E"/><path d="M15 5l1.4 3 2.4-.8-1 3.2 1.6.4-3 2.4.3 1.8H13.3l.3-1.8-3-2.4 1.6-.4-1-3.2 2.4.8z" fill="#D52B1E"/></svg>',
 uk:'<svg viewBox="0 0 30 20"><rect width="30" height="20" fill="#012169"/><path d="M0 0l30 20M30 0L0 20" stroke="#fff" stroke-width="4"/><path d="M0 0l30 20M30 0L0 20" stroke="#C8102E" stroke-width="1.6"/><path d="M15 0v20M0 10h30" stroke="#fff" stroke-width="6"/><path d="M15 0v20M0 10h30" stroke="#C8102E" stroke-width="3.4"/></svg>',
 us:'<svg viewBox="0 0 30 20"><rect width="30" height="20" fill="#fff"/><g fill="#B22234"><rect height="1.54" width="30"/><rect y="3.08" height="1.54" width="30"/><rect y="6.16" height="1.54" width="30"/><rect y="9.24" height="1.54" width="30"/><rect y="12.32" height="1.54" width="30"/><rect y="15.4" height="1.54" width="30"/><rect y="18.46" height="1.54" width="30"/></g><rect width="13" height="10.8" fill="#3C3B6E"/></svg>'
};
const flag=k=>`<span class="flag">${FLAGS[k]}</span>`;
const logo=(b,w,h)=>`<span class="lg lg-${b}" role="img" aria-label="${b.toUpperCase()}" style="${w?`width:${w}px;`:''}${h?`height:${h}px`:''}"></span>`;
const CLS={Forge:'#3EDCF2',Pulse:'#E04BD6',Core:'#3FD89A',Titan:'#9B6BFF',GPU:'#F2B64B'};
const B=[
 {nx:'NX-Forge 8-64a',cls:'Forge',cpu:'AMD EPYC 4344P',brand:'amd',c:8,t:16,ghz:'3.8–5.3 GHz',ram:64,disk:'2× 960 GB NVMe',net:'1 Gbps',reg:'Singapore',f:'sg',p:203.99,tag:'Recommended',bf:'Game networks and busy VPS hosts'},
 {nx:'NX-Pulse 8-64c',cls:'Pulse',cpu:'AMD Ryzen 7 9800X3D',brand:'amd',c:8,t:16,ghz:'4.7–5.2 GHz',ram:64,disk:'2× 1 TB NVMe',net:'1 Gbps',reg:'Frankfurt',f:'de',p:455.99,tag:'High performance',bf:'Single-thread heavy games and simulations'},
 {nx:'NX-Core 4-16b',cls:'Core',cpu:'Intel Xeon E3-1230 v6',brand:'intel',c:4,t:8,ghz:'3.5–3.9 GHz',ram:16,disk:'2× 480 GB SSD',net:'500 Mbps',reg:'Beauharnois',f:'ca',p:25.99,tag:'Best value',bf:'Small sites, bots and dev boxes'},
 {nx:'NX-GPU 16-192',cls:'GPU',cpu:'AMD EPYC 9124 + 2× NVIDIA L4',brand:'nvidia',c:16,t:32,ghz:'3.0–3.7 GHz',ram:192,disk:'2× 1.92 TB NVMe',net:'2 Gbps',reg:'Gravelines',f:'fr',p:1249.99,tag:'GPU',bf:'AI inference, rendering and transcoding'}
];
const money=v=>'$'+v.toFixed(2);
const pick=(c,e)=>`<button class="pick" type="button" aria-pressed="false" data-c="${c}" data-e="${e}">Pick</button>`;
const el=(c,e,label,html)=>`<div class="el"><div class="elbar"><span class="lab">${label}</span>${pick(c,e)}</div>${html}</div>`;

/* ---- C1 Spec Sheet ---- */
function c1(){
 const board=`<svg class="board" viewBox="0 0 420 260" aria-hidden="true">
  <rect class="tr" x="6" y="6" width="408" height="248" rx="10"/>
  <rect class="tr" x="150" y="70" width="110" height="110" rx="6"/><text x="168" y="130">CPU SOCKET</text>
  ${[0,1,2,3].map(i=>`<rect class="tr" x="${290+i*28}" y="40" width="16" height="180" rx="3"/>`).join('')}<text x="292" y="236">DIMM ×4</text>
  <rect class="tr" x="30" y="190" width="90" height="22" rx="3"/><text x="38" y="205">NVMe 0</text>
  <rect class="tr" x="30" y="220" width="90" height="22" rx="3"/><text x="38" y="235">NVMe 1</text>
  <rect class="tr" x="30" y="30" width="70" height="40" rx="3"/><text x="38" y="54">2× 1G NIC</text>
  <path class="tr" d="M100 50 H150 V90 M120 200 H150 V170 M260 120 H290"/>
  <path class="pulse" d="M100 50 H150 V90 M150 125 H260 V120 H290 V60"/>
  <path class="pulse b" d="M120 230 H140 V170 H150 M205 180 V200 H300 V220"/>
 </svg>`;
 const mc=b=>`<article class="mc"><div class="top"><div><div class="tag">${b.tag}</div><div class="nx">${b.nx}</div><div class="cpu">${b.cpu}</div></div>${logo(b.brand)}</div>
  <dl><dt>Cores / threads</dt><dd class="mono">${b.c} / ${b.t}</dd><dt>Clock</dt><dd class="mono">${b.ghz}</dd><dt>Memory</dt><dd class="mono">${b.ram} GB</dd><dt>Storage</dt><dd class="mono">${b.disk}</dd><dt>Network</dt><dd class="mono">${b.net}</dd><dt>Location</dt><dd>${flag(b.f)} ${b.reg}</dd></dl>
  <div class="foot"><div class="price">${money(b.p)}<small> /mo</small></div><button class="btn" type="button">Configure</button></div></article>`;
 const pc=b=>`<article class="pc"><div class="nx">${b.nx}</div><div class="p mono">${money(b.p)}/mo</div><div class="sub">${b.cpu}</div><div class="mini"><span>${b.c}C/${b.t}T</span><span>${b.ram} GB</span><span>${b.disk}</span><span>${flag(b.f)} ${b.reg}</span></div></article>`;
 return el('c1','hero','Hero · board diagram, light travels along the real traces',`<div class="hero"><div><h3>Your own server. Every core, every lane.</h3><p>Bare metal dedicated servers, in stock and online within 24 hours. No neighbours, full root, our portal for everything.</p><button class="btn" type="button">Choose a build</button><div class="brands">${logo('amd',70,22)}${logo('intel',56,22)}${logo('nvidia',80,20)}</div></div>${board}</div>`)
  +el('c1','filter','Filter · one compact toolbar',`<div class="filter"><div class="fg">${['sg','de','fr','ca'].map((f,i)=>`<button class="chip ${i==0?'on':''}" type="button">${flag(f)}</button>`).join('')}</div><div class="fg"><button class="chip on" type="button">${logo('amd',48,18)}</button><button class="chip" type="button">${logo('intel',40,18)}</button><button class="chip" type="button">${logo('nvidia',52,18)}</button></div><label class="rg"><span>Memory · 32 GB+</span><input id="c1r" type="range" min="16" max="256" value="32"></label><label class="rg"><span>Price · up to $500</span><input id="c1p" type="range" min="25" max="1500" value="500"></label><span class="mono" style="color:var(--ink3);font-size:12px;margin-left:auto">18 builds</span></div>`)
  +el('c1','mcard','Marketing card · datasheet',`<div class="row r2">${B.slice(0,3).map(mc).join('')}</div>`)
  +el('c1','pcard','Portal card · compact row',`<div class="row r2">${B.slice(0,3).map(pc).join('')}</div>`);
}
/* ---- C2 Rack Unit ---- */
function c2(){
 const units=['nx-core-4-16','nx-forge-8-64','YOUR SERVER · NX-PULSE 8-64','nx-forge-16-128','nx-titan-96-128','nx-gpu-16-192'];
 const rack=`<div class="rack" aria-hidden="true">${units.map((u,i)=>`<div class="u ${i==2?'you':''}"><span class="led ${i%2?'g':'b'}"></span><span class="led ${i%3?'':'g'}"></span><span>${u}</span><span class="vent"></span><span class="led b"></span></div>`).join('')}</div>`;
 const mc=b=>`<article class="mc" style="--cls:${CLS[b.cls]}">${logo(b.brand,72,28)}<div><div class="nx">${b.nx} <span class="s">· ${b.cpu}</span></div><div class="specs"><span>${b.c}C/${b.t}T</span><span>${b.ram} GB</span><span>${b.disk}</span><span>${b.net}</span><span>${flag(b.f)} ${b.reg}</span></div></div><div class="r"><div class="price">${money(b.p)}</div><div class="s">per month</div></div></article>`;
 const pc=b=>`<article class="pc"><span class="leds"><span class="led g" style="width:6px;height:6px;border-radius:50%;display:inline-block;background:var(--green)"></span></span><div><div class="nx">${b.nx}</div><div class="s">${b.cpu} · ${b.ram} GB · ${b.reg}</div></div><div class="p mono">${money(b.p)}</div></article>`;
 return el('c2','hero','Hero · a rack where your unit is lit, activity LEDs blink at real-looking rates',`<div class="hero"><div><h3>A whole machine in our rack, with your name on it.</h3><p>Pick a unit, we rack it, image it and hand you the keys within 24 hours.</p><button class="btn" type="button">See what's in stock</button></div>${rack}</div>`)
  +el('c2','filter','Filter · left rail, list results',`<div class="layout"><aside class="rail"><div><h4>Location</h4>${[['sg','Singapore'],['de','Frankfurt'],['fr','Gravelines'],['ca','Beauharnois']].map(([f,n],i)=>`<label class="opt"><input type="checkbox" ${i<2?'checked':''}> ${flag(f)} ${n}</label>`).join('')}</div><div><h4>Processor</h4>${['amd','intel','nvidia'].map((b,i)=>`<label class="opt"><input type="checkbox" ${i==0?'checked':''}> ${logo(b,64,20)}</label>`).join('')}</div><div><h4>Memory · 64 GB+</h4><input type="range" min="16" max="256" value="64"></div><div><h4>Price · up to $600</h4><input type="range" min="25" max="1500" value="600"></div></aside><div class="stack">${B.slice(0,3).map(mc).join('')}</div></div>`)
  +el('c2','mcard','Marketing card · rack faceplate, class colour on the edge',`<div class="stack">${B.map(mc).join('')}</div>`)
  +el('c2','pcard','Portal card · faceplate row with status LED',`<div class="stack">${B.slice(0,3).map(pc).join('')}</div>`);
}
/* ---- C3 Aurora Glass ---- */
function c3(){
 const mc=b=>`<article class="mc" style="--cls:${CLS[b.cls]}"><span class="glow"></span><div class="cls">NX-${b.cls} · ${b.tag}</div><div class="nx">${b.nx}</div><div class="cpu2">${logo(b.brand,46,14)} ${b.cpu}</div><div class="g"><div><b class="mono">${b.c}</b><span>cores</span></div><div><b class="mono">${b.ram} GB</b><span>memory</span></div><div><b>${flag(b.f)}</b><span>${b.reg}</span></div></div><div class="foot"><div class="price">${money(b.p)}<span style="font-size:13px;color:var(--ink3);font-weight:400"> /mo</span></div><button class="btn ghost" type="button">Configure</button></div></article>`;
 const pc=b=>`<article class="pc"><span class="glow"></span><div class="nx">${b.nx}</div><div class="s">${b.cpu}</div><div class="meta"><span class="mono">${b.c}C · ${b.ram} GB · ${b.disk}</span><span class="mono">${money(b.p)}</span></div></article>`;
 return el('c3','hero','Hero · the marketing aurora, with one product shot: a CPU lid catching a slow light sweep',`<div class="hero"><div class="au"></div><div class="hin"><div><h3>Bare metal, finished like the rest of Nxeon.</h3><p>Dedicated servers on current AMD, Intel and NVIDIA hardware. In stock, online within 24 hours.</p><button class="btn" type="button">Browse servers</button><div class="logos"><span>${logo('amd',66,20)}</span><span>${logo('intel',56,20)}</span><span>${logo('nvidia',72,18)}</span></div></div><div class="chipw"><div class="cpu"><span class="pins"></span><b>NX</b><small>BARE METAL</small></div></div></div></div>`)
  +el('c3','filter','Filter · frosted card overlapping the hero edge',`<div class="filter"><div class="f"><h4>Processor</h4><div class="brandt"><button class="on" type="button">${logo('amd',48,14)}</button><button type="button">${logo('intel',40,14)}</button><button type="button">${logo('nvidia',52,14)}</button></div></div><div class="f"><h4>Location</h4><div class="flags">${[['sg','SG'],['de','DE'],['fr','FR'],['ca','CA'],['uk','UK'],['us','US']].map(([f,n],i)=>`<button class="${i==0?'on':''}" type="button">${flag(f)} ${n}</button>`).join('')}</div></div><div class="f"><h4>Memory <span class="val">64 GB+</span></h4><input type="range" min="16" max="256" value="64"></div><div class="f"><h4>Monthly price <span class="val">≤ $500</span></h4><input type="range" min="25" max="1500" value="500"></div></div>`)
  +el('c3','mcard','Marketing card · glass, colour-coded by class',`<div class="row r2">${B.slice(0,3).map(mc).join('')}</div>`)
  +el('c3','pcard','Portal card · portal navy with a violet edge',`<div class="row r2">${B.slice(0,3).map(pc).join('')}</div>`);
}
/* ---- C4 Benchmark ---- */
function c4(){
 const max={c:16,ram:192};
 const mc=b=>`<article class="mc"><div class="top"><div><div class="nx">${b.nx}</div><div class="s">${b.cpu}</div></div>${logo(b.brand,54,16)}</div><div class="bars"><div class="bar"><span>Cores</span><span class="t"><i style="width:${b.c/max.c*100}%"></i></span><span class="v">${b.c}C/${b.t}T</span></div><div class="bar"><span>Memory</span><span class="t"><i style="width:${b.ram/max.ram*100}%;background:var(--violet)"></i></span><span class="v">${b.ram} GB</span></div><div class="bar"><span>Network</span><span class="t"><i style="width:${parseFloat(b.net)/ (b.net.includes('Mbps')?2000:2)*100}%;background:var(--blue)"></i></span><span class="v">${b.net}</span></div></div><div class="foot"><div><div style="font-size:20px;font-weight:600">${money(b.p)}<span style="font-size:12px;color:var(--ink3);font-weight:400"> /mo</span></div><div class="ppc">${money(b.p/b.c)} per core</div></div><div>${flag(b.f)} <span style="font-size:13px;color:var(--ink2)">${b.reg}</span></div></div></article>`;
 const hist=n=>Array.from({length:24},(_,i)=>`<i style="height:${15+Math.round(80*Math.abs(Math.sin(i*.7+n)))}%"></i>`).join('');
 return el('c4','hero','Hero · a live core monitor: eight cores, all yours, nobody else on them',`<div class="hero"><div><h3>Eight cores. All of them yours.</h3><p>No noisy neighbours and no shared CPU. Bare metal servers measured the way you'll use them.</p><button class="btn" type="button">Compare builds</button></div><div class="term" aria-hidden="true"><div class="h"><span>nx-forge-8-64a</span><span>load · 8 cores</span></div><div class="cores">${Array.from({length:8},()=>'<div class="core"><i></i></div>').join('')}</div><div class="f"><span>steal <b>0.0%</b></span><span>neighbours <b>0</b></span><span>uptime 41d</span></div></div></div>`)
  +el('c4','filter','Filter · sort pills and sliders with the stock spread behind them',`<div class="tune"><div><h4>Sort by</h4><div class="sort"><button class="on" type="button">price / core</button><button type="button">cores</button><button type="button">memory</button><button type="button">price</button></div></div><div><h4>Cores <span class="mono">8+</span></h4><div class="hist">${hist(1)}</div><input type="range" min="4" max="96" value="8"></div><div><h4>Memory <span class="mono">64 GB+</span></h4><div class="hist">${hist(2)}</div><input type="range" min="16" max="256" value="64"></div><div><h4>Location</h4><div class="sort">${['sg','de','fr','ca'].map((f,i)=>`<button class="${i==0?'on':''}" type="button">${flag(f)}</button>`).join('')}</div></div></div>`)
  +el('c4','mcard','Marketing card · meters and price per core',`<div class="row r2">${B.slice(0,3).map(mc).join('')}</div>`)
  +el('c4','pcard','Portal view · a sortable table',`<div style="overflow-x:auto"><table class="tbl"><thead><tr><th>Build</th><th>Processor</th><th class="r">Cores</th><th class="r">Memory</th><th>Location</th><th class="r">Price</th></tr></thead><tbody>${B.map(b=>`<tr><td>${b.nx}</td><td>${b.cpu}</td><td class="r mono">${b.c}/${b.t}</td><td class="r mono">${b.ram} GB</td><td>${flag(b.f)} ${b.reg}</td><td class="r mono">${money(b.p)}</td></tr>`).join('')}</tbody></table></div>`);
}
/* ---- C5 Concierge ---- */
function c5(){
 const mc=b=>`<article class="mc"><div class="bf">Best for: ${b.bf}</div><div class="nx">${b.nx}</div><div class="line">${b.cpu}, ${b.ram} GB of memory, ${b.disk}.</div><div class="specs"><span>${b.c} cores / ${b.t} threads</span><span>${b.net}</span><span>${flag(b.f)} ${b.reg}</span></div><div class="foot"><div class="price">${money(b.p)}<span style="font-size:14px;color:var(--ink3);font-weight:400"> a month</span></div><button class="btn" type="button">Choose this server</button></div></article>`;
 const pc=b=>`<article class="pc"><div class="bf">Best for: ${b.bf}</div><div class="nx">${b.nx}</div><div class="foot"><span>${b.cpu} · ${b.ram} GB · ${flag(b.f)} ${b.reg}</span><span class="mono">${money(b.p)}</span></div></article>`;
 return el('c5','hero','Hero · type only: the headline cycles through what people run',`<div class="hero"><h3>A dedicated server for <span class="swap"><span>game networks.</span><span>render farms.</span><span>big databases.</span></span></h3><p>Tell us what you're running and we'll show the bare metal builds that fit. In stock, online within 24 hours, managed from your Nxeon portal.</p><div class="facts"><span>${logo('amd',56,16)}EPYC · Ryzen</span><span>${logo('intel',46,16)}Xeon</span><span>${logo('nvidia',60,14)}L4 · A-series</span></div></div>`)
  +el('c5','filter','Filter · guided questions first, sliders tucked away',`<div class="guide"><div class="q">What are you running?</div><div class="pills"><button class="on" type="button">Game servers</button><button type="button">Websites & apps</button><button type="button">Databases</button><button type="button">AI & rendering</button><button type="button">Not sure</button></div><div class="q">Where are your users?</div><div class="pills">${[['sg','Asia'],['de','Europe'],['ca','North America'],['uk','UK']].map(([f,n],i)=>`<button class="${i==0?'on':''}" type="button">${flag(f)} ${n}</button>`).join('')}</div><div class="more">More filters: memory, cores, storage, price ▾</div></div>`)
  +el('c5','mcard','Marketing card · spacious, two per row, written in plain words',`<div class="row" style="grid-template-columns:repeat(auto-fit,minmax(340px,1fr))">${B.slice(0,2).map(mc).join('')}</div>`)
  +el('c5','pcard','Portal card · same voice, smaller',`<div class="row r2">${B.slice(0,3).map(pc).join('')}</div>`);
}
const META=[
 ['c1','Spec Sheet','Calm and technical. Plenty of space, specs set like a datasheet, one blue accent.',c1],
 ['c2','Rack Unit','Hardware as the metaphor: cards are rack faceplates, results are a list you scan.',c2],
 ['c3','Aurora Glass','Closest to the marketing site: the aurora, glass cards, a colour per server class.',c3],
 ['c4','Benchmark','Numbers first: meters, price per core, a sortable table in the portal.',c4],
 ['c5','Concierge','Editorial and guided: big type, plain-language cards, questions before filters.',c5]
];
document.getElementById('bands').innerHTML=META.map(([id,name,desc,fn],i)=>`<section class="band ${id}" id="${id}"><div class="bandhead"><span class="k">Concept ${i+1}</span><h2>${name}</h2><p>${desc}</p></div>${fn()}<textarea class="note" id="note-${id}" placeholder="Notes on ${name} (optional)"></textarea></section>`).join('');

/* ---- picks, saved for Claude ---- */
const state={}; let db=null;
const st=t=>document.getElementById('st').textContent=t;
function paint(){document.querySelectorAll('.pick').forEach(b=>{const s=state[b.dataset.c];const on=!!(s&&s[b.dataset.e]);b.setAttribute('aria-pressed',String(on));b.textContent=on?'Picked':'Pick'});
 META.forEach(([id])=>{const t=document.getElementById('note-'+id);if(t&&document.activeElement!==t)t.value=(state[id]&&state[id].note)||''});
 const n=Object.values(state).reduce((a,s)=>a+['hero','filter','mcard','pcard'].filter(k=>s[k]).length,0);if(db)st(n?`${n} element${n>1?'s':''} picked · saved for Claude`:'Nothing picked yet · picks save automatically')}
async function save(id){if(!db){st('Sign in to claude.ai to save picks');return}try{await db.doc('picks/'+id).set({...state[id],updatedAt:new Date().toISOString()})}catch(e){st('Could not save ('+(e.code||'error')+'). Try again.')}}
document.addEventListener('click',e=>{const b=e.target.closest('.pick');if(!b)return;const c=b.dataset.c,k=b.dataset.e;state[c]=state[c]||{};state[c][k]=!state[c][k];paint();save(c)});
document.addEventListener('input',e=>{const t=e.target;if(!t.classList.contains('note'))return;const id=t.id.slice(5);state[id]=state[id]||{};state[id].note=t.value;clearTimeout(t._t);t._t=setTimeout(()=>save(id),700)});
document.addEventListener('click',e=>{const b=e.target.closest('.chip,.flags button,.brandt button,.sort button,.pills button');if(b&&!b.classList.contains('pick')){b.classList.toggle('on')}});
paint();
(async()=>{try{db=await claude.use('db');if(!db){st('Read-only: sign in to claude.ai to save picks');return}
 db.collection('picks').onSnapshot(s=>{for(const d of s.docs){const v=d.data();if(v)state[d.id]=v}paint()},()=>st('Live sync paused'));paint()}catch(e){st('Read-only right now')}})();
</script>
"""
open("/root/agent-notes/bm-concepts/index.html", "w").write(HTML.replace("LOGOS", logos))
print("written", len(HTML) + len(logos))
