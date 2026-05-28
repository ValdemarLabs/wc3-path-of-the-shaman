import csv
import json

INPUT_FILE = "h:\\Pelit\\WC3_PotS_Requirements\\ToDoVoDo_2518_WC3Patho_2026-02-05_01-10-41.json"
OUTPUT_FILE = "output.csv"

COLUMNS = ["title", "body", "labels", "assignees", "milestone", "state", "state_reason"]


def normalize_text(value):
    if value is None:
        return ""
    return str(value)


def build_body(task):
    body_content = ""
    body = task.get("body", {})
    if isinstance(body, dict):
        body_content = normalize_text(body.get("content", ""))
    else:
        body_content = normalize_text(body)

    checklist_items = task.get("checklistItems", [])
    checklist_texts = []
    if isinstance(checklist_items, list):
        for item in checklist_items:
            if isinstance(item, dict):
                display_name = normalize_text(item.get("displayName", ""))
                if display_name:
                    checklist_texts.append(display_name)

    parts = [p for p in [body_content] + checklist_texts if p]
    return "\n".join(parts)


def build_labels(task):
    categories = task.get("categories", [])
    if isinstance(categories, list):
        return ";".join(normalize_text(cat) for cat in categories if cat is not None)
    return ""


def to_row(task):
    return {
        "title": normalize_text(task.get("title", "")),
        "body": build_body(task),
        "labels": build_labels(task),
        "assignees": "",
        "milestone": "",
        "state": normalize_text(task.get("status", "")),
        "state_reason": normalize_text(task.get("importance", "")),
    }


def main():
    with open(INPUT_FILE, "r", encoding="utf-8-sig") as f:
        data = json.load(f)

    if not isinstance(data, list):
        raise ValueError("Input JSON must be a list of task objects.")

    with open(OUTPUT_FILE, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=COLUMNS, quoting=csv.QUOTE_MINIMAL)
        writer.writeheader()
        for task in data:
            if isinstance(task, dict):
                writer.writerow(to_row(task))

    print(f"CSV file created: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
