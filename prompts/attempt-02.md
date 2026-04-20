# Attempt 02 — Patients Demo Extended (4 artifacts)

**Status:** Completed (with minor assist — see notes)  
**Actual token usage:** ~40% of 131k context window  
**Output:** `patients.json`, `analyze_patients.py`, `risk_flag.py`, `report.txt`

## Prompt

```
/gsd quick Generate four files in the current directory:

1. patients.json — 15 synthetic patient records, each with:
   id, name, age, diagnosis, admission_date, discharge_date

   Use a mix of diagnoses: Hypertension, Diabetes, Pneumonia,
   Appendicitis, Fracture, Asthma. Vary ages between 28 and 82.

2. analyze_patients.py — reads patients.json and prints:
   - Total patient count
   - Average age
   - Most common diagnosis
   - Average length of stay in days
   - Breakdown by diagnosis: count and avg stay per diagnosis

3. risk_flag.py — reads patients.json and prints a list of
   high-risk patients (age > 65 AND diagnosis is Hypertension,
   Diabetes, or Asthma), showing name, age, and diagnosis.

4. report.txt — written by analyze_patients.py as a file
   (not just printed to stdout), containing the same summary output.

Use only Python standard library. All scripts must run independently.
```

## Actual output

**analyze_patients.py**
```
Total patient count: 15
Average age: 57.87
Most common diagnosis: Hypertension
Average length of stay in days: 6.60
Breakdown by diagnosis:
  Hypertension: 3 patients, avg stay 6.00 days
  Diabetes: 3 patients, avg stay 7.00 days
  Pneumonia: 3 patients, avg stay 6.33 days
  Fracture: 2 patients, avg stay 8.00 days
  Asthma: 2 patients, avg stay 6.00 days
  Appendicitis: 2 patients, avg stay 6.50 days
```

**risk_flag.py**
```
High-Risk Patients:
Name                  Age  Diagnosis
----------------------------------------
Bob Smith              70  Diabetes
Jennifer White         72  Diabetes
James Johnson          79  Asthma
David Brown            66  Hypertension
```

**report.txt** — written to disk by analyze_patients.py, matches stdout above.

## Notes

- GSD must be run from a git-initialized directory (`git init` if needed)
- Run `bash ~/run-gsd.sh` from the project directory
- Token budget: ~40% is well within safe range for single-shot tasks
- `report.txt` is written by the script, not by GSD directly
- **Known issue:** The 400 error from the inference endpoint truncated `analyze_patients.py`
  mid-write and dropped `risk_flag.py` entirely. Both files were completed manually to match
  Nemotron's generated logic. The data and all meaningful code is Nemotron's output.
- Root cause: GSD's follow-up turn after file writes pushed the context over `max_model_len`.
  The files themselves are well within budget — it's the confirmation round-trip that fails.
