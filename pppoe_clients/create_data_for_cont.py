#!/usr/bin/python3


import mysql.connector
import sys
import os



docker_compose_config = open("/usr/local/docker/pppoe_clients/docker-compose-all.yaml", "w")
docker_compose_config.write("version: \"3\"\nservices:\n")

print("Start script")
cnx = mysql.connector.connect(user="abills", database="abills", password="abills",  host="172.19.0.1")
print("Create mysql auth data for cursor")

cur = cnx.cursor()





print("Def start....")



def create_users_data(user_pattern):
    print(user_pattern)
    query = "select id from users where id like \"{0}%\";".format(user_pattern)
    cur.execute(query)
    output = cur.fetchall()
    for login in output:
        path = "/usr/local/docker/pppoe_clients/clients_conf/" + login[0]
        if not os.path.exists(path):
            os.mkdir(path)
        chap_secret = path + "/chap-secret"
        f = open(chap_secret, "w")
        f.write("\"{0}\"\t*\t\"000000\"\n".format(login[0]))
        f.close()
        dsl_provider = path + "/dsl-provider"
        f = open(dsl_provider, "w")
        f.write("{}\n{}\n{}\n{}\n{}\n{}\n{}\n{}\n{}\n{}\n".format("noipdefault", "defaultroute" , "replacedefaultroute", "replacedefaultroute", "noauth", "persist", "plugin rp-pppoe.so", "nic-eth0", "nic-eno1", "user \"" + login[0] + '"'))
        f.close()
        docker_compose_config.write("    pppoe_client_{0}:\n        build:\n            context: ./\n        privileged: true\n        volumes:\n            - /usr/local/docker/pppoe_clients/clients_conf/{0}/chap-secret:/etc/ppp/chap-secret\n            - /usr/local/docker/pppoe_clients/clients_conf/{0}/dsl-provider:/etc/ppp/peers/dsl-provider\n".format(login[0]))

create_users_data("ned")
docker_compose_config.close()
