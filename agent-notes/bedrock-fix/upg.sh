rm -rf /opt/bt1; mkdir -p /opt/bt1; docker rm -f bt1 >/dev/null 2>&1
run(){ docker run -d --name bt1 -e EULA=TRUE -e VERSION=$1 $2 -p 19150:19132/udp -v /opt/bt1:/data itzg/minecraft-bedrock-server >/dev/null
 for i in $(seq 1 40); do docker logs bt1 2>&1 | grep -q "Server started" && break; sleep 2; done; sleep 3
 echo "== $1 $2"; docker logs bt1 2>&1 | grep -E "Version:|IPv4 supp|Accepting"; grep -n "^transport" /opt/bt1/server.properties || echo "no transport key"; docker rm -f bt1 >/dev/null; }
run 1.26.45.1 ""
run 1.26.52.3 ""
run 1.26.52.3 "-e TRANSPORT=raknet"
grep -n "^transport" /opt/bt1/server.properties
run LATEST "-e TRANSPORT=raknet"
rm -rf /opt/bt1
