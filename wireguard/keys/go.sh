#!/bin/bash

set -xe
musr="${1:-default}"
( umask 077; wg genkey > ${musr}.key )
wg pubkey < ${musr}.key > ${musr}.pub

echo OK
