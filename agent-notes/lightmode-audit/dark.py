import json,sys,collections
d=json.load(open(sys.argv[1]))
agg=collections.defaultdict(lambda:{'pages':set(),'area':0,'bg':''})
for k,v in d.items():
    for b in v['darkBlocks']:
        a=agg[b['sel'][:120]]; a['pages'].add(k.split('|')[0]); a['area']=max(a['area'],b['area']); a['bg']=b['bg']
for s,a in sorted(agg.items(),key=lambda kv:-len(kv[1]['pages']))[:int(sys.argv[2])]:
    print(len(a['pages']),a['area'],a['bg'],s, sorted(a['pages'])[:3])
