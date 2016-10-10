import docker
import docker_events
import json
import sys


client = docker.Client()

def startup():
  containers = []

  for container in client.containers():
    container_id = container["Id"]
    inspect=client.inspect_container(container_id)
    container_hostname = inspect["Config"]["Hostname"]
    container_name = inspect["Name"].split('/', 1)[1]
    networkmode=str(inspect["HostConfig"]["NetworkMode"])
    if ((str(networkmode) != 'host') and 'container:' not in networkmode): # and (str(networkmode) != 'default')):
      if (str(networkmode) != 'default'):
        container_ip = container["NetworkSettings"]["Networks"][networkmode]["IPAddress"]
      else:
        container_ip = container["NetworkSettings"]["Networks"]["bridge"]["IPAddress"]
      #print("Updating %s to ip (%s|%s|%s) -> %s" % (container_id, container_hostname, container_name, networkmode, container_ip))
    event_data = { container['Id']: {
           "status": "running",
           "Hostname": container_hostname,
           "from": container['Image'],
           "time": container['Created'],
           "ipAddr": container_ip }}
         
    containers.append(event_data)
  return json.dumps(containers)

def container_info(containerId): 
    container={}
    print(containerId)
    inspect=client.inspect_container(containerId)
    networkmode=str(inspect["HostConfig"]["NetworkMode"])
    container['name'] = inspect["Name"].split('/', 1)[1]
    if ((str(networkmode) != 'host') and 'container:' not in networkmode): 
        if (str(networkmode) != 'default'): 
            container['ip'] = inspect["NetworkSettings"]["Networks"][networkmode]["IPAddress"] 
        else: 
            container['ip'] = inspect["NetworkSettings"]["Networks"]["bridge"]["IPAddress"]
    else:
        container['ip']='0.0.0.0'
    container['hostname'] = inspect["Config"]["Hostname"]
    return container


	
def process():
    containerinfo={}
    events = client.events(decode=True)
    for event in events:
        if event['Type'] == "container":
            if event['Action'] == 'start':
                containerinfo=container_info(event['id'])
                print(containerinfo)
                print("Container %s is starting with hostname %s and ipAddr %s" % (containerinfo['name'],
                    containerinfo['hostname'],containerinfo['ip']))
            elif event['Action'] == 'die':
                containerinfo=container_info(event['id'])
                print(containerinfo)
                print("Container %s is stopped %s" % (containerinfo['name'],
                    containerinfo['hostname']))

print(startup())
try: 
    process()
except KeyboardInterrupt:
    print("Bye")
    sys.exit()
