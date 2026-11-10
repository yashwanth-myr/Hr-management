import os
import json

# Path to the input JSON file
input_file = './code.json'  # or code.txt if that's the correct file

# Get the current working directory
base_dir = os.getcwd()

# Read and parse the JSON
with open(input_file, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Create files and directories based on JSON structure
for relative_path, file_info in data.items():
    if not file_info.get("active", False):
        continue

    # Strip leading slashes to avoid writing to root
    relative_path = relative_path.lstrip("/")

    # Construct full file path
    file_path = os.path.join(base_dir, relative_path)

    # Get the code content
    code_content = file_info.get("code", "")

    # Ensure the directory exists
    dir_path = os.path.dirname(file_path)
    if dir_path:
        os.makedirs(dir_path, exist_ok=True)

    # Write the file
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(code_content)

    print(f"Created: {file_path}")

