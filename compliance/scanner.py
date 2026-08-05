import json 
import subprocess

def get_resources():
    command = ["az", "resource", "list"]
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error running az command: {result.stderr}")
        return []
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError:
        print("Error parsing JSON response")
        return []