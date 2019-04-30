#!/usr/bin/env python
"""
Update the IP of the classic load balancer automatically
"""
import socket
import sys
import os
import logging
import time

logger = logging.getLogger("update-clb-ip")
logger.setLevel(logging.INFO)
ch = logging.StreamHandler()
fmt = logging.Formatter('%(levelname)s - %(asctime)s - %(message)s')
ch.setFormatter(fmt)
logger.addHandler(ch)

def backup(hosts):
    timenow = time.strftime("%c")
    timestamp = "Backup occured %s \n" % timenow
    logger.info("Backing up hosts file to /etc/hosts.back ...")
    with open('/etc/hosts.back', 'a+') as f:
        f.write(timestamp)
        for line in hosts:
            f.write(line)


def get_hosts(LB_ADDR, DOMAIN):
    ip_list = []
    hosts_list = []
    ais = socket.getaddrinfo(LB_ADDR, 0, 0, 0, 0)
    for result in ais:
        ip_list.append(result[-1][0])
    ip_list = list(set(ip_list))
    for ip in ip_list:
        add_host = ip + " " + DOMAIN
        hosts_list.append(add_host)

    return hosts_list


def main():
    try:
        while True:
            LB_ADDR = os.environ.get("LB_ADDR", "")
            DOMAIN = os.environ.get("DOMAIN", "kube.gluu.local")
            host_file = open('/etc/hosts', 'r').readlines()
            hosts = get_hosts(LB_ADDR, DOMAIN)
            stop = []
            for host in hosts:
                for i in host_file:
                    if host.replace(" ", "") in i.replace(" ", ""):
                        stop.append("found")
            if len(stop) != len(hosts):
                backup(host_file)
                logger.info("Writing new hosts file")
                with open('/etc/hosts', 'w') as f:
                    for line in host_file:
                        if DOMAIN not in line:
                            f.write(line)
                    for host in hosts:
                        f.write(host)
                    f.write("\n")
            time.sleep(300)
    except KeyboardInterrupt:
        logger.warn("Canceled by user; exiting ...")


if __name__ == "__main__":
    main()
