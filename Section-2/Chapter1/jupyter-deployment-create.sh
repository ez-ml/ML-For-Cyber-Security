#!/usr/bin/env bash
kubectl create serviceaccount spark-driver
kubectl create rolebinding spark-driver-rb --clusterrole=cluster-admin --serviceaccount=default:spark-driver
kubectl apply -f jupyter-deployment.yaml