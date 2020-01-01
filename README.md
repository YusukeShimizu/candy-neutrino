## 前提
1. GCPプロジェクト準備済
2. GCLOUDをinstall済
3. dockerをinstall済
4. kubectlをinstall済

## GKE
まずはクラスタを作る。
対象のプロジェクトが存在するconfigurationを指定する。

```sh
gcloud config configurations activate CONFIGURATION_NAME
```

続いて、空のクラスタを作成する。

```
gcloud container clusters create candy-neutrino --machine-type=n1-standard-1 --num-nodes=1 --region asia-northeast1-a
gcloud container clusters describe candy-neutrino
```

続いて、今後のローカルでのkubectlとの連携のために、credentialを渡す。

```sh
$ gcloud container clusters get-credentials candy-neutrino --zone asia-northeast1-a
Fetching cluster endpoint and auth data.
kubeconfig entry generated for test-cluster.
$ kubectl config get-contexts
```
対象のコンテキストが指定されていることを確認する。

## docker
Container Registry を認証するには、gcloud を Docker 認証ヘルパーとして使用する。

```
gcloud auth configure-docker
```

これができたら、imageをbuildし、gcrにpushする。
```sh
cd lnd
docker build . -t gcr.io/<PROJECT_NAME>/candy-neutrino:latest --no-cache
```
下記を実行すると、下記の用にイメージが表示されるはずだ。

```sh
$ docker images
gcr.io/bruwbird/candy-neutrino                                latest              aaaaaaaaaaaa        25 hours ago        72.7MB
```

続いて、このイメージをGCRにプッシュする。

```sh
docker push gcr.io/<PROJECT_NAME>/candy-neutrino:latest
```

```sh
gcloud container images list 
```

.envをシークレットとして展開する。

```
cp .env.sample .env
kubectl create secret generic neutrino-secret --from-env-file=.env
```

## deploy
statefulsetを利用する。

```sh
sed -i  "bak" "s/your-project-ID/<PROJECT_NAME>/g" StatefulSet.yaml
$ kubectl apply -f StatefulSet.yaml --record
statefulset.apps/candy-neutrino created
kubectl apply -f service.yaml
service/candy-neutrino-s created
```

一定時間が経過すると、podsが作成されていることが確認できる。

```sh
$ kubectl get pods
NAME         READY     STATUS    RESTARTS   AGE
candy-neutrino-0   1/1       Running   1          99m
```

volumeは下記の通り。

```sh
~/g/g/Y/candy-neutrino ❯❯❯ kubectl get pvc -o wide                                                                                                                             2019/12/30 17:50:36 [master]
NAME                                      STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
candy-neutrino-storage-candy-neutrino-0   Bound     pvc-97ab8e3a-2ae0-11ea-a85b-42010a920041   10Gi       RWO            standard       6m7s
```

## 動作
実際にコンテナの中に入り、動作確認をする。

```sh
kubectl exec -it candy-neutrino-0 bash
lncli create
Input wallet password: 
Confirm password:


Do you have an existing cipher seed mnemonic you want to use? (Enter y/n): n

Your cipher seed can optionally be encrypted.
Input your passphrase if you wish to encrypt it (or press enter to proceed without a cipher seed passphrase): 

Generating fresh cipher seed...

!!!YOU MUST WRITE DOWN THIS SEED TO BE ABLE TO RESTORE THE WALLET!!!

---------------BEGIN LND CIPHER SEED---------------
 1. abstract   2. high       3. biology   4. slight 
 5. weekend    6. tonight    7. mystery   8. submit 
 9. easily    10. royal     11. wood     12. figure 
13. benefit   14. ordinary  15. ceiling  16. item   
17. lottery   18. next      19. opera    20. clump  
21. faith     22. copper    23. song     24. tuition
---------------END LND CIPHER SEED-----------------

!!!YOU MUST WRITE DOWN THIS SEED TO BE ABLE TO RESTORE THE WALLET!!!

lnd successfully initialized!
```

このあとの作業に使うlnd node用のGUIツールとしては、[zap](https://zap.jackmallers.com/)を推奨。

## prepare keys
tls及びmacaroonsは、lappsを稼働させるときに必要になるケースが多い。
下記のshellを実行し、tlsを再作成する。

```sh
cd lnd
./rebuild-tls.sh
```

localに落とす時は`kubectl cp`を利用する。
```sh
kubectl cp candy-neutrino-0:root/.lnd/data/chain/bitcoin/testnet/admin.macaroon ./admin.macaroon
kubectl cp candy-neutrino-0:/root/.lnd/tls.cert ./tls.cert
```

## monitoring
必要に応じてlndmonを構築することをおすすめする。
https://github.com/YusukeShimizu/lndmon-gke