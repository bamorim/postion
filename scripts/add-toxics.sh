#!/bin/sh

toxiproxy-cli toxic add -t latency -a latency=2 -a jitter=1 postgres
toxiproxy-cli toxic add -t latency -a latency=2 -a jitter=1 extsvc