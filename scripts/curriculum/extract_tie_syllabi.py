#!/usr/bin/env python3
"""
LearnTZ — Official TIE Curriculum Document Extraction Pipeline
Extracts structured curriculum data, topics, competencies, learning outcomes,
and period allocations from official Tanzania Institute of Education (TIE) 2023 PDFs.
"""

import os
import sys
import glob
import json
import re
import hashlib

# Ensure pypdf can be loaded
sys.path.insert(0, '/tmp/pypdf_lib')
from pypdf import PdfReader

TIE_DOCS_METADATA = {
    "en-1724244732-Curriculum for Primary Education.pdf": {
        "title": "Curriculum for Primary Education Standard I - VI",
        "swahili_title": "Mtaala wa Elimu ya Msingi Darasa la I - VI",
        "subject_name": "General Curriculum Framework",
        "subject_code": "TZ-TIE-PRI-FRAMEWORK",
        "language": "en",
        "isbn": "978-9987-09-852-1",
        "publication_year": 2023,
        "is_framework": True,
        "classification": "compulsory",
        "grades": ["Standard I", "Standard II", "Standard III", "Standard IV", "Standard V", "Standard VI"]
    },
    "en-1727083562-PRIMARY EDUCATION SYLLABUS STD 1-II FINAL.pdf": {
        "title": "Primary Education Syllabus Standard I – II",
        "swahili_title": "Muhtasari wa Elimu ya Msingi Darasa la I – II",
        "subject_name": "Foundational Learning (3Rs, Health, Arts)",
        "subject_code": "TZ-TIE-PRI-STD1-2",
        "language": "en",
        "isbn": "978-9987-09-837-8",
        "publication_year": 2023,
        "is_framework": False,
        "classification": "compulsory",
        "grades": ["Standard I", "Standard II"]
    },
    "sw-1727177907-MUHTASARI SOMO KISWAHILI DRS III - VI.pdf": {
        "title": "Muhtasari wa Somo la Kiswahili Elimu ya Msingi Darasa la III–VI",
        "swahili_title": "Muhtasari wa Somo la Kiswahili Elimu ya Msingi Darasa la III–VI",
        "subject_name": "Kiswahili",
        "subject_code": "TZ-TIE-PRI-KISW",
        "language": "sw",
        "isbn": "978-9987-09-782-1",
        "publication_year": 2023,
        "is_framework": False,
        "classification": "compulsory",
        "grades": ["Standard III", "Standard IV", "Standard V", "Standard VI"]
    },
    "sw-1727168466-ENGLISH Syllabus III-VI FINAL.pdf": {
        "title": "English Language Syllabus for Primary Education Standard III─VI",
        "swahili_title": "Muhtasari wa Lugha ya Kiingereza Elimu ya Msingi Darasa la III─VI",
        "subject_name": "English Language",
        "subject_code": "TZ-TIE-PRI-ENG",
        "language": "en",
        "isbn": "978-9987-09-726-5",
        "publication_year": 2023,
        "is_framework": False,
        "classification": "compulsory",
        "grades": ["Standard III", "Standard IV", "Standard V", "Standard VI"]
    },
    "en-1727169918-SYLLABUS FOR MATHEMATICS PRIMARY EDUCATION.pdf": {
        "title": "Mathematics Syllabus for Primary School Education Standard III-VI",
        "swahili_title": "Muhtasari wa Somo la Hisabati Elimu ya Msingi Darasa la III-VI",
        "subject_name": "Mathematics",
        "subject_code": "TZ-TIE-PRI-MATH",
        "language": "en",
        "isbn": "978-9987-09-858-3",
        "publication_year": 2023,
        "is_framework": False,
        "classification": "compulsory",
        "grades": ["Standard III", "Standard IV", "Standard V", "Standard VI"]
    },
    "en-1727175605-Science Syllabus For Primary Education Standard III - VI.pdf": {
        "title": "Science Syllabus for Primary Education Standard III─VI",
        "swahili_title": "Muhtasari wa Sayansi na Teknolojia Elimu ya Msingi Darasa la III─VI",
        "subject_name": "Science and Technology",
        "subject_code": "TZ-TIE-PRI-SCI",
        "language": "en",
        "isbn": "978-9987-09-860-6",
        "publication_year": 2023,
        "is_framework": False,
        "classification": "compulsory",
        "grades": ["Standard III", "Standard IV", "Standard V", "Standard VI"]
    },
    "en-1727166774-GEOGRAPHY STANDARD III-VI .pdf": {
        "title": "Geography and the Environment Syllabus for Primary Education Standard III – VI",
        "swahili_title": "Muhtasari wa Jiografia na Mazingira Elimu ya Msingi Darasa la III – VI",
        "subject_name": "Geography and Environment",
        "subject_code": "TZ-TIE-PRI-GEO",
        "language": "en",
        "isbn": "978-9987-09-859-0",
        "publication_year": 2023,
        "is_framework": False,
        "classification": "compulsory",
        "grades": ["Standard III", "Standard IV", "Standard V", "Standard VI"]
    },
    "sw-1788263951-KAMISHINA Muhtasari historia ya Tanzania na Maadili A.pdf": {
        "title": "Muhtasari wa Somo la Historia ya Tanzania na Maadili Elimu ya Msingi Darasa la III-VI",
        "swahili_title": "Muhtasari wa Somo la Historia ya Tanzania na Maadili Elimu ya Msingi Darasa la III-VI",
        "subject_name": "Historia ya Tanzania na Maadili",
        "subject_code": "TZ-TIE-PRI-HIST",
        "language": "sw",
        "isbn": "978-9987-09-795-1",
        "publication_year": 2023,
        "is_framework": False,
        "classification": "compulsory",
        "grades": ["Standard III", "Standard IV", "Standard V", "Standard VI"]
    },
    "en-1727176628-SPORT and Arts Primary Education Syllabus III -  VI.pdf": {
        "title": "Arts and Sports Syllabus for Primary Education Standard III─VI",
        "swahili_title": "Muhtasari wa Sanaa na Michezo Elimu ya Msingi Darasa la III─VI",
        "subject_name": "Arts and Sports",
        "subject_code": "TZ-TIE-PRI-ARTS",
        "language": "en",
        "isbn": "978-9987-09-857-6",
        "publication_year": 2023,
        "is_framework": False,
        "classification": "compulsory",
        "grades": ["Standard III", "Standard IV", "Standard V", "Standard VI"]
    },
    "sw-1727176969-MUHTASARI WA LUGHA YA KICHINA ELIMU YA MSINGI III - VI.pdf": {
        "title": "Muhtasari wa Lugha ya Kichina Elimu ya Msingi Darasa la III–VI",
        "swahili_title": "Muhtasari wa Lugha ya Kichina Elimu ya Msingi Darasa la III–VI",
        "subject_name": "Chinese Language",
        "subject_code": "TZ-TIE-PRI-CHIN",
        "language": "sw",
        "isbn": "978-9987-09-844-6",
        "publication_year": 2023,
        "is_framework": False,
        "classification": "elective",
        "grades": ["Standard III", "Standard IV", "Standard V", "Standard VI"]
    }
}

def compute_sha256(filepath):
    h = hashlib.sha256()
    with open(filepath, 'rb') as f:
        while chunk := f.read(8192):
            h.update(chunk)
    return h.hexdigest()

def extract_document(filepath):
    filename = os.path.basename(filepath)
    meta = TIE_DOCS_METADATA.get(filename, {})
    reader = PdfReader(filepath)
    num_pages = len(reader.pages)
    checksum = compute_sha256(filepath)
    filesize = os.path.getsize(filepath)

    doc_data = {
        "filename": filename,
        "title": meta.get("title", filename),
        "swahili_title": meta.get("swahili_title", filename),
        "subject_name": meta.get("subject_name", "General"),
        "subject_code": meta.get("subject_code", "TZ-TIE-PRI"),
        "classification": meta.get("classification", "compulsory"),
        "language": meta.get("language", "en"),
        "isbn": meta.get("isbn"),
        "publication_year": meta.get("publication_year", 2023),
        "publisher": "Tanzania Institute of Education (TIE)",
        "country_code": "TZ",
        "education_level": "Primary Education",
        "grades": meta.get("grades", []),
        "file_sha256": checksum,
        "file_size_bytes": filesize,
        "page_count": num_pages,
        "pages": [],
        "competence_summary": [],
        "detailed_standards": {}
    }

    # Extract all pages text
    for page_idx in range(num_pages):
        page = reader.pages[page_idx]
        text = page.extract_text() or ''
        doc_data["pages"].append({
            "page_number": page_idx + 1,
            "text": text,
            "char_count": len(text)
        })

    # Parse Table 1 (Competence summary) if available
    # Typically pages 4-12
    comp_pattern = re.compile(r'(\d+\.0\s+[^\n]+(?:\n(?!\d+\.\d)[^\n]+)*)\s+(\d+\.\d\s+[^\n]+)', re.MULTILINE)
    
    # Identify standard blocks in detailed content
    # E.g. "Standard III", "Table 2: Contents for Standard III", "Darasa la III", "Jedwali Na. 2"
    std_regex = re.compile(r'(Standard\s+(?:I|II|III|IV|V|VI)|Darasa\s+la\s+(?:I|II|III|IV|V|VI))', re.IGNORECASE)

    current_std = None
    for p in doc_data["pages"]:
        p_num = p["page_number"]
        txt = p["text"]
        
        matches = std_regex.findall(txt)
        if matches:
            for m in matches:
                normalized_std = m.title()
                if 'Darasa La' in normalized_std:
                    # Map to Standard
                    num_part = normalized_std.replace('Darasa La', '').strip()
                    normalized_std = f'Standard {num_part}'
                if normalized_std not in doc_data["detailed_standards"]:
                    doc_data["detailed_standards"][normalized_std] = []
                current_std = normalized_std

        # Extract period count lines like "52", "60", "Idadi ya vipindi"
        period_match = re.findall(r'\b(Periods|Vipindi)[:\s]+(\d+)\b', txt, re.IGNORECASE)
        # Check for main competence headers
        mc_matches = re.findall(r'(\d+\.0\s+[A-Z][^\n]{10,120})', txt)
        sc_matches = re.findall(r'(\d+\.\d\s+[A-Z][^\n]{10,120})', txt)

        if current_std and (mc_matches or sc_matches):
            doc_data["detailed_standards"][current_std].append({
                "page": p_num,
                "main_competences": mc_matches,
                "specific_competences": sc_matches,
                "periods": [p[1] for p in period_match] if period_match else []
            })

    return doc_data

def main():
    data_dir = 'data/curriculum/tz'
    output_dir = 'data/curriculum/tz_extracted'
    os.makedirs(output_dir, exist_ok=True)

    files = sorted(glob.glob(os.path.join(data_dir, '*.pdf')))
    if not files:
        print(f"No PDF files found in {data_dir}")
        sys.exit(1)

    print(f"Discovered {len(files)} TIE syllabus PDF files. Processing...")
    
    master_catalog = []

    for idx, filepath in enumerate(files, 1):
        filename = os.path.basename(filepath)
        print(f"[{idx}/{len(files)}] Processing {filename}...")
        doc_data = extract_document(filepath)
        
        # Save individual extracted JSON
        out_name = os.path.splitext(filename)[0] + '.json'
        out_path = os.path.join(output_dir, out_name)
        with open(out_path, 'w', encoding='utf-8') as out_f:
            json.dump(doc_data, out_f, indent=2, ensure_ascii=False)
            
        print(f"   -> Extracted {doc_data['page_count']} pages, ISBN: {doc_data['isbn']}, Standards: {list(doc_data['detailed_standards'].keys())}")
        
        master_catalog.append({
            "filename": filename,
            "title": doc_data["title"],
            "swahili_title": doc_data["swahili_title"],
            "subject_name": doc_data["subject_name"],
            "subject_code": doc_data["subject_code"],
            "classification": doc_data["classification"],
            "language": doc_data["language"],
            "isbn": doc_data["isbn"],
            "publication_year": doc_data["publication_year"],
            "publisher": doc_data["publisher"],
            "sha256": doc_data["file_sha256"],
            "size_bytes": doc_data["file_size_bytes"],
            "page_count": doc_data["page_count"],
            "standards_covered": doc_data["grades"]
        })

    # Save Master Catalog
    catalog_path = os.path.join(output_dir, 'tie_primary_master_catalog.json')
    with open(catalog_path, 'w', encoding='utf-8') as cat_f:
        json.dump(master_catalog, cat_f, indent=2, ensure_ascii=False)

    print("\nExtraction complete! Master catalog saved to:", catalog_path)

if __name__ == '__main__':
    main()
