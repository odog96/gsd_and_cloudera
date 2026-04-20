# Attempt 01 — Patients Demo (2 artifacts)

**Status:** Completed successfully  
**Token usage:** ~5% of 131k context window  
**Output:** `patients.json`, `analyze_patients.py`

## Prompt

```
/gsd quick Generate two files:

1. patients.json — an array of 10 synthetic patient records, each with fields:
   id, name, age, diagnosis, admission_date, discharge_date

2. analyze_patients.py — a Python script that reads patients.json and prints:
   - Total patient count
   - Average age
   - Most common diagnosis
   - Average length of stay in days

Use only Python standard library. Print a clean summary to stdout.
```

## Expected output

```
Patient Summary:

Total Patients: 10
Average Age: 49.4
Most Common Diagnosis: Hypertension
Average Length of Stay: 5.7 days
```

## Notes

- GSD must be run from a git-initialized directory
- `/gsd quick` skips planning ceremony — keeps token usage low
- Files land in the current working directory
