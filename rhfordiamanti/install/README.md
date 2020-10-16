# OCP on Diamanti 向け RHEL7.6への入れ替え作業

## 前提
- Diamanti k8sが稼働している状態からOSごと入れ替える
- 既存でD20が4台あるため、１台はClusterからremoveしてOSを入れ替える
- 問題がなければ、Clusterを壊して、すべて入れ替える

## 手順
1. 対象のノードをClusterからremoveする
ノードの交換手順を参考にClusterからRemoveする。

```
kubectl drain <nodename> --force --delete-local-data --ignore-daemonsets --grace-period=300
dctl cluster remove <nodename>  <-- Use this command to remove a worker node
# etcのノードになっている場合は下記も実行
dctl cluster etcd-remove <nodename>  <-- Use this command to remove an etcd nodes
```

Removeでノードが再起動されます。

2. 環境の確認  
Disk構成などを念のためログとりしておく。結果的には不要！！

```
$ sudo fdisk -l
[sudo] password for diamanti:
WARNING: fdisk GPT support is currently new, and therefore in an experimental phase. Use at your own discretion.

Disk /dev/sda: 480.1 GB, 480103981056 bytes, 937703088 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disk label type: gpt
Disk identifier: 0B438856-0670-414F-87F0-183E07B29B03


#         Start          End    Size  Type            Name
 1         2048       411647    200M  EFI System      EFI System Partition
 2       411648      4605951      2G  Microsoft basic
 3      4605952    937701375    445G  Linux LVM

Disk /dev/sdb: 480.1 GB, 480103981056 bytes, 937703088 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disk label type: dos
Disk identifier: 0x000aa701

   Device Boot      Start         End      Blocks   Id  System
/dev/sdb1            2048   937701375   468849664   8e  Linux LVM

Disk /dev/mapper/centos_diamanti-root: 42.9 GB, 42949672960 bytes, 83886080 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes


Disk /dev/mapper/centos_diamanti-swap: 68.7 GB, 68719476736 bytes, 134217728 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes


Disk /dev/mapper/centos_diamanti-data: 257.7 GB, 257698037760 bytes, 503316480 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes


Disk /dev/mapper/centos_diamanti-home: 21.5 GB, 21474836480 bytes, 41943040 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes


Disk /dev/mapper/centos_diamanti-var_log_audit: 4294 MB, 4294967296 bytes, 8388608 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes


Disk /dev/mapper/centos_diamanti-var_log: 8589 MB, 8589934592 bytes, 16777216 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes


Disk /dev/mapper/centos_diamanti-var_tmp: 4294 MB, 4294967296 bytes, 8388608 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes


Disk /dev/mapper/centos_diamanti-var: 68.7 GB, 68719476736 bytes, 134217728 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes


Disk /dev/mapper/docker--vg-docker--lv: 480.1 GB, 480101007360 bytes, 937697280 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes

$ lsblk
NAME                              MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda                                 8:0    0 447.1G  0 disk
tqsda1                              8:1    0   200M  0 part /boot/efi
tqsda2                              8:2    0     2G  0 part /boot
mqsda3                              8:3    0   445G  0 part
  tqcentos_diamanti-root          253:0    0    40G  0 lvm  /
  tqcentos_diamanti-swap          253:1    0    64G  0 lvm  [SWAP]
  tqcentos_diamanti-data          253:2    0   240G  0 lvm  /data
  tqcentos_diamanti-home          253:3    0    20G  0 lvm  /home
  tqcentos_diamanti-var_log_audit 253:4    0     4G  0 lvm  /var/log/audit
  tqcentos_diamanti-var_log       253:5    0     8G  0 lvm  /var/log
  tqcentos_diamanti-var_tmp       253:6    0     4G  0 lvm  /var/tmp
  mqcentos_diamanti-var           253:7    0    64G  0 lvm  /var
sdb                                 8:16   0 447.1G  0 disk
mqsdb1                              8:17   0 447.1G  0 part
  mqdocker--vg-docker--lv         253:8    0 447.1G  0 lvm  /var/lib/docker

$ blkid
/dev/mapper/centos_diamanti-var: UUID="179dd332-5a19-40b7-abff-87799c9e973c" TYPE="xfs"
/dev/sda3: UUID="dTaT71-sDLe-kIrE-lH5u-Mj6Q-eATx-zNhlLY" TYPE="LVM2_member" PARTUUID="8b657409-88ee-4b3c-a555-5cb0b1fa190c"

```

3. ISOのマウント、インストール
IPMIを使ってISOマウントしてOSインストールができるようにする  
JavaをつかったKVMコンソールがいまいち動かないので、iKVM over HTML5で実施  

- IPMIのIPにWebブラウザでアクセス
- ログイン。今回は admin/diamanti デフォルトはadmin/admin  
- Virtual MediaタブからISOをマウント。Windowsは閉じない。(HTML5でつないでるので閉じたらきれる)  
- Remote Controlの iKVM over HTML5 を開き、Launch  
- NodeをRebootし、F6でBIOSに入る  
- BIOSからCDROMを選択し、実行
- ISOでBoot後、Installの実行をEnterで開始。あとは自動でインストール  
  
**HTML5のDVDマウントが結構こけるので注意**
**こけた場合はやり直し**


1. 初期設定
下記の設定を行う
- Timezoneの指定
- Hostnameの指定
- IPアドレスの設定  
- DNSの設定  

- Timezoneの設定
`timedatectl set-timezone Asia/Tokyo`
*[:]が入力できない。バーチャルキーボードで対応*  

- Hostnameの指定
`hostnamectl set-hostname diamanti4`

- IPアドレスの設定  
`sudo vi /etc/sysconfig/network-scripts/ifcfh-eno1`

  - 変更
    dhcp="none"  
  - 追記
    IPADDR=172.18.0.24  
    NETMASK=255.255.0.0  
    GATEWAY=172.18.254.254  

- DNSの設定
`vi /etc/resolv.conf`

```
search nwdiamanti.local
nameserver 172.18.0.10
```

5. rpm のインストール
事前にもらっているrpmをインストールする。ファイルは何らかの方法で対象ノードにおくる  

```
$ sudo rpm -ivh diamanti-ocx-3.0.0-72.x86_64.rpm
Preparing...                          ################################# [100%]
Updating / installing...
   1:diamanti-ocx-3.0.0-72            ################################# [100%]
Loading docker images .................
Setting up configuration for firmware installation
Firmware installation failed - Reason: Adapter not reachable
Please contact Diamanti Tech Support (support@diamanti.com)
```

インストールに失敗した場合はContainer/StorageネットワークのNICの設定が問題になっている可能性あり。
下記のコマンドを実行して、eth0 のIPを変更してからrpmをインストールする  

```
sudo dstool -c "ifconfig eth0 169.254.100.2 netmask 255.255.255.0"
sudo rpm -e diamanti-ocx
sudo rpm -ivh diamanti-ocx-3.0.0-72.x86_64.rpm
```

```
[diamanti@diamanti4 ~]$ sudo dstool -c "ifconfig eth0 169.254.100.2 netmask 255.255.255.0"
[sudo] password for diamanti:
[diamanti@diamanti4 ~]$ sudo rpm -e diamanti-ocx
diamanti: Stopping services on uninstall...
diamanti: Cleaning up on uninstall...
[diamanti@diamanti4 ~]$ sudo rpm -ivh diamanti-ocx-3.0.0-72.x86_64.rpm
Preparing...                          ################################# [100%]
Updating / installing...
   1:diamanti-ocx-3.0.0-72            ################################# [100%]
Loading docker images .................
Setting up configuration for firmware installation
Installing Firmware component 1 .................
Firmware component 1 installation succeeded
Please powercycle for changes to take effect
```


6. インストールのチェックポイント

- Diamanti CNIのデプロイについて
  - 手順通りはこける
    - 前提条件でrootにコピーしているがCompute Nodeのrootアカウントはわからない
      - user:diamantiを使う
      - これにより、あとのCompute nodeからのDiamanti OVSのデプロイに失敗する
  - OVSのデプロイ
    - コマンド上、sudoしていないがPermission Denied で失敗する 
      - sudo すればOK
    - 秘密鍵は `~/.ssh.id_rsa` でないといけない
      - 前の手順で **core_id_rsa** にしているのでこける
    - sudo した場合に、秘密鍵(~/.ssh/id_rsa)とkubeconfig(~/.kube/config) は/root/配下をみるので /home/diamanti/にしかもっていないとこける  
    -   

失敗版
````
$ /usr/local/bin/install_ovs.sh ocp ocp.nwdiamanti.local

Using ssh key ~/.ssh/id_rsa


Install Diamanti CNI to Openshift cluster


Get master node details.

etcd-0.ocp.nwdiamanti.local
etcd-2.ocp.nwdiamanti.local
master1.nwdiamanti.local

Load OVS images on all Master Nodes.

etcd-0.ocp.nwdiamanti.local
etcd-2.ocp.nwdiamanti.local
master1.nwdiamanti.local
Remove existing docker images from core@etcd-0.ocp.nwdiamanti.local

Copy OVS docker images to core@etcd-0.ocp.nwdiamanti.local

Load OVS docker image on core@etcd-0.ocp.nwdiamanti.local
Remove existing docker images from core@etcd-2.ocp.nwdiamanti.local

Copy OVS docker images to core@etcd-2.ocp.nwdiamanti.local

Load OVS docker image on core@etcd-2.ocp.nwdiamanti.local
Remove existing docker images from core@master1.nwdiamanti.local

Copy OVS docker images to core@master1.nwdiamanti.local

Load OVS docker image on core@master1.nwdiamanti.local

Get etcd endpoint list.

172.18.0.41
172.18.0.43
172.18.0.42

Replace all etcd endpoint to OVS daemonset.

cp: cannot create regular file ‘/usr/share/diamanti/manifests/ovs/k8s-ovs-server-daemonset.json’: Permission denied
sed: can't read /usr/share/diamanti/manifests/ovs/k8s-ovs-server-daemonset.json: No such file or directory
sed: can't read /usr/share/diamanti/manifests/ovs/k8s-ovs-server-daemonset.json: No such file or directory
sed: can't read /usr/share/diamanti/manifests/ovs/k8s-ovs-server-daemonset.json: No such file or directory
sed: can't read /usr/share/diamanti/manifests/ovs/k8s-ovs-server-daemonset.json: No such file or directory
sed: can't read /usr/share/diamanti/manifests/ovs/k8s-ovs-server-daemonset.json: No such file or directory
Flag --export has been deprecated, This flag is deprecated and will be removed in future.

Create etcd-client CA cert configmap

Flag --export has been deprecated, This flag is deprecated and will be removed in future.

Create etcd-client tls cert and key secrets


Update Cluster Network CRD status.


========== Creating Diamanti OVS daemonset ==========

No resources found in kube-system namespace.
````

成功版
```
$ sudo /usr/local/bin/install_ovs.sh ocp ocp.nwdiamanti.local

Using ssh key ~/.ssh/id_rsa


Install Diamanti CNI to Openshift cluster


Get master node details.

etcd-0.ocp.nwdiamanti.local
etcd-2.ocp.nwdiamanti.local
master1.nwdiamanti.local

Load OVS images on all Master Nodes.

etcd-0.ocp.nwdiamanti.local
etcd-2.ocp.nwdiamanti.local
master1.nwdiamanti.local
Remove existing docker images from core@etcd-0.ocp.nwdiamanti.local

Copy OVS docker images to core@etcd-0.ocp.nwdiamanti.local

Load OVS docker image on core@etcd-0.ocp.nwdiamanti.local
Remove existing docker images from core@etcd-2.ocp.nwdiamanti.local
Warning: Permanently added 'etcd-2.ocp.nwdiamanti.local,172.18.0.43' (ECDSA) to the list of known hosts.

Copy OVS docker images to core@etcd-2.ocp.nwdiamanti.local

Load OVS docker image on core@etcd-2.ocp.nwdiamanti.local
Remove existing docker images from core@master1.nwdiamanti.local
Warning: Permanently added 'master1.nwdiamanti.local,172.18.0.42' (ECDSA) to the list of known hosts.

Copy OVS docker images to core@master1.nwdiamanti.local

Load OVS docker image on core@master1.nwdiamanti.local

Get etcd endpoint list.

172.18.0.41
172.18.0.43
172.18.0.42

Replace all etcd endpoint to OVS daemonset.

Flag --export has been deprecated, This flag is deprecated and will be removed in future.

Create etcd-client CA cert configmap

Flag --export has been deprecated, This flag is deprecated and will be removed in future.

Create etcd-client tls cert and key secrets


Update Cluster Network CRD status.


========== Creating Diamanti OVS daemonset ==========

Running

Diamanti OVS pod dcx-ovs-daemon-2vw9p in Running state

Running

Diamanti OVS pod dcx-ovs-daemon-bvqxl in Running state

Running

Diamanti OVS pod dcx-ovs-daemon-mdbsm in Running state
```

- SSHの秘密鍵、公開鍵について  
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
ssh -i ~/.ssh/core_id_rsa core@master0.nwdiamanti.local
ssh -i ~/.ssh/core_id_rsa core@master1.nwdiamanti.local
ssh -i ~/.ssh/core_id_rsa core@master3.nwdiamanti.local
ssh -i ~/.ssh/core_id_rsa diamanti1.nwdiamanti.local
ssh -i ~/.ssh/core_id_rsa diamanti2.nwdiamanti.local
ssh -i ~/.ssh/core_id_rsa diamanti3.nwdiamanti.local
ssh -i ~/.ssh/core_id_rsa diamanti4.nwdiamanti.local
```



Can you please do the following:

sudo dstool -c "ifconfig eth0 169.254.100.2 netmask 255.255.255.0"

sudo rpm -e diamanti-ocx

sudo rpm -ivh diamanti-ocx-3.0.0-72.x86_64.rpm








