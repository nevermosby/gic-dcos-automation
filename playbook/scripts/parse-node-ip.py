import json
import sys
from pprint import pprint

jdata = sys.stdin.read()
data = json.loads(jdata)

prefix="dcos-node"
boot_node_name=prefix+"001"

m_a_node=[]
m_node=[]
a_node=[]

for vm in data["data"][0]["vms"]:
    vm_name = vm["name"]
    #print vm_name
    if prefix in vm_name and vm_name != boot_node_name:
        # find the target node list
        for netcard in vm["netcard"]:
            if netcard["type"] == "private":
                #print netcard["ip"]
                m_a_node.append(netcard["ip"])

m_a_node.sort()
m_node=m_a_node[:1]
n_node=m_a_node[1:]

#print "master node", m_node
#print "agent node", n_node

print json.dumps({"master_node": m_node, "agent_node": n_node})

#print m_a_node
#for node in m_a_node:
#    print node

