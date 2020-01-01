#!/bin/bash
IP=$(kubectl get services | grep candy-neutrino-s | awk '{print $4}')
kubectl exec candy-neutrino-0 -- rm /root/.lnd/tls.cert
kubectl exec candy-neutrino-0 -- rm /root/.lnd/tls.key
# kubectl exec lnd-pod -- cat server.json > tmp.json
cat server.json >> tmp.json
sed -i  "bak" "s/address/$IP/g" tmp.json
kubectl cp tmp.json candy-neutrino-0:/server.new.json
rm tmp.json
kubectl exec candy-neutrino-0 -- sh -c 'cfssl gencert -initca server.new.json | cfssljson -bare ca -'
kubectl exec candy-neutrino-0 -- sh -c 'cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=config.json server.new.json | cfssljson -bare server'
kubectl exec candy-neutrino-0 -- sh -c 'mv /server.pem /root/.lnd/tls.cert'
kubectl exec candy-neutrino-0 -- sh -c 'mv /server-key.pem /root/.lnd/tls.key'
kubectl delete pod candy-neutrino-0