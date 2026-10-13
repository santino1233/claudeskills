import json,sys,collections,re
d=json.load(open(sys.argv[1]))
agg=collections.defaultdict(lambda:{'n':0,'pages':set(),'ex':None,'min':9})
for k,v in d.items():
    page=k
    for it in v['lowContrast']:
        if it['island']: continue
        sig=re.sub(r'\.(\S+)',lambda m:m.group(0),it['sel'])
        key=(sig,it['fg'],it['bg'])
        a=agg[key]; a['n']+=1; a['pages'].add(page.split('|')[0]); a['min']=min(a['min'],it['ratio'])
        if not a['ex']: a['ex']=it['text']
rows=sorted(agg.items(),key=lambda kv:(-len(kv[1]['pages']),kv[1]['min']))
for (sel,fg,bg),a in rows[:int(sys.argv[2]) if len(sys.argv)>2 else 60]:
    print(f"{len(a['pages']):3}p {a['n']:4}n r={a['min']:.2f} {fg}/{bg} {sel[:110]} | {a['ex']!r}")
