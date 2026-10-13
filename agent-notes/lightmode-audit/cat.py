import json,re,sys,collections
def load(p): return json.load(open(p))
def rc(it):
    sel=it['sel']; fg=it['fg'].replace(' ','')
    if 'text-transparent' in sel or 'bg-clip-text' in sel or 'grad-text' in sel: return None
    if re.search(r'text-(red|rose|amber|emerald|green|sky|cyan|violet|purple|blue|yellow|orange|teal|indigo|pink|fuchsia|lime)-[1-4]00',sel): return 'D palette pastel text'
    if re.search(r'text-\[#',sel) or re.search(r'border-\[#|bg-\[#',sel): return 'C hard-coded hex colours'
    if fg in ('rgb(100,119,142)','rgb(96,122,153)','rgb(123,145,173)','rgb(74,99,130)','rgb(71,96,127)') or re.search(r'text-(tx-faint|slate-[56]00|tx-dim|tx-mute)',sel): return 'A muted-text tokens below AA'
    if fg in ('rgb(10,156,111)','rgb(185,119,8)','rgb(11,145,171)','rgb(208,42,84)') or re.search(r'text-(mint|amber|cyan|rose)\b',sel): return 'B status accent tokens below AA'
    if fg in ('rgb(10,24,41)','rgb(8,23,41)') and it['ratio']<3.6: return 'F ink-on-brand-fill (text-white flips)'
    if fg=='rgb(255,255,255)' : return 'E selected pill / white on translucent fill'
    return 'Z other'
def run(p):
    d=load(p); agg=collections.defaultdict(lambda:{'n':0,'pages':set(),'min':9,'ex':[]})
    for k,v in d.items():
        page=k.split('|')[0]
        for it in v['lowContrast']:
            if it['island']: continue
            r=rc(it)
            if not r: continue
            a=agg[r]; a['n']+=1; a['pages'].add(page); a['min']=min(a['min'],it['ratio'])
            if len(a['ex'])<4: a['ex'].append((page,it['text'],it['ratio'],it['sel'][:60]))
    return agg
if __name__=='__main__':
    agg=run(sys.argv[1])
    for r,a in sorted(agg.items()): print(f"{r:45} instances={a['n']:5} pages={len(a['pages']):3} worst={a['min']}")
    d=load(sys.argv[1]); print('scenes',len(d),'total elems',sum(len([i for i in v['lowContrast'] if not i['island'] and rc(i)]) for v in d.values()))
