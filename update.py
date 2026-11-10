import re
import os
import sys

def update_files_from_string(input_content):
    """
    Parses a string containing multiple file blocks and updates/creates
    files in the current directory structure.

    Args:
        input_content (str): The string containing file blocks.

    Returns:
        list: A list of paths of the files that were successfully updated/created.
    """
    # Regex to find file blocks: captures path and content
    # <file path="<path>"><content></file>
    # path = group 1, content = group 2
    # [\s\S]*? makes it non-greedy and matches across newlines
    # We also strip leading/trailing whitespace around the content itself later
    file_pattern = re.compile(r'<file path="([^"]+)">([\s\S]*?)</file>')

    # Find all file blocks in the input content
    matches = file_pattern.finditer(input_content)

    updated_files = []
    for match in matches:
        raw_path = match.group(1).strip()
        # Strip leading/trailing whitespace/newlines from the captured content block
        content = match.group(2).strip()

        if not raw_path:
            print("Warning: Found a file block with an empty path. Skipping.")
            continue

        # Make path relative to the current directory by removing any leading '/'
        relative_path = raw_path.lstrip('/')

        # Ensure the path is not empty after stripping
        if not relative_path:
             print(f"Warning: Path '{raw_path}' became empty after stripping leading '/'. Skipping.")
             continue

        # Replace potential backslashes with forward slashes for consistency
        # and then use os.path.normpath for OS compatibility
        relative_path = os.path.normpath(relative_path.replace("\\", "/"))

        print(f"Processing path: {relative_path}")

        try:
            # Get the directory part of the path
            dir_path = os.path.dirname(relative_path)

            # Create parent directories if they don't exist
            if dir_path:
                os.makedirs(dir_path, exist_ok=True)
                # print(f"  Ensured directory exists: {dir_path}") # Optional: uncomment for more verbose output

            # Write the content to the file (overwrite if exists)
            with open(relative_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"  Successfully updated file: {relative_path}")
            updated_files.append(relative_path)

        except OSError as e:
            print(f"Error processing file '{relative_path}': {e}", file=sys.stderr)
        except Exception as e:
             print(f"An unexpected error occurred for file '{relative_path}': {e}", file=sys.stderr)

    return updated_files

def main():
    """
    Main function to handle command-line arguments and file reading.
    """
    # if len(sys.argv) != 2:
    #     print(f"Usage: python {sys.argv[0]} <input_filename>")
    #     sys.exit(1)

    input_filename = "code_input.txt"

    try:
        print(f"Reading input from file: {input_filename}")
        with open(input_filename, 'r', encoding='utf-8') as f:
            file_content = f.read()
    except FileNotFoundError:
        print(f"Error: Input file '{input_filename}' not found.", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error reading input file '{input_filename}': {e}", file=sys.stderr)
        sys.exit(1)

    # Optional: Remove the outer <start_code> tag if it exists, handling potential whitespace
    # Find the first '>' after '<start_code>' to handle potential attributes or whitespace
    start_code_match = re.search(r'<start_code.*?>', file_content, re.IGNORECASE | re.DOTALL)
    if start_code_match:
        file_content = file_content[start_code_match.end():]
        print("Removed leading <start_code> tag.")


    print(f"\nStarting file update process from '{input_filename}'...")
    updated = update_files_from_string(file_content)

    if updated:
        print("\nFile update process completed.")
        print(f"Updated/Created {len(updated)} file(s):")
        #for fname in updated: # Use this for simple list
        #    print(f"- {fname}")
        # Use this for a more structured output, especially with deeper paths
        for root, dirs, files in os.walk('.'):
            for file in files:
                full_path = os.path.join(root, file)
                # Normalize path for comparison
                norm_full_path = os.path.normpath(full_path)
                if norm_full_path in updated:
                     print(f"- {norm_full_path}")

    else:
        print("\nFile update process completed. No files were found in the input or updated.")

if __name__ == "__main__":
    main()