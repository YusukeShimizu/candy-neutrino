## deploy neutrino to GKE
Create container cluster
```
$ gcloud container clusters create candy-neutrino --machine-type=n1-standard-1 --num-nodes=1 --region asia-northeast1-a
$ gcloud container clusters describe candy-neutrino
```

Pass GKE configuration for you.

```sh
$ gcloud container clusters get-credentials candy-neutrino --zone asia-northeast1-a
Fetching cluster endpoint and auth data.
kubeconfig entry generated for test-cluster.
$ kubectl config get-contexts
```

Use gcloud for docker auth configuration.
```
$ gcloud auth configure-docker
```

Build image.
```sh
$ cd lnd
$ docker build . -t gcr.io/<PROJECT_NAME>/candy-neutrino:latest --no-cache
```

 Push image.
```sh
docker push gcr.io/<PROJECT_NAME>/candy-neutrino:latest
```

```sh
gcloud container images list 
```

Set .env as secret.

```
cp .env.sample .env
kubectl create secret generic neutrino-secret --from-env-file=.env
```

Apply yamls.

```sh
$ sed -i  "bak" "s/your-project-ID/<PROJECT_NAME>/g" StatefulSet.yaml
$ kubectl apply -f StatefulSet.yaml --record
statefulset.apps/candy-neutrino created
$ kubectl apply -f service.yaml
service/candy-neutrino-s created
```
Wait 5 minutes☕️ and then login to container.

```sh
$ kubectl exec -it candy-neutrino-0 bash
```

Create wallet.

```sh
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
Create new tls certificate which is valid for your ip and for your lnd.
```sh
$ cd lnd
$ ./rebuild-tls.sh
```

You can use [zap](https://zap.jackmallers.com/) to manage LND.

## monitoring
[lndmon gke settings](https://github.com/YusukeShimizu/lndmon-gke) is useful.