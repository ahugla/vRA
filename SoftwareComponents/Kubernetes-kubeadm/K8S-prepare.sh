#!/bin/bash
#SOURCE : https://mapr.com/blog/making-data-actionable-at-scale-part-2-of-3/

# ALEX H.
# 21 Janvier 2019
# v1.7

# USAGE
# -----
# CONFIGURER LE REBOOT DANS LE SOFTWARE COMPONENT
#
# fichierSRC=K8S-prepare.sh
# cd /tmp
# curl -O https://raw.githubusercontent.com/ahugla/vRA/master/SoftwareComponents/Kubernetes-kubeadm/$fichierSRC
# chmod 755 $fichierSRC
# ./$fichierSRC
# rm -f $fichierSRC


# Log $PATH
echo "Intial PATH = $PATH"

# Update PATH
export PATH=$PATH:/usr/local/sbin:/usr/sbin:/root/bin
echo "New PATH = $PATH"


# Disable SELinux
setenforce 0
sed -i '/^SELINUX./ { s/enforcing/disabled/; }' /etc/selinux/config

# Disable memory swapping
swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab


# Enable bridged networking
# Set iptables
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system


# Install docker : based on "https://kubernetes.io/docs/setup/cri/"
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
yum update -y 
yum install -y docker-ce-18.06.1.ce
mkdir /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF
mkdir -p /etc/systemd/system/docker.service.d
systemctl daemon-reload
systemctl restart docker
systemctl enable docker


# Install kubernetes repo comme indiqué: "https://kubernetes.io/docs/setup/independent/install-kubeadm/"
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF


# Install Kubernetes and start it
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl start kubelet
systemctl enable kubelet


yum update -y

# CONFIGURER LE REBOOT DANS LE SOFTWARE COMPONENT