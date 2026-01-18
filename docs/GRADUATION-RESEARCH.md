# Louisiana Graduation Rate Data Research

**Research Date:** 2026-01-10
**Package:** laschooldata
**Objective:** Identify viable machine-readable sources for graduation rate data by district/school

---

## Executive Summary

**Viability Tier: 1 (Direct Downloads - IMPLEMENT)**

Louisiana provides excellent graduation rate data through the Louisiana Department of Education (LDOE). The data is available as direct Excel downloads with consistent structure across all target years (2021-2025). This is a high-quality implementation candidate.

**Recommendation:** IMPLEMENT

---

## Data Sources

### Primary Source: LDOE Data Downloads

**Base URL:** https://doe.louisiana.gov/docs/default-source/data-management/

#### 1. Graduation Rates by Subgroup (PRIMARY DATA SOURCE)

**Description:** School and district-level cohort graduation rates with comprehensive subgroup breakdowns.

**File Pattern:** `{year}-state-school-system-and-school-cohort-grad-rates-by-subgroups.xlsx`

**Availability:**

| Year | File Status | URL |
|------|-------------|-----|
| 2021 | Available (HTTP 200) | [2021 File](https://doe.louisiana.gov/docs/default-source/data-management/2021-state-school-system-and-school-cohort-grad-rates-by-subgroups.xlsx) |
| 2022 | Available (HTTP 200) | [2022 File](https://doe.louisiana.gov/docs/default-source/data-management/2022-state-school-system-and-school-cohort-grad-rates-by-subgroups.xlsx) |
| 2023 | Available (HTTP 200) | [2023 File](https://doe.louisiana.gov/docs/default-source/data-management/2023-state-school-system-and-school-cohort-grad-rates-by-subgroups.xlsx) |
| 2024 | Available (HTTP 200) | [2024 File](https://doe.louisiana.gov/docs/default-source/data-management/2024-state-school-system-and-school-cohort-grad-rates-by-subgroups.xlsx) |
| 2025 | Available (HTTP 200) | [2025 File](https://doe.louisiana.gov/docs/default-source/data-management/2025-state-school-system-and-school-cohort-grad-rates-by-subgroups.xlsx) |

#### 2. Overall Graduation Rates (Simpler Alternative)

**Description:** School-level graduation rates without subgroup breakdowns.

**File Pattern:** `{year}-school-cohort-graduation-and-credential-rate-summary.xlsx`

**Availability:**

| Year | File Status | URL |
|------|-------------|-----|
| 2021 | Available (HTTP 200) | [2021 File](https://doe.louisiana.gov/docs/default-source/data-management/2021-school-cohort-graduation-and-credential-rate-summary.xlsx) |
| 2022 | Available (HTTP 200) | [2022 File](https://doe.louisiana.gov/docs/default-source/data-management/2022-school-cohort-graduation-and-credential-rate-summary.xlsx) |
| 2023 | Available (HTTP 200) | [2023 File](https://doe.louisiana.gov/docs/default-source/data-management/2023-school-cohort-graduation-and-credential-rate-summary.xlsx) |
| 2024 | Available (HTTP 200) | [2024 File](https://doe.louisiana.gov/docs/default-source/data-management/2024-school-cohort-graduation-and-credential-rate-summary.xlsx) |
| 2025 | Available (HTTP 200) | [2025 File](https://doe.louisiana.gov/docs/default-source/data-management/2025-school-cohort-graduation-and-credential-rate-summary.xlsx) |

---

## Data Structure

### File Format

- **Format:** Excel (.xlsx)
- **Sheet Structure:** Single data sheet per year
- **Header Row:** Row 3 (skip first 3 rows: title, FERPA disclaimer, header)
- **Encoding:** Standard UTF-8

### Primary Data Structure (Subgroup Files)

**Sheet Name:** `{year} Graduation_Rate_Subgroup`

**Rows:**

| Year | Total Rows | State | Districts | Schools |
|------|------------|-------|-----------|---------|
| 2021 | 429 | 1 | 72 | 356 |
| 2022 | 434 | 1 | 72 | 361 |
| 2023 | 442 | 1 | 72 | 369 |
| 2024 | 436 | 1 | 72 | 363 |
| 2025 | 438 | 1 | 72 | 365 |

**Columns (16 total - consistent across all years):**

1. `School/School System Code` - Entity identifier (LA = state, 3-digit = district, 6+ digit = school)
2. `School/School System Name` - Entity name
3. `Overall Cohort Grad Rate` - Overall graduation rate percentage
4. `American Indian/Alaskan Native Rate` - AI/AN subgroup rate
5. `Asian Rate` - Asian subgroup rate
6. `Black/African American Rate` - Black/African American subgroup rate
7. `Hispanic Rate` - Hispanic subgroup rate
8. `White Rate` - White subgroup rate
9. `Native Hawaiian/Pacific Islander Rate` - NH/PI subgroup rate
10. `Multi-Race Rate` - Multi-race subgroup rate
11. `Economically Disadvantaged Rate` - Economically disadvantaged subgroup rate
12. `Students with Disabilities Rate` - Students with disabilities subgroup rate
13. `English Learner Rate` - English learner subgroup rate
14. `Homeless Rate` - Homeless subgroup rate
15. `Foster Care Rate` - Foster care subgroup rate
16. `Military Affiliation Rate` - Military affiliation subgroup rate

### Data Values

**Value Types:**
- Numeric percentages: `82.9`, `93.7`, `87.9`
- Threshold values: `>95`, `<5`
- Special codes:
  - `~` - Statistically unreliable (less than 10 students)
  - `NR` - Data not available/suppressed for privacy

**Sample District-Level Data (2025):**

```
School/School System Code: 001
School/School System Name: Acadia Parish
Overall Cohort Grad Rate: 87
American Indian/Alaskan Native Rate: NR
Asian Rate: ~
Black/African American Rate: 80.7
Hispanic Rate: 74.1
White Rate: 90.5
Native Hawaiian/Pacific Islander Rate: NR
Multi-Race Rate: 82.1
Economically Disadvantaged Rate: 80.3
Students with Disabilities Rate: 68
English Learner Rate: ~
Homeless Rate: ~
Foster Care Rate: ~
Military Affiliation Rate: ~
```

**Sample School-Level Data (2025):**

```
School/School System Code: 001005
School/School System Name: Church Point High School
Overall Cohort Grad Rate: 93.7
American Indian/Alaskan Native Rate: NR
Asian Rate: NR
Black/African American Rate: 92.6
Hispanic Rate: ~
White Rate: >95
Native Hawaiian/Pacific Islander Rate: NR
Multi-Race Rate: ~
Economically Disadvantaged Rate: 90.7
Students with Disabilities Rate: ~
English Learner Rate: ~
Homeless Rate: ~
Foster Care Rate: NR
Military Affiliation Rate: NR
```

---

## Implementation Considerations

### Advantages

1. **Complete Year Coverage:** All 5 target years (2021-2025) available
2. **Consistent Structure:** Identical schema across all years
3. **Comprehensive Subgroups:** 13 demographic subgroups plus overall rate
4. **Both Levels:** District and school-level data in same file
5. **Direct Downloads:** No API authentication or complex scraping required
6. **Stable URLs:** Predictable URL pattern by year
7. **Privacy-Conscious:** Proper FERPA compliance with data suppression

### Data Quality Features

- **FERPA Compliance:** Explicit privacy protection documented in data files
- **Suppression Codes:** Clear indicators (`~`, `NR`) for suppressed data
- **Threshold Values:** `>95` and `<5` for rates at boundaries
- **Statewide Aggregate:** State-level totals included for comparison
- **No Manual Processing Required:** Direct Excel parsing with readxl

### Technical Implementation

**File Reading (R):**
```r
library(readxl)

# Skip first 3 rows (title, disclaimer, then headers)
df <- read_excel(path, sheet = "{year} Graduation_Rate_Subgroup", skip = 3)

# Convert district vs school
df$data_level <- ifelse(nchar(df$`School/School System Code`) == 3, "district",
                        ifelse(df$`School/School System Code` == "LA", "state", "school"))
```

**URL Pattern:**
```
https://doe.louisiana.gov/docs/default-source/data-management/{year}-state-school-system-and-school-cohort-grad-rates-by-subgroups.xlsx
```

**Data Type Notes:**
- All rate columns are character (need conversion to numeric)
- Must handle special values: `>95`, `<5`, `~`, `NR`
- Leading/trailing whitespace in values (e.g., ` 93.7`)

### Filtering Considerations

**District-Level Data:**
- Code length = 3 characters
- Exclude state-level (code = "LA")

**School-Level Data:**
- Code length ≥ 6 characters

**Subgroup Availability:**
- Most subgroups have sparse data (many `NR` and `~` values)
- Race/ethnicity generally available for larger schools
- Small schools may have most subgroups suppressed

---

## Comparison to Other States

**Louisiana's Data Quality: EXCELLENT**

- **Tier 1 Implementation:** Same quality as Alabama, Texas, Florida
- **Better than most states:** More comprehensive than typical DOE releases
- **Subgroup Depth:** 13 subgroups exceeds federal requirements
- **Stability:** 5-year consistent track record
- **Transparency:** Clear FERPA documentation and suppression codes

---

## Sample Data Values

### 2025 Statewide Aggregate

```
Louisiana Statewide:
  Overall: 85.0%
  White: 89.6%
  Black/African American: 82.9%
  Hispanic: 72.8%
  Asian: 94.4%
  Multi-Race: 85.5%
  Economically Disadvantaged: 80.2%
  Students with Disabilities: 81.2%
  English Learners: 51.7%
```

### 2025 District Example (Acadia Parish - 001)

```
Overall: 87.0%
White: 90.5%
Black/African American: 80.7%
Hispanic: 74.1%
Economically Disadvantaged: 80.3%
Students with Disabilities: 68.0%
```

### 2025 School Example (Church Point High School - 001005)

```
Overall: 93.7%
Black/African American: 92.6%
Economically Disadvantaged: 90.7%
```

---

## Additional Data Products

The LDOE also provides credential rate data in separate sheets within the summary files:

**Credential Metrics (2025 example):**
- `% of cohort earning Advanced credentials (≥150)`
- `% of cohort earning Basic credentials (>=110 and <150)`
- `% of cohort earning Advanced+Basic credentials (>=110)`
- `% of cohort earning diploma with no Basic or Advanced credentials (100/105)`

These are available in the "Graduates Credentials {year}" sheets of the summary files.

---

## Recommendations

### IMPLEMENTATION PRIORITY: HIGH

**Recommended Approach:**

1. **Use subgroup files as primary data source**
   - File: `{year}-state-school-system-and-school-cohort-grad-rates-by-subgroups.xlsx`
   - Provides both district and school-level data
   - Comprehensive subgroup breakdowns

2. **Implement both `get_raw_grad()` and `get_grad()` functions**
   - `get_raw_grad()`: Raw data from Excel with special values intact
   - `get_grad()`: Tidy format with numeric conversions

3. **Create filtering parameter for data level**
   - `level = c("district", "school", "both")`
   - Default to both levels for flexibility

4. **Handle special values explicitly**
   - Convert `>95` to 96 or NA (document decision)
   - Convert `<5` to 4 or NA (document decision)
   - Keep `~` and `NR` as NA with attributes indicating suppression reason

5. **Implement subgroup parameter**
   - `subgroups = c("overall", "race_ethnicity", "all")`
   - Allow users to select which subgroups to retrieve

### Data Fidelity

**Critical:** Maintain exact values from source files
- Do not round or transform percentages
- Document special value handling in documentation
- Include suppression codes as attributes, not dropped

### Testing Strategy

1. **Year Coverage Test:** Verify all 5 years download and parse
2. **Structure Test:** Verify 16 columns present in each year
3. **Row Count Test:** Verify expected district/school counts per year
4. **Value Range Test:** Verify percentages in reasonable ranges (0-100 or special codes)
5. **Fidelity Test:** Compare district aggregates to sum of schools (where available)

---

## Conclusion

Louisiana's graduation rate data is **exceptionally well-structured and accessible**. The LDOE provides:

- 5 years of consistent data (2021-2025)
- Direct Excel downloads with no authentication required
- Comprehensive subgroup breakdowns (13 subgroups)
- Both district and school-level data
- Clear privacy protection documentation
- Stable, predictable URLs

This is a **Tier 1 implementation candidate** with high confidence for successful deployment.

**Next Steps:**
1. Create `get_raw_grad()` function to fetch Excel files
2. Create `get_grad()` function to return tidy data
3. Implement filtering by level (district/school) and subgroups
4. Add comprehensive tests for all years
5. Document special value handling in vignette

---

## Sources

- [LDOE Data Management Portal](https://doe.louisiana.gov/docs/default-source/data-management/)
- [2025 Graduation Rates by Subgroup](https://doe.louisiana.gov/docs/default-source/data-management/2025-state-school-system-and-school-cohort-grad-rates-by-subgroups.xlsx)
- [2025 School Cohort Graduation Summary](https://doe.louisiana.gov/docs/default-source/data-management/2025-school-cohort-graduation-and-credential-rate-summary.xlsx)
- [LDOE News Release: Louisiana High School Graduation Rate Exceeds 83%](https://www.wafb.com/2024/10/30/new-data-shows-more-louisiana-high-school-students-are-graduating/)
