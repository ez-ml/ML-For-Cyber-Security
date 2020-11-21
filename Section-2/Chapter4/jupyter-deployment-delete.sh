#!/usr/bin/env bash
kubectl delete deployment jupyter-lab
kubectl delete service jupyter-lab
kubectl delete service jupyter-headless
kubectl delete service jupyter-lb
kubectl delete serviceaccount spark-driver
kubectl delete rolebinding spark-driver-rb