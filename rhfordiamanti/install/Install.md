# Install Step by Step

## パラメータ値  
| 設定 | 値 |
|:--|:--|
| ドメイン名 | nwdiamanti.local |
| Cluster Name | ocp |
| subdomain | ocp.nwdiamanti.local |
| Network VLAN | 450 |
| Storage VLAN | 4011 |

## リソース
| リソース | IP | ID | Password |
|:--|:--|:--|:--|  
| AD/dhcp | 172.18.0.10 | administrator@nwdiamanti.local | Password1! |
| LB/Web | 172.18.0.12 | root | Netw0rld |
| diamanti1-4 | 172.18.0.21-24 | root | diamanti |
| ocp master0-2 | 172.18.0.41-43 | core | 証明書ベース |
|  |  |  |  |


## 事前に作成するリソース
- DNS
- Load Balancer
- Web Server  

今回の環境では、Install用のLinux兼、LB(HAProxy)/Webserver(Nginx)を作成  
DNSはADサーバーに兼任  

## 必要なライセンス
- OpenShift ライセンス  
  - ライセンスに紐づいているRedHat Account  
  

## OpenShift バイナリのダウンロード  
必要なバイナリは**OpenShift installer**と**RHCOS**のisoファイル、**PullSecret**,**OCのバイナリ**など。  
https://cloud.redhat.com/openshift/install/metal/user-provisioned   

インストーラーは最新のものしか置いていないので、バージョンを指定する場合はファイルを探す必要がある。    


Installer : プロダクトダウンロードページからダウンロード(https://access.redhat.com/downloads/content/290/ver=4.3/rhel---7/4.3.38/x86_64/product-software)  
RHCOS : https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/  
  
## Load Balancer (HAProxy)
Configのサンプルは conf/haproxy.cfg に保存済み  
Configのパスは /etc/haproxy/  

細かい設定はQiita参照  
https://qiita.com/daihiraoka/items/ada36baef875805f004f  


## Web Server (Nginx)  
Configのサンプルは conf/default.conf に保存済み  
Configのパスは  /etc/nginx/conf.d/  
公開するファイルパスは下記のように構造にしている  

```
# tree /usr/share/nginx/html/
/usr/share/nginx/html/
 -- 50x.html
 -- index.html
  --- ocp
    ---- bios.raw.gz -> rhcos-4.3.8-x86_64-metal.x86_64.raw.gz
    ---- bootstrap.ign
    ---- index.html
    ---- master.ign
    ---- rhcos-4.3.8-x86_64-metal.x86_64.raw.gz
    ---- worker.ign
```

### ファイルの配置  
5つのファイルを配置する。これはRHCOSがOSブート時にConfigをWebサーバーから取得してOSを構成するために利用する  

- bootstrap.ign
- index.html
- master.ign
- rhcos-4.3.33-x86_64-metal.x86_64.raw.gz
- worker.ign  

*.ignはOpenShift Installer で生成するため、あとから配置する  
**rhcos-4.3.33-x86_64-metal.x86_64.raw.gz**はファイル名が長すぎるので、**bios.raw.gz**にリンクを貼っておく  

`ln -s rhcos-4.3.33-x86_64-metal.x86_64.raw.gz bios.raw.gz`  


## SSHの秘密鍵、公開鍵の作成    
OCPのインストール全体としては2回作る必要がある。
  1. OCP installを実行する際に、RHCOSにSSHできるように公開鍵を埋め込む
  2. Diamanti rpmをインストールする際に、Ansibleを実行するがその際に証明書ベースで各Diamanti hostに接続するために利用

よって、ocp installがDiamanti hostではない場合、2つの秘密鍵が必要になる。
また、OCP installを実行したホストで作成した秘密鍵はAnsibleを実行するDiamanti hostにコピーする必要がある。
面倒なので、１つの秘密鍵ですべてが済むようにする

  - OCP Installerを実行するホストで実施
  (前提) Diamanti hostがすべて実行されていること  
         Diamanti RPMをインストールするホストは **diamanti4**  
```
ssh-keygen -t rsa -b 4096 -N '' -f ~/.ssh/id_rsa
eval "$(ssh-agent -s)" 
scp ~/.ssh/id_rsa root@diamanti4:~/.ssh/core_id_rsa
```
    - diamanti hostに公開鍵を配る
```
for host in diamanti1.nwdiamanti.local \
diamanti2.nwdiamanti.local \
diamanti3.nwdiamanti.local \
diamanti4.nwdiamanti.local; \
do ssh-copy-id -i ~/.ssh/id_rsa.pub $host; \
done
```

  - diamanti4 で実施  
    - sshの接続確認  
```
ssh -i ~/.ssh/core_id_rsa diamanti1.nwdiamanti.local
ssh -i ~/.ssh/core_id_rsa diamanti2.nwdiamanti.local
ssh -i ~/.ssh/core_id_rsa diamanti3.nwdiamanti.local
ssh -i ~/.ssh/core_id_rsa diamanti4.nwdiamanti.local
```

## Installerの準備とInstall-config.yamlの作成  
Installerをダウンロードし、Installerを実行するLinux上で展開します。  

```
mkdir ocp
cd ocp
//ここにインストーラとinstall-config.yamlを配置
ll

-rw-r--r--. 1 root root       706  3月 17  2020 README.md
drwxr-xr-x. 2 root root        33  9月 28 12:11 diamanti
-rw-r--r--. 1 root root      3878  8月 28 00:37 install-config.yaml.diamanti
-rwxr-xr-x. 1 root root 332449248  3月 17  2020 openshift-install
-rw-r--r--. 1 root root  82424252  8月  4 09:55 openshift-install-linux.tar.gz

mkdir diamanti
cp install-config.yaml.diamanti diamanti/install-config.yaml
```

installerは `tar -zxvf {filenaem}` で解凍する。  
Install-config.yamlをコピーした状態のディレクトリ構造は下記のようになる

````
# tree /root/ocp/
/root/ocp/
 - README.md
 - diamanti
   -- install-config.yaml
 - install-config.yaml
 - install-config.yaml.diamanti
 - openshift-install
 - openshift-install-linux.tar.gz
````

### Install-config.yamlの編集
DiamantiのNetworkモジュールを利用するように変更を行う。
また、PullSecretとSSHの公開鍵を埋め込む。  
サンプルは conf/install-config.yaml.diamanti に記載。  
PullSecretと公開鍵は環境に合わせて変更が必要です。  

- sample
```
apiVersion: v1
baseDomain: nwdiamanti.local
compute:
- name: worker
  replicas: 0
controlPlane:
  name: master
  replicas: 3
metadata:
  ## The name for the cluster
  name: ocp
networking:
  clusterNetworks:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  ## DiamantiSDNに変更(Default: OpenShiftSDN)
  networkType: DiamantiSDN
  serviceNetwork:
  - 172.30.0.0/16
platform:
  none: {}
pullSecret: '{"auths":{"cloud.~略~Fcw==","email":"suzukik@networld.co.jp"}}}'
sshKey: 'ssh-rsa ~略~nwdiamanti.local'
```

### Installer の実行  
インストーラを実行してファイルを作成します。4.2以降ではMaster Nodeにリソースがスケジュールされないように設定を変更する必要があります。
(Qiitaに手順あり)  

- マニフェストファイルの作成  
```
./openshift-install create manifests --dir=diamanti/

# ./openshift-install create manifests --dir=diamanti/
INFO Consuming Install Config from target directory
WARNING Making control-plane schedulable by setting MastersSchedulable to true for Scheduler cluster settings
```

- マニフェストの編集 
`vi diamanti/manifests/cluster-scheduler-02-config.yml`

```
apiVersion: config.openshift.io/v1
kind: Scheduler
metadata:
  creationTimestamp: null
  name: cluster
spec:
  ## trueをfalseに変更
  mastersSchedulable: false
  policy:
    name: ""
status: {}
```

- Ignition fileの作成  
```
./openshift-install create ignition-configs --dir=diamanti/

 ./openshift-install create ignition-configs --dir=diamanti/
INFO Consuming Openshift Manifests from target directory
INFO Consuming OpenShift Install (Manifests) from target directory
INFO Consuming Master Machines from target directory
INFO Consuming Worker Machines from target directory
INFO Consuming Common Manifests from target directory
```

- ファイルのコピーと権限の変更  
```
cp diamanti/*.ign /usr/share/nginx/html/ocp/
chmod 777 /usr/share/nginx/html/ocp/*.ign
```

- NGINX公開ディレクトリの状態
権限は特に縛りなく777でつけていますが、本番環境では環境に合わせて設定してください。  
RHCOSのバイナリも権限エラーが出る可能性があるので、必ず設定を確認してください。  

```
# ll /usr/share/nginx/html/ocp/
合計 785032
lrwxrwxrwx. 1 root root        38  8月  3 16:46 bios.raw.gz -> rhcos-4.3.8-x86_64-metal.x86_64.raw.gz
-rwxrwxrwx. 1 root root    296426  9月 28 15:37 bootstrap.ign
-rw-r--r--. 1 root root       621  8月  3 16:04 index.html
-rwxrwxrwx. 1 root root      1825  9月 28 15:37 master.ign
-rwxr-xr-x. 1 root root 803561085  8月  3 16:43 rhcos-4.3.8-x86_64-metal.x86_64.raw.gz
-rwxrwxrwx. 1 root root      1825  9月 28 15:37 worker.ign
```


## Master Nodeの展開  
Master NodeはvSphere上の仮想マシンに展開します。今回はベアメタルインストールにも対応ができるようにベアメタルベースでインストールを実施します。  
Master NodeはRHCOS(Red Hat CoreOS)で構成します。
今回はTerraformでVMの作成とISOからのブートまで設定します。  

また、RHCOSは基本、DHCPでネットワークを構成します。
VM作成時にMacAddressを固定にして、DHCPサーバーでIPを固定しています。  

構成するVMは4台あります。
- bootstrap : 1
- master : 3

BootStrapから設定し、次にMaster を3台設定します。
Boot画面からの実行方法は下記

- "Install RHEL CoreOS" がでたらEnter
- "Press Enter ~~"でEnter
- `/usr/libexec/coreos-installer -d sda -b http://172.18.0.12:8008/ocp/bios.raw.gz -i http://172.18.0.12:8008/ocp/bootstrap.ign` を実行  
- Install Complete でReboot
- 数分待つ
- 残りのMasterもBoot画面に移動する  
- "Press Enter ~~"でEnter
- `/usr/libexec/coreos-installer -d sda -b http://172.18.0.12:8008/ocp/bios.raw.gz -i http://172.18.0.12:8008/ocp/master.ign` を実行  
- Install Complete でReboot

### Install Statusの確認
次に **DiamantiSDN** をインストールするために、OpenShiftのインストール状況を確認します。
OpenShift Installerを実行したホストに戻り、下記のコマンドを実行します。  

`./openshift-install --dir=diamanti/ wait-for bootstrap-complete --log-level=debug`

```
# ./openshift-install --dir=diamanti/ wait-for bootstrap-complete --log-level=debug
DEBUG OpenShift Installer 4.3.8
DEBUG Built from commit f7a2f7cf9ec3201bb8c9ebb677c05d21c72e3cc5
INFO Waiting up to 30m0s for the Kubernetes API at https://api.ocp.nwdiamanti.local:6443...
DEBUG Still waiting for the Kubernetes API: the server could not find the requested resource
DEBUG Still waiting for the Kubernetes API: Get https://api.ocp.nwdiamanti.local:6443/version?timeout=32s: EOF
INFO API v1.16.2 up
INFO Waiting up to 30m0s for bootstrapping to complete...
```

"INFO Waiting up to 30m0s for bootstrapping to complete..."が表示されたら次に進みます。 
このコンソールは閉じないでそのままにしておきます。   

### Diamanti Moduleのインストール  
準備されている Ansible Playbookを使って、RHCOSにインストールします。  
この作業は **Diamanti host** で実行します。今回はDiamanti4です。  

- 公開鍵認証の確認
下記コマンドでそれぞれ接続できるか確認します。
```
ssh -i ~/.ssh/core_id_rsa core@master0.nwdiamanti.local
ssh -i ~/.ssh/core_id_rsa core@master1.nwdiamanti.local
ssh -i ~/.ssh/core_id_rsa core@master3.nwdiamanti.local
```

```
[root@diamanti4 ~]# ssh -i ~/.ssh/core_id_rsa core@master0.nwdiamanti.local
The authenticity of host 'master0.nwdiamanti.local (172.18.0.41)' can't be established.
ECDSA key fingerprint is SHA256:MgNLqG6G41fnrJKgGhuYS/PX2+TlLq/9d4bjZq6ZixI.
ECDSA key fingerprint is MD5:06:09:bc:54:6b:68:d6:77:e3:68:7a:41:27:98:cc:c8.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'master0.nwdiamanti.local,172.18.0.41' (ECDSA) to the list of known hosts.
Red Hat Enterprise Linux CoreOS 43.81.202003191953.0
  Part of OpenShift 4.3, RHCOS is a Kubernetes native operating system
  managed by the Machine Config Operator (`clusteroperator/machine-config`).

WARNING: Direct SSH access to machines is not recommended; instead,
make configuration changes via `machineconfig` objects:
  https://docs.openshift.com/container-platform/4.3/architecture/architecture-rhcos.html

---
[core@master0 ~]$ exit
logout
Connection to master0.nwdiamanti.local closed.
[root@diamanti4 ~]# ssh -i ~/.ssh/core_id_rsa core@master1.nwdiamanti.local
The authenticity of host 'master1.nwdiamanti.local (172.18.0.42)' can't be established.
ECDSA key fingerprint is SHA256:33yOTuS/85BgRNxp1xmfMdn0LqxPnNZtyThKbNOXEpk.
ECDSA key fingerprint is MD5:da:74:cf:19:ba:df:50:5b:6f:d3:bb:5f:0d:6d:96:dd.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'master1.nwdiamanti.local,172.18.0.42' (ECDSA) to the list of known hosts.
Red Hat Enterprise Linux CoreOS 43.81.202003191953.0
  Part of OpenShift 4.3, RHCOS is a Kubernetes native operating system
  managed by the Machine Config Operator (`clusteroperator/machine-config`).

WARNING: Direct SSH access to machines is not recommended; instead,
make configuration changes via `machineconfig` objects:
  https://docs.openshift.com/container-platform/4.3/architecture/architecture-rhcos.html

---
[core@master1 ~]$ exit
logout
Connection to master1.nwdiamanti.local closed.
[root@diamanti4 ~]# ssh -i ~/.ssh/core_id_rsa core@master2.nwdiamanti.local
The authenticity of host 'master2.nwdiamanti.local (172.18.0.43)' can't be established.
ECDSA key fingerprint is SHA256:YfibVw1eGGVRL3ZLsta+l4ACCr7mrAR6zZMGbbSv6do.
ECDSA key fingerprint is MD5:4d:4d:2d:ab:c1:a2:bd:be:27:a6:c4:4f:e8:d1:8d:c0.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'master2.nwdiamanti.local,172.18.0.43' (ECDSA) to the list of known hosts.
Red Hat Enterprise Linux CoreOS 43.81.202003191953.0
  Part of OpenShift 4.3, RHCOS is a Kubernetes native operating system
  managed by the Machine Config Operator (`clusteroperator/machine-config`).

WARNING: Direct SSH access to machines is not recommended; instead,
make configuration changes via `machineconfig` objects:
  https://docs.openshift.com/container-platform/4.3/architecture/architecture-rhcos.html

---
[core@master2 ~]$ exit
logout
Connection to master2.nwdiamanti.local closed.
```

- kubeconfigのコピー 
Installerを実行したホストにKubeconfigが作成されます。それをDiamanti hostにコピーします。  

```
mkdir ~/.kube
scp root@172.18.0.12:/root/ocp/diamanti/auth/kubeconfig ~/.kube/config
```

- インストールの実行  
スクリプトの問題で秘密鍵のファイル名を **id_rsa** にして実行します。  

```
mv ~/.ssh/core_id_rsa ~/.ssh/id_rsa
/usr/local/bin/install_ovs.sh ocp nwdiamanti.local
```
Log
```
# mv ~/.ssh/core_id_rsa ~/.ssh/id_rsa
# /usr/local/bin/install_ovs.sh ocp nwdiamanti.local

Using ssh key ~/.ssh/id_rsa
Install Diamanti CNI to Openshift cluster

Get master node details.

master0.nwdiamanti.local
master1.nwdiamanti.local
master2.nwdiamanti.local

Load OVS images on all Master Nodes.

master0.nwdiamanti.local
master1.nwdiamanti.local
master2.nwdiamanti.local
Remove existing docker images from core@master0.nwdiamanti.local

Copy OVS docker images to core@master0.nwdiamanti.local

Load OVS docker image on core@master0.nwdiamanti.local
Remove existing docker images from core@master1.nwdiamanti.local

Copy OVS docker images to core@master1.nwdiamanti.local

Load OVS docker image on core@master1.nwdiamanti.local
Remove existing docker images from core@master2.nwdiamanti.local

Copy OVS docker images to core@master2.nwdiamanti.local

Load OVS docker image on core@master2.nwdiamanti.local

Get etcd endpoint list.

172.18.0.41
172.18.0.42
172.18.0.43

Replace all etcd endpoint to OVS daemonset.

Flag --export has been deprecated, This flag is deprecated and will be removed in future.

Create etcd-client CA cert configmap

Flag --export has been deprecated, This flag is deprecated and will be removed in future.

Create etcd-client tls cert and key secrets

Update Cluster Network CRD status.
========== Creating Diamanti OVS daemonset ==========

Running
Diamanti OVS pod dcx-ovs-daemon-8q98w in Running state

Running
Diamanti OVS pod dcx-ovs-daemon-fljrt in Running state

Running
Diamanti OVS pod dcx-ovs-daemon-qllm4 in Running state
```

### Install Statusの確認 その２
Installerを実行したホストに戻ります。  
Status確認のコマンドを実行したコンソールが開いたままになっているかと思います。  
ステータスが変わっていることを確認します。

```
# ./openshift-install --dir=diamanti/ wait-for bootstrap-complete --log-level=debug
DEBUG OpenShift Installer 4.3.8
DEBUG Built from commit f7a2f7cf9ec3201bb8c9ebb677c05d21c72e3cc5
INFO Waiting up to 30m0s for the Kubernetes API at https://api.ocp.nwdiamanti.local:6443...
DEBUG Still waiting for the Kubernetes API: the server could not find the requested resource
DEBUG Still waiting for the Kubernetes API: Get https://api.ocp.nwdiamanti.local:6443/version?timeout=32s: EOF
INFO API v1.16.2 up
INFO Waiting up to 30m0s for bootstrapping to complete...
DEBUG Bootstrap status: complete
INFO It is now safe to remove the bootstrap resources
```

次に下記コマンドを実行してステータスを確認します。  
`./openshift-install --dir=diamanti/ wait-for install-complete --log-level=debug`
構成が完了するまで時間がかかります。  
Diamanti hostから `oc get clustroperators` どのOperatorの構成待ちが確認できます。watchしたい場合は`watch -n5 oc get clusteroperators`で5秒間隔で更新されます。  


ステータスが99%で止まります。
```
DEBUG Still waiting for the cluster to initialize: Working towards 4.3.8: 99% complete
DEBUG Still waiting for the cluster to initialize: Some cluster operators are still updating: authentication, console, ingress, monitoring
```
Diamanti hostのデプロイを始めます。 
コンソールはこのままにしておきます。   

### Diamanti HostをOpenShift Workerノードに設定  
Diamanti hostをWorkerノードに設定します。
これもDiamanti host上からAnsibleを利用し実行しますが、ノードの再起動が実行されるため、Ansibleコマンドを実行するホストはノードの追加対象外にしてください（改めて別ノードから追加します）  

- ansible inventoryの編集  
`vi /etc/ansible/ocx_workers_sample_inventory`  

```
[all:vars]
ansible_user=root
#ansible_become=True

openshift_kubeconfig_path="~/.kube/config"

oreg_auth_user="suzukik@networld"
oreg_auth_password=Kemiroom1216!
### add line ###
oreg_poolid=8a85f99c73c470240173c6dafdb67795
################

cluster_name=ocp
subdomain=nwdiamanti.local
storage_vlan=4011

[new_workers]
diamanti1.nwdiamanti.local
diamanti2.nwdiamanti.local
diamanti3.nwdiamanti.local
```

- ansibleファイルの編集  
最初の10数行部分を変更する。  

```
---
- name:  Host Registration using RHSM
  hosts: new_workers
  gather_facts: no
  tasks:
#    - name: Ensuring Password Less Host Access
#      shell: yes y | ssh-keygen -f ~/.ssh/id_rsa -N ''
#      run_once: true
#    - authorized_key:
#        user: root
#        state: present
#        key: "{{ lookup('file', '/root/.ssh/id_rsa.pub') }}"

    - name: RHSM Registration
      redhat_subscription:
        state: present
        username: "{{oreg_auth_user}}"
        password: "{{oreg_auth_password}}"
        force_register: true
      tags:
        - register

    - name: Refresh registration
      shell: |
        subscription-manager refresh

#    - name: Get RHSM Pool ID
#      shell: |
#        subscription-manager list --available --matches 'Red Hat OpenShift Container Platform Partner Developer Support' --pool-only
#      register: pool_id
#      tags:
#        - getpoolid
    - name: Attach Pool ID
      shell: |
        subscription-manager attach --pool={{ oreg_poolid }}
      tags:
        - attachpool
```


- ansible 実行  
`ansible-playbook -i /etc/ansible/ocx_workers_sample_inventory /usr/share/ansible/openshift-ansible/playbooks/diamanti_add_workers.yml`  

正常に完了したことを確認します。  
Ansible実行中にエラーが出た場合はエラーを確認します。
少なくとも、Ansible実行直後のPoolIDやSSH関連、Red Hatアカウント以外ではエラーは発生しません  



### Install Statusの確認 その３
Installerを実行したホストに戻ります。  
Status確認のコマンドを実行したコンソールが開いたままになっているかと思います。  
エラーで止まっているはずなので、再度コマンドを実行します。  

`./openshift-install --dir=diamanti/ wait-for install-complete --log-level=debug`
`oc get clusteroperators`

```
# ./openshift-install --dir=diamanti/ wait-for install-complete --log-level=debug
DEBUG OpenShift Installer 4.3.8
DEBUG Built from commit f7a2f7cf9ec3201bb8c9ebb677c05d21c72e3cc5
DEBUG Fetching Install Config...
DEBUG Loading Install Config...
DEBUG   Loading SSH Key...
DEBUG   Loading Base Domain...
DEBUG     Loading Platform...
DEBUG   Loading Cluster Name...
DEBUG     Loading Base Domain...
DEBUG     Loading Platform...
DEBUG   Loading Pull Secret...
DEBUG   Loading Platform...
DEBUG Using Install Config loaded from state file
DEBUG Reusing previously-fetched Install Config
INFO Waiting up to 30m0s for the cluster at https://api.ocp.nwdiamanti.local:6443 to initialize...
DEBUG Still waiting for the cluster to initialize: Some cluster operators are still updating: authentication, console, monitoring
DEBUG Still waiting for the cluster to initialize: Some cluster operators are still updating: authentication, console, monitoring
DEBUG Still waiting for the cluster to initialize: Some cluster operators are still updating: authentication, console, monitoring
DEBUG Still waiting for the cluster to initialize: Some cluster operators are still updating: authentication, console, monitoring
DEBUG Still waiting for the cluster to initialize: Working towards 4.3.8: 100% complete
DEBUG Cluster is initialized
INFO Waiting up to 10m0s for the openshift-console route to be created...
DEBUG Route found in openshift-console namespace: console
DEBUG Route found in openshift-console namespace: downloads
DEBUG OpenShift console route is created
INFO Install complete!
INFO To access the cluster as the system:admin user when using 'oc', run 'export KUBECONFIG=/root/ocp/diamanti/auth/kubeconfig'
INFO Access the OpenShift web-console here: https://console-openshift-console.apps.ocp.nwdiamanti.local
INFO Login to the console with user: kubeadmin, password: zsNcm-iWGdB-iP4iw-bsRPU
```




