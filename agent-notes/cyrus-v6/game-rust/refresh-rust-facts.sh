#!/usr/bin/env bash
# Monthly refresh of Cyrus's Rust facts (run after each first-Thursday forced update, once Oxide has released).
# Needs only public data: Oxide's MIT repo and Carbon's public metadata. Writes into a scratch dir; review, then copy.
#   1. regenerates lib/cyrus/games/rust.hooks.ts (hook names)
#   2. prints the hook-manifest diff between the previous and current Rust build (=> knowledge.failureRules / versions[].breaking)
#   3. re-checks every prefab path and item shortname the generator emits
set -euo pipefail
WT="${1:?usage: refresh-rust-facts.sh <worktree>}"
S="$(mktemp -d)"; cd "$S"
git clone -q --filter=blob:none --no-checkout https://github.com/OxideMod/Oxide.Rust.git oxr
for r in Oxide.Rust Oxide.Core Oxide.CSharp; do git clone -q --depth 1 https://github.com/OxideMod/$r.git $r; done
for f in carbon/hooks rust/prefabs rust/entities rust/items; do curl -s -o "meta_$(echo $f|tr / _).json" "https://api.carbonmod.gg/meta/$f.json"; done
git -C oxr log --format='%h %cd %s' --date=short -- resources/Rust.opj | grep -E "Rust update \(" | head -3
python3 - "$WT" <<'PY'
import json,re,glob,subprocess,sys
wt=sys.argv[1]
log=subprocess.check_output(['git','-C','oxr','log','--format=%h %s','--','resources/Rust.opj'],text=True).splitlines()
updates=[l.split()[0] for l in log if re.search(r'Rust update \(',l)]
cur,prev=updates[0],updates[1]
def load(c):
  d=json.loads(subprocess.check_output(['git','-C','oxr','show',f'{c}:resources/Rust.opj'],text=True)); out={}
  for m in d['Manifests']:
    for h in m['Hooks']:
      hh=h['Hook']; out[hh['Name']]=(hh['HookName'],hh['TypeName']+'.'+hh['Signature']['Name']+'('+','.join(hh['Signature']['Parameters'])+')',hh.get('ArgumentString'))
  return out
head=subprocess.check_output(['git','-C','oxr','rev-parse','--short','origin/HEAD'],text=True).strip()
A,B=load(prev),load(head)
print('== hook diff', prev, '->', head)
for k in sorted(set(B)-set(A)): print('+',k,B[k][1])
for k in sorted(set(A)-set(B)): print('-',k,A[k][1])
for k in sorted(set(A)&set(B)):
  if A[k][1:]!=B[k][1:]: print('~',k,A[k][1:],'->',B[k][1:])
names={v[0] for v in B.values()}
src=''.join(open(f).read() for f in glob.glob('Oxide.*/src/**/*.cs',recursive=True))
names|=set(re.findall(r'CallHook\("([A-Za-z_]+)"',src))
c=json.load(open('meta_carbon_hooks.json'))
names|={h['Name'] for hs in c.values() for h in hs if h.get('OxideCompatible')}
names|={'Init','Loaded','Unload','OnServerInitialized','OnServerShutdown','LoadDefaultConfig','LoadDefaultMessages','OnPluginLoaded','OnPluginUnloaded','OnUserConnected','OnPlayerConnected'}
names=sorted(n for n in names if re.match(r'^[A-Za-z_]+$',n) and not re.match(r'^I[A-Z]',n) and not (n.startswith('Init') and n!='Init'))
print('hooks:',len(names),'-> write', wt+'/lib/cyrus/games/rust.hooks.ts (Set literal) after review')
json.dump(names,open('hooknames.json','w'))
pre={p['Path'] for p in json.load(open('meta_rust_prefabs.json'))}|{p['Path'] for p in json.load(open('meta_rust_entities.json'))}
gen=open(wt+'/lib/cyrus/engine/games/rust.ts').read()+open(wt+'/test/cyrus-game-rust.test.ts').read()
for p in sorted(set(re.findall(r'"(assets/[^"]+\.prefab)"',gen))):
  if p not in pre: print('PREFAB GONE:',p)
items={i['ShortName'] for i in json.load(open('meta_rust_items.json'))}
for s in sorted(set(re.findall(r'\[/[^/]+/, "([a-z0-9.]+)"\]',gen))|{'rifle.ak','bone.club','rock','scrap','metal.ore','stones','wood','sulfur.ore','hq.metal.ore','ammo.rifle','explosive.timed'}):
  if s not in items: print('ITEM GONE:',s)
print('scratch dir:', '.')
PY
echo "scratch: $S"
