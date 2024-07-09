 
import requests  
import json  
  
# ServiceNow API credentials  
snow_username = "your_username"  
snow_password = "your_password"  
snow_instance = "your_instance"  
  
# Generative AI model API endpoint  
ai_endpoint = "https://your_ai_endpoint.com/incident_detection"  
  
# Incident detection function  
def detect_incident(event_data):  
    # Call Generative AI model API to detect incident  
    response = requests.post(ai_endpoint, json=event_data)  
    if response.status_code == 200:  
        incident_data = response.json()  
        if incident_data["incident_detected"]:  
            # Create incident ticket in ServiceNow  
            create_incident_ticket(incident_data)  
        else:  
            print("No incident detected")  
    else:  
        print("Error calling AI model API")  
  
# Create incident ticket function  
def create_incident_ticket(incident_data):  
    # Set up ServiceNow API connection  
    snow_url = f"https://{snow_instance}.service-now.com/api/now/table/incident"  
    auth = (snow_username, snow_password)  
    headers = {"Content-Type": "application/json"}  
  
    # Create incident ticket payload  
    payload = {  
        "short_description": incident_data["incident_description"],  
        "description": incident_data["incident_details"],  
        "priority": incident_data["priority"],  
        "severity": incident_data["severity"],  
        "category": incident_data["category"],  
        "subcategory": incident_data["subcategory"],  
        "assignment_group": incident_data["assignment_group"]  
    }  
  
    # Create incident ticket in ServiceNow  
    response = requests.post(snow_url, auth=auth, headers=headers, json=payload)  
    if response.status_code == 201:  
        print("Incident ticket created successfully")  
    else:  
        print("Error creating incident ticket")  
  
# Example event data  
event_data = {  
    "event_type": "CPU_USAGE_HIGH",  
    "resource": "server01",  
    "value": 90,  
    "timestamp": "2023-02-20 14:30:00"  
}  
  
# Call incident detection function  
detect_incident(event_data)