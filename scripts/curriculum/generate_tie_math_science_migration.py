#!/usr/bin/env python3
from __future__ import annotations

"""
Generate idempotent, natural-key-resolved Supabase SQL migration for official
TIE 2023 Primary Mathematics and Science syllabi (Standards III–VI).

Source documents (verified in repository):
  1. data/curriculum/tz/en-1727169918-SYLLABUS FOR MATHEMATICS PRIMARY EDUCATION.pdf
     ISBN: 978-9987-09-858-3 | 40 pages | First Edition 2023 (TIE / MoEST)
     SHA-256: baef25143a8133b1a435854134f0971133585bb8674d873ba99b83826a0e6eb8
  2. data/curriculum/tz/en-1727175605-Science Syllabus For Primary Education Standard III - VI.pdf
     ISBN: 978-9987-09-860-6 | 49 pages | First Edition 2023 (TIE / MoEST)
     SHA-256: f83ea3623f244c0505b6df390a797db9b014d0449ea99172d5622d1ab95f6157

Zero hardcoded UUIDs: resolves country, curriculum, curriculum_version,
education_level, and education_grades dynamically by stable natural keys.
"""

from pathlib import Path

SYLLABI = [
    {
        "subject_slug": "mathematics",
        "subject_name": "Mathematics",
        "official_prefix": "Mathematics Syllabus for Primary Education",
        "umbrella_code": "tie-pri-mathematics",
        "display_order": 4,
        "source_file": "data/curriculum/tz/en-1727169918-SYLLABUS FOR MATHEMATICS PRIMARY EDUCATION.pdf",
        "isbn": "978-9987-09-858-3",
        "sha256": "baef25143a8133b1a435854134f0971133585bb8674d873ba99b83826a0e6eb8",
        "standards": [
            {
                "grade_code": "STANDARD_3",
                "roman": "III",
                "weekly_periods": 6,
                "total_periods": 234,
                "main_competences": [
                    {
                        "code": "1.0",
                        "title": "Demonstrate mastery of elementary mathematical skills",
                        "specific": [
                            {
                                "code": "1.1",
                                "title": "Demonstrate an understanding of the concept of numbers",
                                "periods": 52,
                                "page": 8,
                                "criteria": "The value of a digit in multi-digit whole number is recognised",
                                "activities": [
                                    ("(a) Recognise the value of a digit in a multi-digit whole number", "The value of a digit in multi-digit whole number is recognised", 8),
                                    ("(b) Read and write multi-digit whole numbers", "Multi-digit whole numbers are correctly read and written", 8),
                                    ("(c) Compare whole numbers using symbols =, <, and >", "Whole numbers are correctly compared", 9),
                                    ("(d) Identify sequences in whole numbers", "Sequence of whole numbers is correctly identified", 9),
                                ],
                            },
                            {
                                "code": "1.2",
                                "title": "Demonstrate an understanding of basic numerical operations",
                                "periods": 30,
                                "page": 9,
                                "criteria": "Addition and subtraction of whole numbers is performed correctly",
                                "activities": [
                                    ("(a) Addition and subtraction of whole numbers", "Addition and subtraction of whole numbers is performed correctly", 9),
                                ],
                            },
                            {
                                "code": "1.3",
                                "title": "Demonstrate an understanding of measurements",
                                "periods": 22,
                                "page": 10,
                                "criteria": "Measurements of length, mass and volume are recognised accurately",
                                "activities": [
                                    ("(a) Recognise measurements of length, mass and volume", "Measurements of length, mass and volume are recognised accurately", 10),
                                ],
                            },
                            {
                                "code": "1.4",
                                "title": "Demonstrate an understanding of elementary geometry",
                                "periods": 30,
                                "page": 10,
                                "criteria": "The concept of shape is clearly explained",
                                "activities": [
                                    ("(a) Explain the concept of shape", "The concept of shape is clearly explained", 10),
                                    ("(b) Explain a point, line, line segment, and a ray", "Concept of a point, line, line segment and a ray are correctly explained", 11),
                                    ("(c) Construct plane figures using points, lines and line segments", "Plane figures are accurately constructed using point, line and line segment", 11),
                                ],
                            },
                            {
                                "code": "1.5",
                                "title": "Demonstrate an understanding of elementary mathematical skills",
                                "periods": 26,
                                "page": 12,
                                "criteria": "The concept of fraction is clearly explained using division of objects",
                                "activities": [
                                    ("(a) Use division of objects to explain the concept of fraction", "The concept of fraction is clearly explained using division of objects", 12),
                                    ("(b) Addition and subtraction of fractions of the same denominator", "Operations of addition and subtraction of fractions of the same denominator are performed correctly", 12),
                                ],
                            },
                        ],
                    },
                    {
                        "code": "2.0",
                        "title": "Demonstrate mastery of elementary application of mathematics",
                        "specific": [
                            {
                                "code": "2.1",
                                "title": "Demonstrate an understanding of the mathematics of time",
                                "periods": 36,
                                "page": 13,
                                "criteria": "Units of measuring time is clearly described",
                                "activities": [
                                    ("(a) Describe units of measuring time", "Units of measuring time is clearly described", 13),
                                    ("(b) Describe time in 12-hour format", "Time in 12-hour format is accurately described", 13),
                                    ("(c) Describe time in 24-hour format", "Time in 24-hour format is accurately described", 13),
                                    ("(d) Recognise number of hours in a day, days in a week, weeks in a month, months in a year", "Number of hours in a day, days in a week, weeks in a month, months in a year are correctly recognised", 14),
                                ],
                            },
                            {
                                "code": "2.2",
                                "title": "Demonstrate an understanding of financial mathematics",
                                "periods": 38,
                                "page": 14,
                                "criteria": "The denomination of Tanzanian currency in shillings and cents is clearly recognised",
                                "activities": [
                                    ("(a) Recognise the denomination of Tanzanian currency in shillings and cents", "The denomination of Tanzanian currency in shillings and cents is clearly recognised", 14),
                                    ("(b) Addition and subtraction of Tanzanian currency", "Operations of addition and subtraction of amounts of money in shillings and cents are performed correctly", 15),
                                ],
                            },
                        ],
                    },
                ],
            },
            {
                "grade_code": "STANDARD_4",
                "roman": "IV",
                "weekly_periods": 6,
                "total_periods": 234,
                "main_competences": [
                    {
                        "code": "1.0",
                        "title": "Demonstrate mastery of elementary mathematical skills",
                        "specific": [
                            {
                                "code": "1.1",
                                "title": "Demonstrate an understanding of the concept of numbers",
                                "periods": 12,
                                "page": 16,
                                "criteria": "Roman numbers are correctly recognised",
                                "activities": [
                                    ("(a) Recognise Roman numbers (up to M)", "Roman numbers are correctly recognised", 16),
                                ],
                            },
                            {
                                "code": "1.2",
                                "title": "Demonstrate an understanding of basic numerical operations",
                                "periods": 26,
                                "page": 16,
                                "criteria": "Whole numbers are correctly multiplied and divided",
                                "activities": [
                                    ("(a) Multiplication and division of whole numbers", "Whole numbers are correctly multiplied and divided", 16),
                                ],
                            },
                            {
                                "code": "1.3",
                                "title": "Demonstrate an understanding of measurements",
                                "periods": 38,
                                "page": 17,
                                "criteria": "Various components of the measures of length, mass, and volume are correctly converted",
                                "activities": [
                                    ("(a) Convert between the various components of the measures of length, mass, and volume (millimetres to kilometres, milligrams to tonnes, and millilitres to litres)", "Various components of the measures of length, mass, and volume are correctly converted", 17),
                                    ("(b) Addition and subtraction of measurements for length, mass and volume", "Addition and subtraction of measurement for length, mass and volume are correctly performed", 17),
                                ],
                            },
                            {
                                "code": "1.4",
                                "title": "Demonstrate an understanding of elementary geometry",
                                "periods": 32,
                                "page": 17,
                                "criteria": "Perimeters and areas of plane figures are calculated correctly",
                                "activities": [
                                    ("(a) Calculate the perimeters and areas of plane figures (rectangle, square and triangle)", "Perimeters and areas of plane figures are calculated correctly", 17),
                                ],
                            },
                            {
                                "code": "1.5",
                                "title": "Demonstrate an understanding of elementary mathematical skills",
                                "periods": 66,
                                "page": 18,
                                "criteria": "Comparing fractions by using =, <, and > is performed correctly",
                                "activities": [
                                    ("(a) Compare fractions by using =, <, and > signs", "Comparing fractions by using =, <, and > is performed correctly", 18),
                                    ("(b) Multiplication and division of fractions", "Multiplication and division of fractions are correctly performed", 18),
                                    ("(c) Explain the concept of decimals", "Concept of decimals is explained correctly", 18),
                                    ("(d) Addition and subtraction of decimals", "Addition and subtraction of decimals are performed correctly", 19),
                                ],
                            },
                        ],
                    },
                    {
                        "code": "2.0",
                        "title": "Demonstrate mastery of elementary application of mathematics",
                        "specific": [
                            {
                                "code": "2.1",
                                "title": "Demonstrate an understanding of the mathematics of time",
                                "periods": 34,
                                "page": 19,
                                "criteria": "Measures of time between their component are correctly converted",
                                "activities": [
                                    ("(a) Convert between the components of measures of time (seconds to hours)", "Measures of time between their component are correctly converted", 19),
                                    ("(b) Addition and subtraction of time", "Addition and subtraction of time is done correctly", 19),
                                ],
                            },
                            {
                                "code": "2.2",
                                "title": "Demonstrate an understanding of financial mathematics",
                                "periods": 26,
                                "page": 19,
                                "criteria": "Multiplication and division of Tanzanian currency is performed correctly",
                                "activities": [
                                    ("(a) Multiplication and division of Tanzanian currency", "Multiplication and division of Tanzanian currency is performed correctly", 19),
                                ],
                            },
                        ],
                    },
                ],
            },
            {
                "grade_code": "STANDARD_5",
                "roman": "V",
                "weekly_periods": 6,
                "total_periods": 240,
                "main_competences": [
                    {
                        "code": "1.0",
                        "title": "Demonstrate mastery of elementary mathematical skills",
                        "specific": [
                            {
                                "code": "1.1",
                                "title": "Demonstrate an understanding of measurements",
                                "periods": 44,
                                "page": 20,
                                "criteria": "Measurements for length, mass and volume are correctly multiplied",
                                "activities": [
                                    ("(a) Multiplication of measurements for length, mass and volume", "Measurements for length, mass and volume are correctly multiplied", 20),
                                    ("(b) Division of measurements for length, mass and volume", "Measurements for length, mass and volume are correctly divided", 20),
                                ],
                            },
                            {
                                "code": "1.2",
                                "title": "Demonstrate an understanding of elementary geometry",
                                "periods": 62,
                                "page": 21,
                                "criteria": "Concept of pi is correctly explained",
                                "activities": [
                                    ("(a) Explain the concept of pi", "Concept of pi is correctly explained", 21),
                                    ("(b) Calculate the circumference of a circle", "The circumference of a circle is correctly calculated", 21),
                                    ("(c) Calculate the area of a circle", "Area of a circle is correctly calculated", 21),
                                ],
                            },
                            {
                                "code": "1.3",
                                "title": "Demonstrate an understanding of elementary mathematical skills",
                                "periods": 68,
                                "page": 22,
                                "criteria": "Even, odd and prime numbers are correctly identified",
                                "activities": [
                                    ("(a) Identify even, odd and prime numbers", "Even, odd and prime numbers are correctly identified", 22),
                                    ("(b) Calculate factors and multiples of numbers not exceeding three digits", "Factors and multiples of numbers not exceeding three digits are correctly calculated", 22),
                                    ("(c) Calculate the Lowest Common Multiple (LCM) and Greatest Common Factor (GCF) of whole numbers", "Lowest Common Multiple (LCM) and Greatest Common Factor (GCF) of whole numbers are correctly calculated", 22),
                                    ("(d) Addition and subtraction of fractions with different denominators", "Fractions with different denominators are correctly added and subtracted", 23),
                                    ("(e) Addition and subtraction of mixed fractions", "Mixed fractions are correctly added and subtracted", 23),
                                    ("(f) Multiplication of decimals", "Decimals are correctly multiplied", 23),
                                    ("(g) Divide numbers to obtain an answer with no more than three decimal places", "Decimals to get answer with no more than three decimal places are correctly divided", 24),
                                    ("(h) Convert percentages into fractions and decimals", "Percentages into fractions and decimals are correctly identified", 24),
                                ],
                            },
                            {
                                "code": "1.4",
                                "title": "Demonstrate an elementary understanding of algebra",
                                "periods": 54,
                                "page": 25,
                                "criteria": "Concept of algebra is correctly explained",
                                "activities": [
                                    ("(a) Explain the concept of algebra", "Concept of algebra is correctly explained", 25),
                                    ("(b) Identify term, variables, and coefficients in algebraic expressions", "Term, variables, and coefficients of algebraic expressions are correctly identified", 25),
                                    ("(c) Write algebraic equations", "Algebraic equations are correctly written", 25),
                                    ("(d) Simplify algebraic expressions using the right sequence of mathematical operations", "Algebraic expressions using the right sequence of mathematical operations are correctly simplified", 26),
                                    ("(e) Calculate simple equations", "Simple algebraic equations are correctly calculated", 26),
                                ],
                            },
                        ],
                    },
                    {
                        "code": "2.0",
                        "title": "Demonstrate mastery of elementary application of mathematics",
                        "specific": [
                            {
                                "code": "2.1",
                                "title": "Demonstrate an understanding of financial mathematics",
                                "periods": 12,
                                "page": 27,
                                "criteria": "Problems involving sale and purchase correctly solved",
                                "activities": [
                                    ("(a) Solve problems involving sale and purchase", "Problems involving sale and purchase correctly solved", 27),
                                ],
                            },
                        ],
                    },
                ],
            },
            {
                "grade_code": "STANDARD_6",
                "roman": "VI",
                "weekly_periods": 6,
                "total_periods": 234,
                "main_competences": [
                    {
                        "code": "1.0",
                        "title": "Demonstrate mastery of elementary mathematical skills",
                        "specific": [
                            {
                                "code": "1.1",
                                "title": "Demonstrate an understanding of measurements",
                                "periods": 18,
                                "page": 28,
                                "criteria": "Problems involving distance and time are adequately solved",
                                "activities": [
                                    ("(a) Solve problems involving distance and time", "Problems involving distance and time are adequately solved", 28),
                                ],
                            },
                            {
                                "code": "1.2",
                                "title": "Demonstrate an understanding of elementary geometry",
                                "periods": 102,
                                "page": 28,
                                "criteria": "Area and volume of three-dimensional figures are correctly calculated",
                                "activities": [
                                    ("(a) Calculate the area and volume of three dimensional figures (rectangular parallelepiped, square parallelepiped and cylinder)", "Area and volume of three-dimensional figures are correctly calculated", 28),
                                    ("(b) Calculate degree of angles in plane figures (triangle, rectangle and circle)", "Degree of angles in plane figures are correctly calculated", 29),
                                    ("(c) Describe types of triangles and Pythagoras' theorem", "Types of triangles and Pythagoras' theorem are correctly described", 29),
                                ],
                            },
                            {
                                "code": "1.3",
                                "title": "Demonstrate an understanding of elementary mathematical skills",
                                "periods": 52,
                                "page": 30,
                                "criteria": "The square of a number is correctly calculated",
                                "activities": [
                                    ("(a) Calculate the square of a number", "The square of a number is correctly calculated", 30),
                                    ("(b) Calculate the square root of a number", "Square root of a number is calculated correctly", 30),
                                    ("(c) Explain the concept of integers", "Concept of integers is correctly explained", 30),
                                    ("(d) Perform operations in integers", "Operations with integers are correctly performed", 31),
                                ],
                            },
                        ],
                    },
                    {
                        "code": "2.0",
                        "title": "Demonstrate mastery of elementary application of mathematics",
                        "specific": [
                            {
                                "code": "2.1",
                                "title": "Demonstrate an understanding of elementary statistics and its applications",
                                "periods": 62,
                                "page": 32,
                                "criteria": "Concept of statistics is clearly explained",
                                "activities": [
                                    ("(a) Explain the concept of statistics", "Concept of statistics is clearly explained", 32),
                                    ("(b) Find the mean, median and mode of ungrouped data", "The mean, median and mode of ungrouped data is correctly calculated", 33),
                                    ("(c) Interpretation and presentation of data using statistical diagrams (pie charts and histograms)", "Data is accurately interpreted and presented using pie charts and histograms", 33),
                                ],
                            },
                        ],
                    },
                ],
            },
        ],
    },
    {
        "subject_slug": "science",
        "subject_name": "Science",
        "official_prefix": "Science Syllabus for Primary Education",
        "umbrella_code": "tie-pri-science",
        "display_order": 5,
        "source_file": "data/curriculum/tz/en-1727175605-Science Syllabus For Primary Education Standard III - VI.pdf",
        "isbn": "978-9987-09-860-6",
        "sha256": "f83ea3623f244c0505b6df390a797db9b014d0449ea99172d5622d1ab95f6157",
        "standards": [
            {
                "grade_code": "STANDARD_3",
                "roman": "III",
                "weekly_periods": 7,
                "total_periods": 175,
                "main_competences": [
                    {
                        "code": "1.0",
                        "title": "Demonstrate mastery of scientific theories",
                        "specific": [
                            {
                                "code": "1.1",
                                "title": "Demonstrate an elementary understanding of scientific theories",
                                "periods": 44,
                                "page": 8,
                                "criteria": "The concept of science is clearly explained",
                                "activities": [
                                    ("(a) Explain the concept of science (meaning and branches of science)", "The concept of science is clearly explained", 8),
                                    ("(b) Describe the human sensory organs", "Human sensory organs are clearly explained", 9),
                                ],
                            },
                            {
                                "code": "1.2",
                                "title": "Make simple scientific observations",
                                "periods": 44,
                                "page": 10,
                                "criteria": "Different objects in the environment are correctly identified",
                                "activities": [
                                    ("(a) Identify different objects in the environment", "Different objects in the environment are correctly identified", 10),
                                    ("(b) Identify living and non-living things", "Living and non-living things found in the environment are correctly identified", 10),
                                    ("(c) Identify the main groups of living things (plants and animals)", "Main groups of living things are clearly identified", 11),
                                ],
                            },
                        ],
                    },
                    {
                        "code": "2.0",
                        "title": "Demonstrate mastery of elementary scientific skills",
                        "specific": [
                            {
                                "code": "2.1",
                                "title": "Conduct simple scientific experiments",
                                "periods": 43,
                                "page": 12,
                                "criteria": "Steps for conducting scientific investigations are clearly described",
                                "activities": [
                                    ("(a) Describe basic steps in conducting a scientific investigation", "Steps for conducting scientific investigations are clearly described", 12),
                                    ("(b) Conduct elementary experiments on various living and non-living things", "Elementary experiments on various living and non-living things are correctly conducted", 13),
                                    ("(c) Care for living things in the environment", "Living things in the environment are properly cared for", 13),
                                ],
                            },
                        ],
                    },
                    {
                        "code": "3.0",
                        "title": "Demonstrate mastery of ICT skills",
                        "specific": [
                            {
                                "code": "3.1",
                                "title": "Use ICT for learning",
                                "periods": 44,
                                "page": 14,
                                "criteria": "ICT is properly used to play simple games that explain scientific phenomena and concepts",
                                "activities": [
                                    ("(a) Use ICT to play simple games that promote ability to explain scientific phenomena and concepts", "ICT is properly used to play simple games that explain scientific phenomena and concepts", 14),
                                ],
                            },
                        ],
                    },
                ],
            },
            {
                "grade_code": "STANDARD_4",
                "roman": "IV",
                "weekly_periods": 7,
                "total_periods": 175,
                "main_competences": [
                    {
                        "code": "1.0",
                        "title": "Demonstrate mastery of scientific theories",
                        "specific": [
                            {
                                "code": "1.1",
                                "title": "Demonstrate an elementary understanding of scientific theories",
                                "periods": 30,
                                "page": 16,
                                "criteria": "The basic principles of health are clearly explained",
                                "activities": [
                                    ("(a) Explain the basic principles of health (balanced diet, physical exercises, personal and environmental hygiene, safety signs and symbols)", "The basic principles of health are clearly explained", 16),
                                    ("(b) Describe types of common human diseases (modes of transmission, causes, control and preventions)", "Common types of human diseases and their control and prevention are clearly described", 17),
                                    ("(c) Explain the concept of matter (types and characteristics)", "The concept of matter (types and characteristics) is clearly explained", 18),
                                    ("(d) Explain the concept of combustion (meaning, causes and effects)", "The concept of combustion is clearly explained", 19),
                                ],
                            },
                            {
                                "code": "1.2",
                                "title": "Make simple scientific observations",
                                "periods": 30,
                                "page": 20,
                                "criteria": "Life cycles of insect vectors are clearly investigated",
                                "activities": [
                                    ("(a) Investigate the life cycle of insect vectors (housefly, cockroach and mosquito)", "Life cycles of insect vectors are clearly investigated", 20),
                                ],
                            },
                            {
                                "code": "1.3",
                                "title": "Demonstrate a basic understanding of types of energy and their uses",
                                "periods": 30,
                                "page": 21,
                                "criteria": "Types of energy and their uses are clearly described",
                                "activities": [
                                    ("(a) Describe types of energy (heat, light and sound energy) and their uses", "Types of energy and their uses are clearly described", 21),
                                ],
                            },
                        ],
                    },
                    {
                        "code": "2.0",
                        "title": "Demonstrate mastery of elementary scientific skills",
                        "specific": [
                            {
                                "code": "2.1",
                                "title": "Conduct elementary scientific experiments",
                                "periods": 30,
                                "page": 22,
                                "criteria": "Simple experiments on characteristics of matter are conducted correctly",
                                "activities": [
                                    ("(a) Conduct simple experiments to investigate the states of matter", "Simple experiments on characteristics of matter are conducted correctly", 22),
                                    ("(b) Conduct simple experiments to demonstrate importance of air in combustion", "Simple experiments on importance of air in combustion are correctly conducted", 23),
                                    ("(c) Conduct simple experiments on heat, light and sound energy", "Simple experiments on heat, light and sound energy are correctly conducted", 23),
                                ],
                            },
                        ],
                    },
                    {
                        "code": "3.0",
                        "title": "Demonstrate mastery of ICT skills",
                        "specific": [
                            {
                                "code": "3.1",
                                "title": "Use ICT for learning",
                                "periods": 25,
                                "page": 24,
                                "criteria": "ICT is used properly to draw and arrange various shapes in a logical sequence",
                                "activities": [
                                    ("(a) Use ICT to draw and arrange various shapes in a logical sequence", "ICT is used properly to draw and arrange various shapes in a logical sequence", 24),
                                ],
                            },
                        ],
                    },
                    {
                        "code": "4.0",
                        "title": "Design simple computer programmes",
                        "specific": [
                            {
                                "code": "4.1",
                                "title": "Design simple computer programmes",
                                "periods": 30,
                                "page": 25,
                                "criteria": "Simple games that use a single shape are correctly developed by using block-based programming languages",
                                "activities": [
                                    ("(a) Develop simple games that use a single shape by using block-based programming language", "Simple games that use a single shape are correctly developed by using block-based programming languages", 25),
                                ],
                            },
                        ],
                    },
                ],
            },
            {
                "grade_code": "STANDARD_5",
                "roman": "V",
                "weekly_periods": 6,
                "total_periods": 175,
                "main_competences": [
                    {
                        "code": "1.0",
                        "title": "Demonstrate mastery of scientific theories",
                        "specific": [
                            {
                                "code": "1.1",
                                "title": "Demonstrate an elementary understanding of scientific theories",
                                "periods": 45,
                                "page": 26,
                                "criteria": "Human digestive system is correctly explained",
                                "activities": [
                                    ("(a) Explain the human digestive system (meaning, parts and their functions)", "Human digestive system is correctly explained", 26),
                                    ("(b) Explain the human reproductive systems", "Female and male reproductive systems are correctly explained", 27),
                                    ("(c) Explain the growth in animals and plants", "Growth in animals and plants is clearly explained", 27),
                                    ("(d) Explain the stages of development of the human body", "Stages of development of human body are correctly explained", 28),
                                ],
                            },
                            {
                                "code": "1.2",
                                "title": "Demonstrate a basic understanding of types of energy and their uses",
                                "periods": 45,
                                "page": 29,
                                "criteria": "Concept of magnetism is correctly explained",
                                "activities": [
                                    ("(a) Explain the concept of magnetism (meaning, properties and applications)", "Concept of magnetism is correctly explained", 29),
                                ],
                            },
                        ],
                    },
                    {
                        "code": "2.0",
                        "title": "Demonstrate mastery of elementary scientific skills",
                        "specific": [
                            {
                                "code": "2.1",
                                "title": "Conduct elementary scientific experiments",
                                "periods": 45,
                                "page": 30,
                                "criteria": "Simple scientific experiments on growth in animals and plants are correctly conducted",
                                "activities": [
                                    ("(a) Conduct simple scientific experiments on growth in animals and plants", "Simple scientific experiments on growth in animals and plants are correctly conducted", 30),
                                    ("(b) Conduct simple experiments to demonstrate magnetic properties", "Simple experiments to demonstrate magnetic properties are correctly conducted", 31),
                                ],
                            },
                        ],
                    },
                    {
                        "code": "3.0",
                        "title": "Design simple computer programmes",
                        "specific": [
                            {
                                "code": "3.1",
                                "title": "Design simple computer programmes",
                                "periods": 40,
                                "page": 31,
                                "criteria": "Simple games of two shapes are correctly developed using block-based programming language",
                                "activities": [
                                    ("(a) Develop simple games that use two shapes using block-based programming language", "Simple games of two shapes are correctly developed using block-based programming language", 31),
                                ],
                            },
                        ],
                    },
                ],
            },
            {
                "grade_code": "STANDARD_6",
                "roman": "VI",
                "weekly_periods": 6,
                "total_periods": 175,
                "main_competences": [
                    {
                        "code": "1.0",
                        "title": "Demonstrate mastery of scientific theories",
                        "specific": [
                            {
                                "code": "1.1",
                                "title": "Demonstrate elementary understanding of scientific theories",
                                "periods": 45,
                                "page": 33,
                                "criteria": "Respiratory systems in animals and plants are clearly explained",
                                "activities": [
                                    ("(a) Explain respiratory systems in animals and plants (meaning, parts and mechanisms)", "Respiratory systems in animals and plants are clearly explained", 33),
                                    ("(b) Explain the concept of acids and bases (meaning, properties, source and uses)", "The concepts of acids and bases are clearly explained", 34),
                                    ("(c) Explain the concept of a machine (meaning, types and uses)", "The concept of a machine and its uses are clearly explained", 34),
                                    ("(d) Explain the concepts of floating and sinking", "The concepts of floating and sinking of objects are explained clearly", 35),
                                ],
                            },
                            {
                                "code": "1.2",
                                "title": "Demonstrate a basic understanding of types of energy and their uses",
                                "periods": 45,
                                "page": 36,
                                "criteria": "The concept of electricity is clearly explained",
                                "activities": [
                                    ("(a) Explain the concept of electricity (meaning, sources and uses)", "The concept of electricity is clearly explained", 36),
                                    ("(b) Describe simple electric circuit (parts, type, symbols and constructions)", "The concept of simple electric circuit is explained clearly", 37),
                                ],
                            },
                        ],
                    },
                    {
                        "code": "2.0",
                        "title": "Demonstrate mastery of elementary scientific skills",
                        "specific": [
                            {
                                "code": "2.1",
                                "title": "Conduct elementary scientific experiments",
                                "periods": 45,
                                "page": 38,
                                "criteria": "Experiments to identify acids and bases substances in the environment are correctly conducted",
                                "activities": [
                                    ("(a) Conduct simple experiments to identify acids and bases in the environment", "Experiments to identify acids and bases substances in the environment are correctly conducted", 38),
                                    ("(b) Conduct simple experiments about machines", "Simple experiments about machines are correctly conducted", 38),
                                    ("(c) Conduct simple experiments on floating or sinking", "Experiments to identify objects that float or sink are correctly conducted", 39),
                                    ("(d) Conduct experiments on simple electric circuits", "Experiments on simple electric circuits are correctly conducted", 39),
                                ],
                            },
                        ],
                    },
                    {
                        "code": "3.0",
                        "title": "Design simple computer programmes",
                        "specific": [
                            {
                                "code": "3.1",
                                "title": "Design simple computer programmes",
                                "periods": 40,
                                "page": 40,
                                "criteria": "Simple games that use more than two shapes are correctly developed using block-based programming languages",
                                "activities": [
                                    ("(a) Develop simple games that use more than two shapes using block-based programming languages", "Simple games that use more than two shapes are correctly developed using block-based programming languages", 40),
                                ],
                            },
                        ],
                    },
                ],
            },
        ],
    },
]


def sql_str(value: str | None) -> str:
    if value is None:
        return "null"
    return "'" + value.replace("'", "''") + "'"


def split_periods(total: int, count: int) -> list[int]:
    if count <= 0:
        return []
    base, rem = divmod(total, count)
    return [base + (1 if i < rem else 0) for i in range(count)]


def generate_sql() -> str:
    lines: list[str] = [
        "-- ============================================================================",
        "-- LearnTZ — Official TIE Primary Mathematics & Science Curriculum Ingestion",
        "-- Standards III, IV, V, and VI (2023 Competency-Based Syllabus Edition)",
        "--",
        "-- Authoritative Sources:",
        "--   1. Mathematics Syllabus for Primary School Education Standard III-VI (ISBN 978-9987-09-858-3)",
        "--      SHA-256: baef25143a8133b1a435854134f0971133585bb8674d873ba99b83826a0e6eb8",
        "--   2. Science Syllabus for Primary Education Standard III-VI (ISBN 978-9987-09-860-6)",
        "--      SHA-256: f83ea3623f244c0505b6df390a797db9b014d0449ea99172d5622d1ab95f6157",
        "--",
        "-- Uses 100% natural-key resolution (zero hardcoded grade/curriculum/level UUIDs).",
        "-- Fully idempotent and transaction-safe for fresh resets and repeated runs.",
        "-- ============================================================================",
        "",
        "begin;",
        "",
        "-- 1. Archive grade-less umbrella subjects superseded by grade-scoped Standards III-VI records",
        "update public.subjects",
        "set is_published = false,",
        "    description = 'Archived umbrella subject superseded by grade-scoped Standards III-VI subjects.'",
        "where country_code = 'TZ'",
        "  and code in ('tie-pri-mathematics', 'tie-pri-science')",
        "  and grade_id is null;",
        "",
        "-- 2. Record official syllabus traceability on curriculum_sources (natural key: sha256_checksum)",
        "update public.curriculum_sources",
        "set usage_rights_status = 'permission_pending',",
        "    usage_rights_reviewed_at = now(),",
        "    usage_rights_note = 'Competence codes, official titles, learning activities, and period allocations verified against official 2023 TIE Mathematics Syllabus (ISBN 978-9987-09-858-3).'",
        "where sha256_checksum = 'baef25143a8133b1a435854134f0971133585bb8674d873ba99b83826a0e6eb8';",
        "",
        "update public.curriculum_sources",
        "set usage_rights_status = 'permission_pending',",
        "    usage_rights_reviewed_at = now(),",
        "    usage_rights_note = 'Competence codes, official titles, learning activities, and period allocations verified against official 2023 TIE Science Syllabus (ISBN 978-9987-09-860-6).'",
        "where sha256_checksum = 'f83ea3623f244c0505b6df390a797db9b014d0449ea99172d5622d1ab95f6157';",
        "",
    ]

    for syl in SYLLABI:
        slug = syl["subject_slug"]
        subj_name = syl["subject_name"]
        official_prefix = syl["official_prefix"]
        disp_order = syl["display_order"]
        isbn = syl["isbn"]

        for std in syl["standards"]:
            grade_code = std["grade_code"]
            roman = std["roman"]
            grade_suffix = grade_code.lower().replace("_", "")
            subject_code = f"tie-pri-{slug}-{grade_suffix}"
            official_name = f"{official_prefix} — Standard {roman}"
            desc = (
                f"Official 2023 TIE {subj_name} syllabus for Standard {roman} "
                f"({std['total_periods']} periods, {std['weekly_periods']} periods/week; ISBN {isbn})."
            )

            lines.extend([
                f"-- ============================================================================",
                f"-- {subj_name} — Standard {roman} ({grade_code}): {std['total_periods']} periods",
                f"-- ============================================================================",
                "do $$",
                "declare",
                "  v_curriculum_id uuid;",
                "  v_level_id uuid;",
                "  v_grade_id uuid;",
                "  v_version_id uuid;",
                "  v_subject_id uuid;",
                "  v_main_id uuid;",
                "  v_topic_id uuid;",
                "begin",
                "  -- Natural-key resolution: Country (TZ) -> Curriculum (TIE) -> Level (PRIMARY) -> Grade",
                "  select id into v_curriculum_id",
                "  from public.curricula",
                "  where country_code = 'TZ' and code = 'TIE'",
                "  limit 1;",
                "  if v_curriculum_id is null then",
                "    raise exception 'Natural-key resolution failed: TZ TIE curriculum not found';",
                "  end if;",
                "",
                "  select id into v_level_id",
                "  from public.education_levels",
                "  where curriculum_id = v_curriculum_id and code = 'PRIMARY'",
                "  limit 1;",
                "  if v_level_id is null then",
                "    raise exception 'Natural-key resolution failed: PRIMARY education level not found for TIE curriculum';",
                "  end if;",
                "",
                "  select id into v_grade_id",
                "  from public.education_grades",
                f"  where curriculum_id = v_curriculum_id and education_level_id = v_level_id and code = {sql_str(grade_code)}",
                "  limit 1;",
                "  if v_grade_id is null then",
                f"    raise exception 'Natural-key resolution failed: education grade {grade_code} not found for TIE PRIMARY';",
                "  end if;",
                "",
                "  select id into v_version_id",
                "  from public.curriculum_versions",
                "  where curriculum_id = v_curriculum_id and version_code = 'TIE_PRIMARY_2023'",
                "  limit 1;",
                "",
                "  -- Upsert grade-scoped subject by natural key (curriculum_id, education_level_id, grade_id, code)",
                "  select id into v_subject_id",
                "  from public.subjects",
                "  where country_code = 'TZ'",
                "    and curriculum_id = v_curriculum_id",
                "    and education_level_id = v_level_id",
                "    and grade_id = v_grade_id",
                f"    and code = {sql_str(subject_code)};",
                "",
                "  if v_subject_id is null then",
                "    insert into public.subjects (",
                "      country_code, curriculum_id, education_level_id, grade_id,",
                "      code, name, official_name, description, display_order, is_published, classification, language",
                "    ) values (",
                f"      'TZ', v_curriculum_id, v_level_id, v_grade_id,",
                f"      {sql_str(subject_code)}, {sql_str(subj_name)}, {sql_str(official_name)}, {sql_str(desc)},",
                f"      {disp_order}, true, 'compulsory', 'en'",
                "    ) returning id into v_subject_id;",
                "  else",
                "    update public.subjects",
                f"    set name = {sql_str(subj_name)},",
                f"        official_name = {sql_str(official_name)},",
                f"        description = {sql_str(desc)},",
                f"        display_order = {disp_order},",
                "        is_published = true,",
                "        classification = 'compulsory',",
                "        language = 'en',",
                "        updated_at = now()",
                "    where id = v_subject_id;",
                "  end if;",
                "",
            ])

            topic_order = 0
            for mc_idx, mc in enumerate(std["main_competences"], start=1):
                mc_code = mc["code"]
                mc_title = mc["title"]
                mc_desc = f"Official 2023 TIE {subj_name} Standard {roman} Main Competence {mc_code} (ISBN {isbn})."

                lines.extend([
                    f"  -- Main Competence {mc_code}: {mc_title}",
                    "  insert into public.curriculum_main_competences (",
                    "    subject_id, curriculum_version_id, code, title, description, display_order, is_published",
                    "  ) values (",
                    f"    v_subject_id, v_version_id, {sql_str(mc_code)}, {sql_str(mc_title)}, {sql_str(mc_desc)}, {mc_idx}, true",
                    "  )",
                    "  on conflict (subject_id, code) do update",
                    "    set title = excluded.title,",
                    "        description = excluded.description,",
                    "        curriculum_version_id = coalesce(excluded.curriculum_version_id, curriculum_main_competences.curriculum_version_id),",
                    "        display_order = excluded.display_order,",
                    "        is_published = true,",
                    "        updated_at = now()",
                    "  returning id into v_main_id;",
                    "",
                ])

                for sc_idx, sc in enumerate(mc["specific"], start=1):
                    topic_order += 1
                    sc_code = sc["code"]
                    sc_title = sc["title"]
                    sc_periods = sc["periods"]
                    sc_page = sc["page"]
                    sc_criteria = sc["criteria"]
                    summary = (
                        f"Main Competence {mc_code}: {mc_title}. "
                        f"Specific Competence {sc_code}. Weekly allocation: {std['weekly_periods']} periods. "
                        f"Source: TIE 2023 {subj_name} Syllabus (ISBN {isbn}, p.{sc_page})."
                    )

                    lines.extend([
                        f"  -- Specific Competence {sc_code}: {sc_title}",
                        "  v_topic_id := null;",
                        "  select id into v_topic_id",
                        "  from public.topics",
                        f"  where subject_id = v_subject_id and competency_code = {sql_str(sc_code)};",
                        "",
                        "  if v_topic_id is null then",
                        "    insert into public.topics (",
                        "      subject_id, title, summary, display_order, is_published,",
                        "      competency_code, period_allocation, assessment_criteria, source_page",
                        "    ) values (",
                        f"      v_subject_id, {sql_str(sc_title)}, {sql_str(summary)}, {topic_order}, true,",
                        f"      {sql_str(sc_code)}, {sc_periods}, {sql_str(sc_criteria)}, {sc_page}",
                        "    ) returning id into v_topic_id;",
                        "  else",
                        "    update public.topics",
                        f"    set title = {sql_str(sc_title)},",
                        f"        summary = {sql_str(summary)},",
                        f"        display_order = {topic_order},",
                        f"        period_allocation = {sc_periods},",
                        f"        assessment_criteria = {sql_str(sc_criteria)},",
                        f"        source_page = {sc_page},",
                        "        is_published = true,",
                        "        updated_at = now()",
                        "    where id = v_topic_id;",
                        "  end if;",
                        "",
                        "  insert into public.curriculum_specific_competences (",
                        "    main_competence_id, subject_id, topic_id, code, title, description,",
                        "    period_allocation, assessment_criteria, source_page, display_order, is_published",
                        "  ) values (",
                        f"    v_main_id, v_subject_id, v_topic_id, {sql_str(sc_code)}, {sql_str(sc_title)}, {sql_str(summary)},",
                        f"    {sc_periods}, {sql_str(sc_criteria)}, {sc_page}, {sc_idx}, true",
                        "  )",
                        "  on conflict (topic_id) do update",
                        "    set main_competence_id = excluded.main_competence_id,",
                        "        code = excluded.code,",
                        "        title = excluded.title,",
                        "        description = excluded.description,",
                        "        period_allocation = excluded.period_allocation,",
                        "        assessment_criteria = excluded.assessment_criteria,",
                        "        source_page = excluded.source_page,",
                        "        display_order = excluded.display_order,",
                        "        is_published = true,",
                        "        updated_at = now();",
                        "",
                        "  -- Refresh official learning activity subtopics idempotently",
                        "  delete from public.subtopics where topic_id = v_topic_id;",
                    ])

                    act_periods = split_periods(sc_periods, len(sc["activities"]))
                    for a_idx, ((act_title, act_criteria, act_page), p_alloc) in enumerate(
                        zip(sc["activities"], act_periods), start=1
                    ):
                        lines.extend([
                            "  insert into public.subtopics (",
                            "    topic_id, title, description, learning_outcome, assessment_criteria,",
                            "    period_allocation, display_order, source_page, is_published",
                            "  ) values (",
                            f"    v_topic_id, {sql_str(act_title)}, {sql_str(f'TIE 2023 {subj_name} Standard {roman} (ISBN {isbn}, p.{act_page})')},",
                            f"    {sql_str(act_criteria)}, {sql_str(act_criteria)}, {p_alloc}, {a_idx}, {act_page}, true",
                            "  );",
                        ])
                    lines.append("")

            lines.extend(["end $$;", ""])

    lines.append("commit;")
    return "\n".join(lines) + "\n"


if __name__ == "__main__":
    out_path = Path(__file__).resolve().parents[2] / "supabase" / "migrations" / "20261119000200_tie_math_science_primary_curriculum_ingestion.sql"
    sql = generate_sql()
    out_path.write_text(sql, encoding="utf-8")
    print(f"Generated {out_path} ({len(sql.splitlines())} lines)")
