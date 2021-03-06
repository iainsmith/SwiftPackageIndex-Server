#!/bin/bash
# This command assumes the prod db to be available on port 7432 on localhost, via an ssh tunnel:
# ssh -i <your private key> -L 7432:db:5432 -p 2222 root@173.255.229.82
pg_dump --no-owner -h localhost -p 7432 -U spi_prod spi_prod > spi_prod_$(date +%Y-%m-%d).dump
