#!/usr/bin/env bash

if [ -z ${K8S_VERSION+x} ]; then
  K8S_VERSION=1.28.1-00
fi

# Hack DNS if not responding
host -4 www.google.com | grep -i failed >/dev/null || {
  NAMESERVER=192.168.121.1
  grep -q  nameserver /etc/resolv.conf && sed -i_bak "s/\(nameserver\) .*/\1 $NAMESERVER/" /etc/resolv.conf || echo "nameserver $NAMESERVER" >> /etc/resolv.conf
}

apt-get update && apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb  http://apt.kubernetes.io/  kubernetes-xenial  main" > /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"
apt-get update
apt-get install -y \
  avahi-daemon \
  libnss-mdns \
  traceroute \
  htop \
  httpie \
  bash-completion \
  docker-ce \
  kubeadm=$K8S_VERSION \
  kubelet=$K8S_VERSION \
  kubectl=$K8S_VERSION
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

systemctl daemon-reload
systemctl restart docker

# Set alias for kubectl command
echo "alias k=kubectl" >> /home/vagrant/.bashrc
swapoff -a
kubectl completion bash | tee /etc/bash_completion.d/kubectl > .dev.null
echo 'complete -o default -F __start_kubectl k' >>/home/vagrant/.bashrc
