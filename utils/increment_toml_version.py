import toml
import argparse
import re

def increment_version_in_toml(toml_file_path, part_to_increment='patch'):
    """
    Reads a TOML file, increments the specified part of the "version" field,
    and writes the changes back to the file. Handles versions with user suffixes.

    Args:
        toml_file_path (str): The path to the TOML file to be modified.
        part_to_increment (str): The part of the version to increment ('major', 'minor', or 'patch').
                                 Defaults to 'patch'.
                                 
    Example:
        python increment_toml_version.py path/to/your/file.toml 
        python increment_toml_version.py path/to/your/file.toml --part minor
    """

    # Read the TOML file
    with open(toml_file_path, 'r') as f:
        data = toml.load(f)

    # Get the "version" field and validate its format
    if 'tool' in data and 'poetry' in data['tool'] and 'version' in data['tool']['poetry']:
        version_str = data['tool']['poetry']['version']

        # Remove any existing user suffix
        version_str = version_str.split('+')[0]

        # Use regular expressions to match different version formats
        match = re.match(r'^(\d+)\.(\d+)(?:\.(\d+))?', version_str)
        if not match:
            raise ValueError(f"Invalid version format: {version_str}")

        major, minor, patch = match.groups()
        patch = patch or '0'  # Handle the case where patch is not present

        # Increment the specified part of the version
        if part_to_increment == 'major':
            major = str(int(major) + 1)
            minor = '0'
            patch = '0'
        elif part_to_increment == 'minor':
            minor = str(int(minor) + 1)
            patch = '0'
        elif part_to_increment == 'patch':
            patch = str(int(patch) + 1)
        else:
            raise ValueError(f"Invalid part to increment: {part_to_increment}")

        # Update the "version" field (without any user suffix)
        data['tool']['poetry']['version'] = f"{major}.{minor}.{patch}"

    else:
        print(f"Warning: 'version' field not found in {toml_file_path}")

    # Write the modified data back to the TOML file
    with open(toml_file_path, 'w') as f:
        toml.dump(data, f)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Increment version in a TOML file.')
    parser.add_argument('toml_file', help='Path to the TOML file')
    parser.add_argument('--part', choices=['major', 'minor', 'patch'], default='patch',
                        help='Part of the version to increment')
    args = parser.parse_args()

    increment_version_in_toml(args.toml_file, args.part)