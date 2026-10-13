import sys,re
# keep both sides (HEAD then theirs) for every conflict in the file
for f in sys.argv[1:]:
    out=[];st=0
    for l in open(f).read().split('\n'):
        if l.startswith('<<<<<<< '): st=1; continue
        if l.startswith('=======') and st==1: st=2; continue
        if l.startswith('>>>>>>> ') and st==2: st=0; continue
        out.append(l)
    open(f,'w').write('\n'.join(out))
