#!/usr/bin/env python3
import docker
import json
import sys
import dns


tsigfile = 'secrets.json'
client = docker.Client()
tsighandle = open(tsigfile, mode='r')
keyring = dns.tsigkeyring.from_text(json.load(tsighandle))
tsighandle.close()


def startup():
    containers = []

    for container in client.containers():
        container_id = container["Id"]
        inspect = client.inspect_container(container_id)
        container_hostname = inspect["Config"]["Hostname"]
        container_name = inspect["Name"].split('/', 1)[1]
        networkmode = str(inspect["HostConfig"]["NetworkMode"])
        # and (str(networkmode) != 'default')):
        if ((str(networkmode) != 'host') and 'container:' not in networkmode):
            if (str(networkmode) != 'default'):
                container_ip = container["NetworkSettings"][
                    "Networks"][networkmode]["IPAddress"]
            else:
                container_ip = container["NetworkSettings"][
                    "Networks"]["bridge"]["IPAddress"]
        event_data = {container['Id']: {
            "status": "running",
            "name": container_name,
            "Hostname": container_hostname,
            "from": container['Image'],
            "time": container['Created'],
            "ipAddr": container_ip}}

        containers.append(event_data)
    return json.dumps(containers)


def container_info(containerId):
    container = {}
    print(containerId)
    inspect = client.inspect_container(containerId)
    networkmode = str(inspect["HostConfig"]["NetworkMode"])
    container['name'] = inspect["Name"].split('/', 1)[1]
    if ((str(networkmode) != 'host') and 'container:' not in networkmode):
        if (str(networkmode) != 'default'):
            container['ip'] = inspect["NetworkSettings"][
                "Networks"][networkmode]["IPAddress"]
        else:
            container['ip'] = inspect["NetworkSettings"][
                "Networks"]["bridge"]["IPAddress"]
    else:
        container['ip'] = '0.0.0.0'
    container['hostname'] = inspect["Config"]["Hostname"]
    return container


def dockerddns(action, event, dnsserver, ttl):
    update = dns.update.Update('i.bartsch.cl.', keyring=keyring)
    update.replace(event['hostname'], ttl, 'A', event['ip'])
    response = dns.query.tcp(update, dnsserver, timeout=10)
    print(response)
    print("hello")


def process():
    containerinfo = {}
    events = client.events(decode=True)
    for event in events:
        if event['Type'] == "container":
            if event['Action'] == 'start':
                containerinfo = container_info(event['id'])
                print(containerinfo)
                print("Container %s is starting with hostname %s and ipAddr %s"
                      % (containerinfo['name'],
                         containerinfo['hostname'], containerinfo['ip']))
            elif event['Action'] == 'die':
                containerinfo = container_info(event['id'])
                print(containerinfo)
                print("Container %s is stopping %s" %
                      (containerinfo['name'],
                       containerinfo['hostname']))

print(startup())
try:
    process()
except KeyboardInterrupt:
    print("Bye")
    sys.exit()
