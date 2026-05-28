import csv
import json

INPUT_FILE = "h:\\Pelit\\PotS_JASS\\Other\\ToDoVoDo_2518_WC3Patho_2026-02-05_01-10-41.json"
OUTPUT_FILE = "output.csv"

COLUMNS = ["title", "body", "labels", "assignees", "milestone", "state", "state_reason"]


def normalize_text(value):
    if value is None:
        return ""
    return str(value)





def main():
    with open(INPUT_FILE, "r", encoding="utf-8-sig") as f:
        data = json.load(f)

    if not isinstance(data, list):
        raise ValueError("Input JSON must be a list of task objects.")

    with open(OUTPUT_FILE, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=COLUMNS, quoting=csv.QUOTE_ALL)
        writer.writeheader()
        
        for task in data:
            if not isinstance(task, dict):
                continue
                
            title = normalize_text(task.get("title", ""))
            checklist_items = task.get("checklistItems", [])
            
            if checklist_items and isinstance(checklist_items, list):
                # One row per checklist item
                for item in checklist_items:
                    if isinstance(item, dict):
                        body = normalize_text(item.get("displayName", ""))
                        is_checked = item.get("isChecked", False)
                        state = "completed" if is_checked else "notStarted"
                        
                        row = {
                            "title": title,
                            "body": body,
                            "labels": "",
                            "assignees": "",
                            "milestone": "",
                            "state": state,
                            "state_reason": "",
                        }
                        writer.writerow(row)
            else:
                # No checklist items: output one row with empty body
                row = {
                    "title": title,
                    "body": "",
                    "labels": "",
                    "assignees": "",
                    "milestone": "",
                    "state": "notStarted",
                    "state_reason": "",
                }
                writer.writerow(row)

    print(f"CSV file created: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
