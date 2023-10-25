#!/bin/sh

toxiproxy-cli toxic delete -n latency_downstream postgres
toxiproxy-cli toxic delete -n latency_downstream extsvc