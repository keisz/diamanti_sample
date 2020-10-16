# Static volume provisioning

- Provision a static volume using following dctl command:

```
VolumeMode: Block
$ dctl volume create pvc-block-static -b -s 5Gi

VolumeMode: Filesystem
$ dctl volume create pvc-filesystem-static -s 5Gi
```

- Create PersistentVolumeClaim for volumeMode as raw block device using following command:

```
$ kubectl create -f pvc-block-static.yaml
```

- Create PersistentVolumeClaim for volumeMode as filesystem using following command:

```
$ kubectl create -f pvc-filesystem-static.yaml
```

