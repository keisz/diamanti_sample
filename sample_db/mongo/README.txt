NOTE:

For mongo to form a replicaSet, Please execute the following on any of the mongo instances:

kubectl exec -ti <PODNAME> -- mongo --eval "JSON.stringify(db.adminCommand({'replSetInitiate' : {_id : 'ycsbrs', members: [{ _id : 0, host : 'test-svc-mongo-1:27017', priority: 1 },{ _id : 1, host : 'test-svc-mongo-2:27017', priority: 0.5 },{ _id : 2, host : 'test-svc-mongo-3:27017', priority: 0.5 }]}}))"
