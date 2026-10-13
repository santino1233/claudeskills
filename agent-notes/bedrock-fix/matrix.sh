rm -rf /opt/bt1
ping() { python3 - "$1" <<'PY'
import socket,sys,struct
s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);s.settimeout(3)
magic=bytes.fromhex("00ffff00fefefefefdfdfdfd12345678")
pkt=b"\x01"+struct.pack(">q",1)+magic+struct.pack(">q",2)
try:
  s.sendto(pkt,("127.0.0.1",int(sys.argv[1])));d,_=s.recvfrom(4096);print("RAKNET_PONG",d[0]==0x1c, d[35:120])
except Exception as e: print("RAKNET_NO_REPLY",e)
PY
}
for V in "$@"; do for T in default raknet; do
  rm -rf /opt/bt1; mkdir -p /opt/bt1; docker rm -f bt1 >/dev/null 2>&1
  E=""; [ $T = raknet ] && E="-e TRANSPORT=raknet"
  docker run -d --name bt1 -e EULA=TRUE -e VERSION=$V $E -p 19150:19132/udp -p 19150:19132/tcp -p 19151:19133/udp -v /opt/bt1:/data itzg/minecraft-bedrock-server >/dev/null
  for i in $(seq 1 40); do docker logs bt1 2>&1 | grep -q "Server started" && break; sleep 2; done; sleep 3
  echo "=== VERSION=$V transport=$T"
  docker logs bt1 2>&1 | grep -E "IPv4 supported|IPv6 supported|Accepting clients|TRANSPORT TYPE|Version:"
  echo "udp:"; docker exec bt1 sh -c 'awk "NR>1{print \$2}" /proc/net/udp /proc/net/udp6' | tr '\n' ' '; echo
  echo "tcp listen:"; docker exec bt1 sh -c 'awk "NR>1 && \$4==\"0A\"{print \$2}" /proc/net/tcp /proc/net/tcp6' | tr '\n' ' '; echo
  ping 19150
  docker rm -f bt1 >/dev/null 2>&1; rm -rf /opt/bt1
done; done
