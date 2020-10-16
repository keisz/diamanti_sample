1. Login to DR cluster
dctl -s <VIP> login

2. Save kube config to a file named "kubeconfig"
cp ~/.kube/config kubeconfig

3. Create remote-kubeconfig secret
kubectl create secret -n diamanti-system generic remote-kubeconfig --from-file=kubeconfig

4. Get volume replicator helm chart from the following path
cp /usr/share/diamanti/ui/helm/charts/volume-replicator-0.1.0.tgz ~/
tar -xzf volume-replicator-0.1.0.tgz
cd volume-replicator

5. Update values.yaml if required
helm install -n scheduled .

6. Create volume replication config
Refer to the example pvc-replicate.yaml
