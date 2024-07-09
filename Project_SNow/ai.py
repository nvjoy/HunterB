 
import torch  
from transformers import AutoModelForSequenceClassification, AutoTokenizer  
from sklearn.preprocessing import LabelEncoder  
  
# Load pre-trained model and tokenizer  
model_name = "distilbert-base-uncased"  
model = AutoModelForSequenceClassification.from_pretrained(model_name, num_labels=8)  
tokenizer = AutoTokenizer.from_pretrained(model_name)  
  
# Load label encoder  
le = LabelEncoder()  
labels = ["CPU_USAGE_HIGH", "MEMORY_USAGE_HIGH", "DISK_USAGE_HIGH", "NETWORK_OUTAGE", "APPLICATION_ERROR", "DATABASE_ERROR", "SECURITY_BREACH", "OTHER"]  
le.fit(labels)  
  
# Define API endpoint  
@app.route("/incident_detection", methods=["POST"])  
def detect_incident():  
    # Get event data from request  
    event_data = request.get_json()  
    event_type = event_data["event_type"]  
    resource = event_data["resource"]  
    value = event_data["value"]  
    timestamp = event_data["timestamp"]  
  
    # Preprocess event data  
    input_text = f"{event_type} on {resource} with value {value} at {timestamp}"  
    inputs = tokenizer.encode_plus(  
        input_text,  
        add_special_tokens=True,  
        max_length=512,  
        return_attention_mask=True,  
        return_tensors="pt"  
    )  
  
    # Create tensor dataset  
    dataset = torch.utils.data.TensorDataset(inputs["input_ids"], inputs["attention_mask"])  
  
    # Create data loader  
    data_loader = torch.utils.data.DataLoader(dataset, batch_size=1, shuffle=False)  
  
    # Evaluate model  
    model.eval()  
    with torch.no_grad():  
        outputs = model(**data_loader)  
  
    # Get predicted label  
    logits = outputs.logits  
    _, predicted = torch.max(logits, dim=1)  
    predicted_label = le.inverse_transform(predicted.item())  
  
    # Create incident data  
    incident_data = {  
        "incident_detected": True,  
        "incident_description": f"Detected {predicted_label} on {resource}",  
        "incident_details": input_text,  
        "priority": get_priority(predicted_label),  
        "severity": get_severity(predicted_label),  
        "category": get_category(predicted_label),  
        "subcategory": get_subcategory(predicted_label),  
        "assignment_group": get_assignment_group(predicted_label)  
    }  
  
    return jsonify(incident_data)  
  
def get_priority(label):  
    # Define priority mapping  
    priority_mapping = {  
        "CPU_USAGE_HIGH": "High",  
        "MEMORY_USAGE_HIGH": "High",  
        "DISK_USAGE_HIGH": "Medium",  
        "NETWORK_OUTAGE": "Critical",  
        "APPLICATION_ERROR": "High",  
        "DATABASE_ERROR": "Critical",  
        "SECURITY_BREACH": "Critical",  
        "OTHER": "Low"  
    }  
    return priority_mapping[label]  
  
def get_severity(label):  
    # Define severity mapping  
    severity_mapping = {  
        "CPU_USAGE_HIGH": "Major",  
        "MEMORY_USAGE_HIGH": "Major",  
        "DISK_USAGE_HIGH": "Minor",  
        "NETWORK_OUTAGE": "Critical",  
        "APPLICATION_ERROR": "Major",  
        "DATABASE_ERROR": "Critical",  
        "SECURITY_BREACH": "Critical",  
        "OTHER": "Minor"  
    }  
    return severity_mapping[label]  
  
def get_category(label):  
    # Define category mapping  
    category_mapping = {  
        "CPU_USAGE_HIGH": "Infrastructure",  
        "MEMORY_USAGE_HIGH": "Infrastructure",  
        "DISK_USAGE_HIGH": "Infrastructure",  
        "NETWORK_OUTAGE": "Network",  
        "APPLICATION_ERROR": "Application",  
        "DATABASE_ERROR": "Database",  
        "SECURITY_BREACH": "Security",  
        "OTHER": "Other"  
    }  
    return category_mapping[label]  
  
def get_subcategory(label):  
    # Define subcategory mapping  
    subcategory_mapping = {  
        "CPU_USAGE_HIGH": "Server",  
        "MEMORY_USAGE_HIGH": "Server",  
        "DISK_USAGE_HIGH": "Storage",  
        "NETWORK_OUTAGE": "Network Connectivity",  
        "APPLICATION_ERROR": "Application Logic",  
        "DATABASE_ERROR": "Database Query",  
        "SECURITY_BREACH": "Unauthorized Access",  
        "OTHER": "Unknown"  
    }  
    return subcategory_mapping[label]  
  
def get_assignment_group(label):  
    # Define assignment group mapping  
    assignment_group_mapping = {  
        "CPU_USAGE_HIGH": "Server Team",  
        "MEMORY_USAGE_HIGH": "Server Team",  
        "DISK_USAGE_HIGH": "Storage Team",  
        "NETWORK_OUTAGE": "Network Team",  
        "APPLICATION_ERROR": "Application Team",  
        "DATABASE_ERROR": "Database Team",  
        "SECURITY_BREACH": "Security Team",  
        "OTHER": "IT Support"  
    }  
    return assignment_group_mapping[label]