import re
import json
import os

def parse_answer_block(answer_string):
    """
    Extracts file paths (keys) from a JSON dictionary embedded within <answer> tags.

    Args:
        answer_string: A string containing the <answer> tag with JSON content.

    Returns:
        A list of file paths (strings) found as keys in the JSON,
        or None if extraction or parsing fails.
    """
    # Be more flexible with whitespace around tags
    match = re.search(r'<answer>(.*?)</answer>', answer_string, re.DOTALL | re.IGNORECASE)
    if not match:
        print("Error: Could not find content within <answer>...</answer> tags.")
        # Attempt to find JSON directly if tags are missing/malformed
        try:
            # Find the first '{' and the last '}' assuming it's the JSON block
            first_brace = answer_string.find('{')
            last_brace = answer_string.rfind('}')
            if first_brace != -1 and last_brace != -1 and last_brace > first_brace:
                json_string = answer_string[first_brace : last_brace + 1].strip()
                print("Warning: Found JSON content outside of expected <answer> tags.")
            else:
                print("Error: No JSON object found in the input string either.")
                return None
        except Exception: # Catch any error during substring search
             print("Error: Could not extract JSON content from input string.")
             return None
    else:
        json_string = match.group(1).strip()

    try:
        data = json.loads(json_string)
        if not isinstance(data, dict):
            print("Error: Content inside <answer> or extracted block is not a valid JSON dictionary.")
            return None
        # Ensure keys are strings
        return [str(key) for key in data.keys()]
    except json.JSONDecodeError as e:
        print(f"Error: Failed to parse JSON content from <answer> block. Details: {e}")
        print(f"Problematic JSON string: {json_string[:200]}...") # Print snippet for debugging
        return None
    except Exception as e:
        print(f"An unexpected error occurred during JSON parsing: {e}")
        return None

def parse_ingest_text(ingest_text):
    """
    Parses the large text blob containing file structures and contents.
    Specifically looks for the ==== File: ==== pattern.

    Args:
        ingest_text: The string content of the ingest.txt file.

    Returns:
        A dictionary where keys are normalized relative file paths and
        values are the corresponding file content strings. Returns None on failure.
    """
    all_files_content = {}
    # Updated regex to specifically match the observed pattern
    # Allows for variable number of '=' (at least 5)
    # Looks for "File:", captures the path until newline
    # Looks for another line of '='
    # Captures everything until the next possible file block or end of string
    block_pattern = re.compile(
        r"^={5,}\nFile:\s*(.*?)\n={5,}\n(.*?)(?=\n={5,}\nFile:|\Z)",
        re.MULTILINE | re.DOTALL
    )

    matches_found = 0
    for match in block_pattern.finditer(ingest_text):
        matches_found += 1
        relative_path = match.group(1).strip()
        content = match.group(2).strip()
        # Normalize path (replace backslashes, remove leading slashes)
        normalized_path = os.path.normpath(relative_path.replace('\\', '/')).lstrip('.\\/')
        all_files_content[normalized_path] = content
        # print(f"Parsed: '{normalized_path}'") # Uncomment for debugging

    if matches_found == 0:
         print("Warning: No file blocks matched the expected pattern in ingest text.")
         print("Expected pattern similar to: ====\\nFile: <path>\\n====\\n<code>")
         # Try a simpler split as a fallback (less reliable)
         print("Attempting fallback split...")
         separator = "================================================" # Use the exact separator length
         try:
             # Split the text based on the separator, skipping the first part (directory structure)
             potential_blocks = ingest_text.split(separator + '\nFile: ')[1:]
             if not potential_blocks:
                 potential_blocks = ingest_text.split(separator + '\r\nFile: ')[1:] # Try windows newline

             for block in potential_blocks:
                 lines = block.split('\n', 2) # Split path, separator, content
                 if len(lines) >= 3 and lines[1].startswith("==="):
                     relative_path = lines[0].strip()
                     content = lines[2].strip()
                     normalized_path = os.path.normpath(relative_path.replace('\\', '/')).lstrip('.\\/')
                     all_files_content[normalized_path] = content
                     matches_found += 1
                     # print(f"Parsed (fallback): '{normalized_path}'") # Uncomment for debugging
         except Exception as e:
             print(f"Fallback split method failed: {e}")

         if matches_found == 0:
            print("Fallback split method also failed to parse files.")
            return None # Indicate failure

    print(f"Successfully parsed {matches_found} file blocks.")
    return all_files_content


def get_requested_files(all_files_content, requested_paths):
    """
    Retrieves the content for a specific list of files from the parsed data.

    Args:
        all_files_content: The dictionary returned by parse_ingest_text.
        requested_paths: A list of relative file paths to retrieve.

    Returns:
        A dictionary containing only the requested file paths and their content.
        If a requested file was not found in the parsed data, its value will be None.
    """
    result = {}
    found_count = 0
    not_found_count = 0

    if not all_files_content:
        print("Error: Cannot extract requested files because no files were parsed from ingest text.")
        for req_path in requested_paths:
             result[req_path] = None # Use original requested path as key
             not_found_count +=1
        print(f"\nLookup complete: Found {found_count} files, {not_found_count} not found.")
        return result

    if not requested_paths:
        print("Warning: No file paths were provided to extract.")
        return {}

    print("\nStarting file lookup...")
    for req_path in requested_paths:
        # Normalize the requested path for lookup
        normalized_req_path = os.path.normpath(req_path.replace('\\', '/')).lstrip('.\\/')
        # print(f"Looking for '{req_path}' (normalized: '{normalized_req_path}')") # Debugging

        # Check if the normalized path exists in our parsed data
        if normalized_req_path in all_files_content:
            # Use the original requested path as the key in the output
            result[req_path] = all_files_content[normalized_req_path]
            found_count += 1
            # print(f"  Found.") # Debugging
        else:
            print(f"Warning: Requested file path '{req_path}' (normalized: '{normalized_req_path}') not found in parsed ingest data.")
            result[req_path] = None # Indicate not found
            not_found_count += 1

    print(f"\nLookup complete: Found {found_count} files, {not_found_count} not found.")
    return result

# --- Main Execution ---
if __name__ == "__main__":
    # Use 'ingest.txt' as per your example
    ingest_file_path = "digest.txt"
    input_str_file_path = "extract.txt"
    output_json_path = "extracted_code_1.json"

    # --- Read Ingest File ---
    try:
        with open(ingest_file_path, 'r', encoding='utf-8') as f:
            ingest_content = f.read()
        print(f"Successfully read '{ingest_file_path}'.")
    except FileNotFoundError:
        print(f"Error: Ingest file not found at '{ingest_file_path}'. Please make sure it exists in the same directory as the script.")
        exit(1)
    except Exception as e:
        print(f"Error reading '{ingest_file_path}': {e}")
        exit(1)

    # --- Read Input String File ---
    try:
        with open(input_str_file_path, 'r', encoding='utf-8') as f:
            input_str_content = f.read()
        print(f"Successfully read '{input_str_file_path}'.")
    except FileNotFoundError:
        print(f"Error: Input string file not found at '{input_str_file_path}'. Please make sure it exists.")
        exit(1)
    except Exception as e:
        print(f"Error reading '{input_str_file_path}': {e}")
        exit(1)

    # --- Process ---
    print("\nParsing answer block from input string file...")
    target_file_paths = parse_answer_block(input_str_content)

    if target_file_paths:
        print(f"Found {len(target_file_paths)} target file paths.")

        print("\nParsing ingest text file...")
        all_parsed_content = parse_ingest_text(ingest_content)

        if all_parsed_content is not None:
             print("\nExtracting requested file contents...")
             extracted_data = get_requested_files(all_parsed_content, target_file_paths)

             # --- Save Output ---
             try:
                 with open(output_json_path, 'w', encoding='utf-8') as f:
                     json.dump(extracted_data, f, indent=2, ensure_ascii=False)
                 print(f"\nSuccessfully saved extracted code to '{output_json_path}'.")
                 # Optionally print a summary of extracted files
                 print("\nExtracted files:")
                 for path, content in extracted_data.items():
                     status = "[Found]" if content is not None else "[Not Found]"
                     print(f"- {path} {status}")

             except Exception as e:
                 print(f"\nError writing output JSON file '{output_json_path}': {e}")
        else:
            print("\nIngest text parsing failed. Cannot extract files.")

    else:
        print("\nCould not extract target file paths from the input string file. Exiting.")
