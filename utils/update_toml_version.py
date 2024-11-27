import toml
import os
import re

def update_version_in_toml(toml_file_path):
    """
    Reads a TOML file, updates the "version" field by appending "+USER"
    where USER is an environment variable, and writes the changes back to the file.

    Args:
        toml_file_path (str): The path to the TOML file to be modified.
        
    Example usage: python update_toml_version.py path/to/your/file.toml
    """
    # Read the TOML file
    with open(toml_file_path, 'r') as f:
        data = toml.load(f)

    # Get the USER environment variable
    user = os.environ.get('USER')
    if not user:
        raise ValueError("The 'USER' environment variable is not set.")

    # Update the "version" field, using regex to find the numerical part
    if 'tool' in data and 'poetry' in data['tool'] and 'version' in data['tool']['poetry']:
        version_str = data['tool']['poetry']['version']
        match = re.match(r'^(\d+\.\d+\.\d+)', version_str)  # Match only the numerical part
        if match:
            numerical_version = match.group(1)
            data['tool']['poetry']['version'] = f"{numerical_version}+{user}"
        else:
            print(f"Warning: Invalid version format in {toml_file_path}")
    else:
        print(f"Warning: 'version' field not found in {toml_file_path}")

    # Write the modified data back to the TOML file
    with open(toml_file_path, 'w') as f:
        toml.dump(data, f)

if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='Update version in a TOML file.')
    parser.add_argument('toml_file', help='Path to the TOML file')
    args = parser.parse_args()

    update_version_in_toml(args.toml_file)