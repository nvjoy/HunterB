import requests
from requests.auth import HTTPBasicAuth

SN_INSTANCE = "https://dev276210.service-now.com"
SN_USER = "admin"
SN_PASS = "Jv67JqK^xEv@"

def create_incident(short_description, description):
    
    url = f"{SN_INSTANCE}/api/now/table/incident"
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json"
    }
    data = {
        "short_description": "This is my first incident",
        "description": "This is my first incident description"
    }
    
    response = requests.post(url, auth=HTTPBasicAuth(SN_USER, SN_PASS), headers=headers, json=data)
    
    if response.status_code == 201:
        print("Incident created successfully.")
        print("Response:", response.json())
    else:
        print("Failed to create incident.")
        print("Response:", response.text)

# Example usage
short_description = "Example Incident"
description = "This is an example incident created via Python script."

create_incident(short_description, description)

def update_incident_work_notes(incident_sys_id, work_notes):
    
    url = f"{SN_INSTANCE}/api/now/table/incident/{incident_sys_id}"
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json"
    }
    data = {
        "work_notes": work_notes
    }
    
    response = requests.patch(url, auth=HTTPBasicAuth(SN_USER, SN_PASS), headers=headers, json=data)
    
    if response.status_code == 200:
        print("Incident work notes updated successfully.")
        print("Response:", response.json())
    else:
        print("Failed to update incident work notes.")
        print("Response:", response.text)

# Example usage
incident_sys_id = "182dd59a838f0210e037f120feaad3a5"
work_notes = "These are the updated work notes for the incident."

update_incident_work_notes(incident_sys_id, work_notes)

