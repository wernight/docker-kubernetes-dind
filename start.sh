#!/bin/sh -e

# Start Docker daemon
dockerd-entrypoint.sh --registry-mirror=http://registry_mirror:5000 &
sleep 3

# Start Kubernetes
docker run -d --name=etcd --net=host gcr.io/google_containers/etcd:2.0.13 \
    /usr/local/bin/etcd --addr=127.0.0.1:4001 --bind-addr=0.0.0.0:4001 --data-dir=/var/etcd/data
docker run -d --name=master --net=host -v /var/run/docker.sock:/var/run/docker.sock gcr.io/google_containers/hyperkube:v1.0.7 \
    /hyperkube kubelet --api_servers=http://localhost:8080 --v=2 --address=0.0.0.0 --enable_server --hostname_override=127.0.0.1 --config=/etc/kubernetes/manifests
docker run -d --name=proxy --net=host --privileged gcr.io/google_containers/hyperkube:v1.0.7 \
    /hyperkube proxy --master=http://127.0.0.1:8080 --v=2

# Start Docker Registry
docker run --name registry -p 5000:5000 registry:2
