#!/usr/bin/env python

import requests
import json
import subprocess

all_csrs = requests.get('http://localhost:8080/apis/certificates.k8s.io/v1beta1/certificatesigningrequests')
all_csrs.raise_for_status()

all_csrs_obj = json.loads(all_csrs.content)

for item in all_csrs_obj['items']:
    if 'conditions' in item['status']:
        print(item['status']['conditions'][0]['type'])
    else:
        cert_req = item['metadata']['name']
        print("Running: kubectl certificate approve {}".format(cert_req))
        subprocess.Popen("kubectl certificate approve {}".format(cert_req), shell=True)



