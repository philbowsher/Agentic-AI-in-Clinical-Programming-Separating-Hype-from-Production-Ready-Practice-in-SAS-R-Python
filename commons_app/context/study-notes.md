# Study notes: CDISCPILOT01

- The study compares placebo with low and high doses of xanomeline in subjects with mild to moderate Alzheimer's disease.
- ADSL has one record per randomized subject. Screen failures are excluded (define.xml).
- Age groups (AGEGR1): <65, 65-80, >80. A subject aged exactly 65 belongs in 65-80.
- The safety population (SAFFL = "Y") is every ITT subject who received at least one dose (TRTSDT present).
- TRTEDT is the last dose date. If it is missing and the subject discontinued after visit 3, the define.xml says to use the discontinuation date.
- The study ADSL is built in SAS by programs/sas/adsl.sas and keeps only the variables that program derives. The original CDISC pilot ADSL has more variables.
