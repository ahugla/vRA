#!/bin/bash
#SOURCE : https://mapr.com/blog/making-data-actionable-at-scale-part-2-of-3/

# ALEX H.
# 16 Mai 2018
# v1.4

# USAGE
# -----
# fichierSRC=K8S-prepare.sh
# cd /tmp
# curl -O https://raw.githubusercontent.com/ahugla/vRA/master/SoftwareComponents/Kubernetes-kubeadm/$fichierSRC
# chmod 755 $fichierSRC
# ./$fichierSRC
# rm -f $fichierSRC


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


# Install docker
yum install -y docker

# Launch Docker and enable it on system boot
systemctl start docker
systemctl enable docker


# Install kubernetes repo
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# Install Kubernetes and start it
yum install -y kubelet kubeadm kubectl
systemctl start kubelet
systemctl enable kubelet
