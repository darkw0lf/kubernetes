#!/bin/bash

kubectl get nodes -o wide
kubectl get pods -A -o wide
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
kubectl get pods -n kube-system -o wide

#sudo kubeadm token create --print-join-command

kubectl get nodes -o wide
kubectl run my-pod --image=nginx --port=80
kubectl get pods -o wide
