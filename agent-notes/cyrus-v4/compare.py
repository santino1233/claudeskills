# side-by-side: concept (left) | ours (right), same size. usage: python3 compare.py ours.png out.png
import sys
from PIL import Image
a=Image.open('/root/agent-notes/cyrus-v4/owner-concept.png').convert('RGB')
b=Image.open(sys.argv[1]).convert('RGB').resize(a.size)
o=Image.new('RGB',(a.width*2+12,a.height),(255,255,255)); o.paste(a,(0,0)); o.paste(b,(a.width+12,0)); o.save(sys.argv[2])
