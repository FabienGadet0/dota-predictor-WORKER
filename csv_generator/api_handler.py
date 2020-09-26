import os
# from logger import log
import requests
import time
from logger import log

URL = 'https://api.opendota.com/api/'


class Api_handler():
    def __init__(self, api_type):
        self.api_type = api_type

    def generate_data(self):
        pass

    def raw_query(self, query, mute=False, retry=0, to_json=True):
        if not mute:
            print(f"Querying {URL}{query}")
        try:
            r = requests.get(f"{URL}{query}")
        except requests.exceptions.RequestException as e:
            log('ERROR', f"Error querying :{e}")
        finally:
            if r.status_code == 200:
                retry = 0
                if to_json:
                    return r.json()
                else:
                    return r.text
            elif retry < 3 and r.status_code not in [404, 500]:
                log('INFO',
                    f"Status code {r.status_code} = {r.content} retrying in 50 secs")
                time.sleep(50)
                self.raw_query(query, mute, retry+1)
            else:
                log('ERROR', f"Status code {r.status_code} = {r.content}")
                return [{}]

    def exec_query(self, mute=False, additional='', to_json=True):
        return self.raw_query(f"{self.api_type}{additional}", mute=mute, to_json=to_json)
