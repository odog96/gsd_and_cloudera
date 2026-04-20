# Patients Demo Prompt

Paste this directly into your GSD session.

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
