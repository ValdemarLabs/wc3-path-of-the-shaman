import json
import csv

# Input and output file paths
json_file = "h:\\Pelit\\WC3_PotS_Requirements\\ToDoVoDo_2518_WC3Patho_2026-02-05_01-10-41.json"
csv_file = "output.csv"

# Columns to extract
columns = ["title", "body", "isChecked", "labels", "assignees", "milestone", "state", "state_reason"]

with open(json_file, "r", encoding="utf-8-sig") as f:
    data = json.load(f)

# If the JSON is a list of issues
if isinstance(data, list):
    issues = data
# If the JSON is a dict with issues under a key
elif isinstance(data, dict):
    # Try to find the key that contains the issues
    for key in data:
        if isinstance(data[key], list):
            issues = data[key]
            break
    else:
        raise ValueError("No list of issues found in JSON.")
else:
    raise ValueError("Unexpected JSON structure.")

with open(csv_file, "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=columns)
    writer.writeheader()
    for issue in issues:
        checklist = issue.get("checklistItems", [])
        if checklist:
            for item in checklist:
                row = {}
                row["title"] = issue.get("title", "")
                row["body"] = item.get("displayName", "")
                row["isChecked"] = item.get("isChecked", "")
                # Fill in other columns from parent issue
                for col in columns:
                    if col in ("title", "body", "isChecked"):
                        continue
                    value = issue.get(col, "")
                    if isinstance(value, list):
                        value = ", ".join(str(v) for v in value)
                    if isinstance(value, dict):
                        value = value.get("title", str(value))
                    row[col] = value
                writer.writerow(row)
        else:
            # No checklist items, output one row for the task itself
            row = {}
            row["title"] = issue.get("title", "")
            # Use the main body content if available
            body = issue.get("body", {})
            if isinstance(body, dict):
                row["body"] = body.get("content", "")
            else:
                row["body"] = body
            row["isChecked"] = ""
            for col in columns:
                if col in ("title", "body", "isChecked"):
                    continue
                value = issue.get(col, "")
                if isinstance(value, list):
                    value = ", ".join(str(v) for v in value)
                if isinstance(value, dict):
                    value = value.get("title", str(value))
                row[col] = value
            writer.writerow(row)

print(f"CSV file created: {csv_file}")