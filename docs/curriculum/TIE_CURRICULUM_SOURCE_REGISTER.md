# LearnTZ — TIE Curriculum Source Register
**Authority:** Tanzania Institute of Education (Taasisi ya Elimu Tanzania - TIE)  
**Parent Ministry:** Ministry of Education, Science and Technology (MoEST)  
**Location:** Dar es Salaam, United Republic of Tanzania  
**Registry Version:** 2023.1.0-PROD  
**Document Format:** PDF / Authoritative Print Documents  
**Status:** Cryptographically Verified • STAGE C Deliverable  

---

## 1. Registry Architecture & Verification Methodology

All primary curriculum implementations in LearnTZ derive strictly from official national syllabus documents published by the Tanzania Institute of Education (TIE). Each physical source file stored in `data/curriculum/tz/` is verified against SHA-256 cryptographic checksums, mapped to `public.curriculum_sources` in the Supabase production database, and indexed by internal table page boundaries.

---

## 2. Authoritative Source Document Inventory

### Doc 01: General Primary Curriculum Framework
- **File Name:** `en-1724244732-Curriculum for Primary Education.pdf`
- **Official Title:** *Curriculum for Primary Education Standard I - VI*
- **Swahili Title:** *Mtaala wa Elimu ya Msingi Darasa la I - VI*
- **Issuing Institution:** Tanzania Institute of Education (TIE)
- **ISBN:** `978-9987-09-852-1`
- **Publication Year:** 2023 First Edition
- **File Size:** 1,171,410 bytes (1.17 MB) | **Page Count:** 34 pages
- **SHA-256 Checksum:** `b5298c4153dbe9f9d22fb21740a7a666405cb2a2c875db1a506379aac834a447`
- **Database UUID (`public.curriculum_sources`):** `c6256a41-c331-4f30-be06-e53e352af8a2`
- **Usage Rights Status:** `permission_pending` (Reference metadata cleared)
- **Verification Status:** `verified`
- **Internal Table Mapping:**
  - Table of Contents: p. 3
  - Table 1 (Learning Areas & Competences Std I–II): p. 13
  - Table 2 (Learning Areas & Subjects Std III–VI): p. 14
  - Table 3 (Main & Specific Competences Std I–II): p. 14
  - Table 4 (Subjects & Competences Std III–VI): pp. 16–25
  - Table 5 (Time & Period Allocation Std I–II): p. 26
  - Table 6 (Time & Period Allocation Std III–VI): p. 26

---

### Doc 02: Foundational Learning (Standards I & II)
- **File Name:** `en-1727083562-PRIMARY EDUCATION SYLLABUS STD 1-II FINAL.pdf`
- **Official Title:** *Primary Education Syllabus Standard I – II*
- **Swahili Title:** *Muhtasari wa Elimu ya Msingi Darasa la I – II*
- **Issuing Institution:** Tanzania Institute of Education (TIE)
- **ISBN:** `978-9987-09-837-8`
- **Publication Year:** 2023 First Edition
- **File Size:** 651,402 bytes | **Page Count:** 42 pages
- **SHA-256 Checksum:** `34a99e256d89fd117f951223a78f4a13afaf15e630299f7cb5c250b09157a8b1`
- **Database UUID (`public.curriculum_sources`):** `549bd065-3079-45da-961b-d98f8c3e8209`
- **Usage Rights Status:** `permission_pending`
- **Verification Status:** `verified`
- **Internal Table Mapping:**
  - Table 1 (Overview Std I–II): p. 9
  - Table 2 (Period Distribution Std I–II): p. 13
  - Table 3 (Detailed Contents Standard I): pp. 14–26
  - Table 4 (Detailed Contents Standard II): pp. 27–40

---

### Doc 03: Kiswahili (Standards III–VI)
- **File Name:** `sw-1727177907-MUHTASARI SOMO KISWAHILI DRS III - VI.pdf`
- **Official Title:** *Muhtasari wa Somo la Kiswahili Elimu ya Msingi Darasa la III–VI*
- **English Title:** *Kiswahili Syllabus for Primary Education Standard III–VI*
- **Issuing Institution:** Taasisi ya Elimu Tanzania (TIE)
- **ISBN:** `978-9987-09-782-1`
- **Publication Year:** 2023 First Edition
- **File Size:** 944,426 bytes | **Page Count:** 76 pages
- **SHA-256 Checksum:** `037b48e2017eebe1d2fcec8cf796a631ea180b646ecf4d4a46bf2649dc4afc7b`
- **Database UUID (`public.curriculum_sources`):** `92c59ee8-583c-4432-bf89-9e12681b74d6`
- **Usage Rights Status:** `permission_pending`
- **Verification Status:** `verified`
- **Internal Table Mapping:**
  - Jedwali Na. 1 (Overview Std III–VI): p. 10
  - Jedwali Na. 2 (Detailed Contents Standard III): pp. 15–31
  - Jedwali Na. 3 (Detailed Contents Standard IV): pp. 32–47
  - Jedwali Na. 4 (Detailed Contents Standard V): pp. 48–63
  - Jedwali Na. 5 (Detailed Contents Standard VI): pp. 64–74

---

### Doc 04: English Language (Standards III–VI) — *Reference Implementation*
- **File Name:** `sw-1727168466-ENGLISH Syllabus III-VI FINAL.pdf`
- **Official Title:** *English Language Syllabus for Primary Education Standard III─VI*
- **Swahili Title:** *Muhtasari wa Somo la Kiingereza Elimu ya Msingi Darasa la III─VI*
- **Issuing Institution:** Tanzania Institute of Education (TIE)
- **ISBN:** `978-9987-09-726-5`
- **Publication Year:** 2023 First Edition
- **File Size:** 1,113,809 bytes | **Page Count:** 64 pages
- **SHA-256 Checksum:** `ae6b2f5d28b60bb77bd3bb2d7816535bacb671934cca4660705cfa937f9aacd2`
- **Database UUID (`public.curriculum_sources`):** `e8301da6-b2e7-4540-990b-c939a0faa22d`
- **Usage Rights Status:** `permission_pending` (Reference metadata cleared)
- **Verification Status:** `verified` (100% Ingested & Active in DB)
- **Internal Table Mapping:**
  - Table 1 (Overview Std III–VI): p. 9
  - Table 2 (Detailed Contents Standard III): pp. 14–21 (244 periods)
  - Table 3 (Detailed Contents Standard IV): pp. 22–31 (234 periods)
  - Table 4 (Detailed Contents Standard V): pp. 32–47 (224 periods)
  - Table 5 (Detailed Contents Standard VI): pp. 48–59 (150 periods)

---

### Doc 05: Mathematics (Standards III–VI)
- **File Name:** `en-1727169918-SYLLABUS FOR MATHEMATICS PRIMARY EDUCATION.pdf`
- **Official Title:** *Mathematics Syllabus for Primary School Education Standard III-VI*
- **Swahili Title:** *Muhtasari wa Somo la Hisabati Elimu ya Msingi Darasa la III-VI*
- **Issuing Institution:** Tanzania Institute of Education (TIE)
- **ISBN:** `978-9987-09-858-3`
- **Publication Year:** 2023 First Edition
- **File Size:** 826,615 bytes | **Page Count:** 40 pages
- **SHA-256 Checksum:** `baef25143a8133b1a435854134f0971133585bb8674d873ba99b83826a0e6eb8`
- **Database UUID (`public.curriculum_sources`):** `a438a4df-2445-471d-a7ee-fc76c5e025e4`
- **Usage Rights Status:** `permission_pending`
- **Verification Status:** `verified`
- **Internal Table Mapping:**
  - Table 1 (Overview Std III–VI): p. 9
  - Table 2 (Detailed Contents Standard III): pp. 14–21
  - Table 3 (Detailed Contents Standard IV): pp. 22–25
  - Table 4 (Detailed Contents Standard V): pp. 26–33
  - Table 5 (Detailed Contents Standard VI): pp. 34–39

---

### Doc 06: Science and Technology (Standards III–VI)
- **File Name:** `en-1727175605-Science Syllabus For Primary Education Standard III - VI.pdf`
- **Official Title:** *Science Syllabus for Primary Education Standard III─VI*
- **Swahili Title:** *Muhtasari wa Sayansi na Teknolojia Elimu ya Msingi Darasa la III─VI*
- **Issuing Institution:** Tanzania Institute of Education (TIE)
- **ISBN:** `978-9987-09-860-6`
- **Publication Year:** 2023 First Edition
- **File Size:** 398,091 bytes | **Page Count:** 49 pages
- **SHA-256 Checksum:** `f83ea3623f244c0505b6df390a797db9b014d0449ea99172d5622d1ab95f6157`
- **Database UUID (`public.curriculum_sources`):** `69cfd26d-d35b-4583-b3dd-5e7c501e6ff9`
- **Usage Rights Status:** `permission_pending`
- **Verification Status:** `verified`
- **Internal Table Mapping:**
  - Table 1 (Overview Std III–VI): p. 10
  - Table 2 (Detailed Contents Standard III): pp. 15–22
  - Table 3 (Detailed Contents Standard IV): pp. 23–32
  - Table 4 (Detailed Contents Standard V): pp. 33–39
  - Table 5 (Detailed Contents Standard VI): pp. 40–47

---

### Doc 07: Geography and the Environment (Standards III–VI)
- **File Name:** `en-1727166774-GEOGRAPHY STANDARD III-VI .pdf`
- **Official Title:** *Geography and the Environment Syllabus for Primary Education Standard III – VI*
- **Swahili Title:** *Muhtasari wa Jiografia na Mazingira Elimu ya Msingi Darasa la III – VI*
- **Issuing Institution:** Tanzania Institute of Education (TIE)
- **ISBN:** `978-9987-09-859-0`
- **Publication Year:** 2023 First Edition
- **File Size:** 704,729 bytes | **Page Count:** 37 pages
- **SHA-256 Checksum:** `fe373aee700908a968ebad4dfc365a7141891c260dfc828eedbf882a75a3489d`
- **Database UUID (`public.curriculum_sources`):** `4eaefc6f-298a-45c0-90e3-66999d485796`
- **Usage Rights Status:** `permission_pending`
- **Verification Status:** `verified`
- **Internal Table Mapping:**
  - Table 1 (Overview Std III–VI): p. 9
  - Table 2 (Detailed Contents Standard III): pp. 14–19
  - Table 3 (Detailed Contents Standard IV): pp. 20–24
  - Table 4 (Detailed Contents Standard V): pp. 25–30
  - Table 5 (Detailed Contents Standard VI): pp. 31–36

---

### Doc 08: History of Tanzania and Ethics (Standards III–VI)
- **File Name:** `sw-1788263951-KAMISHINA Muhtasari historia ya Tanzania na Maadili A.pdf`
- **Official Title:** *Muhtasari wa Somo la Historia ya Tanzania na Maadili Elimu ya Msingi Darasa la III-VI*
- **English Title:** *History of Tanzania and Ethics Syllabus for Primary Education Standard III-VI*
- **Issuing Institution:** Taasisi ya Elimu Tanzania (TIE)
- **ISBN:** `978-9987-09-795-1`
- **Publication Year:** 2023 First Edition
- **File Size:** 843,958 bytes | **Page Count:** 52 pages
- **SHA-256 Checksum:** `4ea0df6a92752fbba00dbb9aa2f9cacd4f66733c8471d650bb3d99e4c83c70e3`
- **Database UUID (`public.curriculum_sources`):** `503ef846-67ce-4020-bae2-c4cd20891c1a`
- **Usage Rights Status:** `permission_pending`
- **Verification Status:** `verified`
- **Internal Table Mapping:**
  - Jedwali Na 1 (Overview Std III–VI): p. 10
  - Jedwali Na 2 (Detailed Contents Standard III): pp. 16–26
  - Jedwali Na 3 (Detailed Contents Standard IV): pp. 27–33
  - Jedwali Na 4 (Detailed Contents Standard V): pp. 34–39
  - Jedwali Na 5 (Detailed Contents Standard VI): pp. 40–49

---

### Doc 09: Arts and Sports (Standards III–VI)
- **File Name:** `en-1727176628-SPORT and Arts Primary Education Syllabus III -  VI.pdf`
- **Official Title:** *Arts and Sports Syllabus for Primary Education Standard III─VI*
- **Swahili Title:** *Muhtasari wa Sanaa na Michezo Elimu ya Msingi Darasa la III─VI*
- **Issuing Institution:** Tanzania Institute of Education (TIE)
- **ISBN:** `978-9987-09-857-6`
- **Publication Year:** 2023 First Edition
- **File Size:** 1,017,452 bytes | **Page Count:** 39 pages
- **SHA-256 Checksum:** `49aa2159d9801f2fc597befb79f73ed3f528b00b25bf9106ae4f718ec9fc2011`
- **Database UUID (`public.curriculum_sources`):** `965f122b-4399-4eda-b6f5-d4161372cebb`
- **Usage Rights Status:** `permission_pending`
- **Verification Status:** `verified`
- **Internal Table Mapping:**
  - Table 1 (Overview Std III–VI): p. 10
  - Table 2 (Detailed Contents Standard III): pp. 14–19
  - Table 3 (Detailed Contents Standard IV): pp. 20–25
  - Table 4 (Detailed Contents Standard V): pp. 26–32
  - Table 5 (Detailed Contents Standard VI): pp. 33–38

---

### Doc 10: Chinese Language (Standards III–VI) — *Elective*
- **File Name:** `sw-1727176969-MUHTASARI WA LUGHA YA KICHINA ELIMU YA MSINGI III - VI.pdf`
- **Official Title:** *Muhtasari wa Lugha ya Kichina Elimu ya Msingi Darasa la III–VI*
- **Chinese Title:** *小学三至六年级中文教学大纲*
- **Issuing Institution:** Taasisi ya Elimu Tanzania (TIE)
- **ISBN:** `978-9987-09-844-6`
- **Publication Year:** 2023 First Edition
- **File Size:** 745,977 bytes | **Page Count:** 78 pages
- **SHA-256 Checksum:** `323905446a4d04fabc32e05aeaa3bf97616afbde37b12c6c0d1aec7193e8f21d`
- **Database UUID (`public.curriculum_sources`):** `3cbc64b4-687f-4892-8212-4d182b737733`
- **Usage Rights Status:** `permission_pending`
- **Verification Status:** `verified`
- **Internal Table Mapping:**
  - Table 1 (Overview Std III–VI): p. 12
  - Table 2 (Detailed Contents Standard III): pp. 19–36
  - Table 3 (Detailed Contents Standard IV): pp. 37–50
  - Table 4 (Detailed Contents Standard V): pp. 51–65
  - Table 5 (Detailed Contents Standard VI): pp. 66–76

---

## 3. Cryptographic Verification Matrix

| Document Reference | Checksum (SHA-256) | DB Status |
| :--- | :--- | :--- |
| Curriculum Framework | `b5298c4153dbe9f9d22fb21740a7a666405cb2a2c875db1a506379aac834a447` | Verified |
| Standards I & II Syllabus | `34a99e256d89fd117f951223a78f4a13afaf15e630299f7cb5c250b09157a8b1` | Verified |
| Kiswahili Syllabus | `037b48e2017eebe1d2fcec8cf796a631ea180b646ecf4d4a46bf2649dc4afc7b` | Verified |
| English Syllabus (Ref) | `ae6b2f5d28b60bb77bd3bb2d7816535bacb671934cca4660705cfa937f9aacd2` | Verified & Active |
| Mathematics Syllabus | `baef25143a8133b1a435854134f0971133585bb8674d873ba99b83826a0e6eb8` | Verified |
| Science Syllabus | `f83ea3623f244c0505b6df390a797db9b014d0449ea99172d5622d1ab95f6157` | Verified |
| Geography Syllabus | `fe373aee700908a968ebad4dfc365a7141891c260dfc828eedbf882a75a3489d` | Verified |
| History & Ethics Syllabus | `4ea0df6a92752fbba00dbb9aa2f9cacd4f66733c8471d650bb3d99e4c83c70e3` | Verified |
| Arts & Sports Syllabus | `49aa2159d9801f2fc597befb79f73ed3f528b00b25bf9106ae4f718ec9fc2011` | Verified |
| Chinese Language Syllabus | `323905446a4d04fabc32e05aeaa3bf97616afbde37b12c6c0d1aec7193e8f21d` | Verified |
