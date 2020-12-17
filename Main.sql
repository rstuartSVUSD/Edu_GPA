--Year term is a term that is matches the school year

WITH relTerms AS ( --Last 4 year terms
    SELECT 
        tcte.rel_terms 
        ,(SELECT DISTINCT name FROM terms WHERE terms.id = tcte.rel_terms AND terms.schoolid = 6052260 AND terms.isYearRec = 1) AS Year_Name
    FROM
            (SELECT
                id AS Current_Year
                ,id - 100 AS One_Year_Ago
                ,id - 200 AS Two_Years_Ago
                ,id - 300 AS Three_Years_Ago
                ,id - 400 AS Four_Years_Ago
            FROM terms t
            WHERE 
                t.firstday <= SYSDATE
                AND t.lastday >= SYSDATE
                AND t.schoolid = 6052260 --Avoids duplicate term IDs from other schools
                AND t.isYearRec = 1)
        UNPIVOT (
            rel_terms
            FOR term_name IN (Current_Year, One_Year_Ago, Two_Years_Ago, Three_Years_Ago, Four_Years_Ago)
            ) tcte
), 
grades AS (SELECT --Selects storedgrades from last 4 year termids
                    *
                FROM
                    storedgrades sg
                WHERE
                    sg.termid IN (SELECT rel_terms FROM relTerms)
) 
                


SELECT 
    pse.studentid
    ,(SELECT name FROM terms WHERE terms.yearid = pse.yearid AND terms.isyearrec = 1 AND terms.schoolid = 6052260) AS School_Year
    ,pse.schoolname
    ,(CASE
        WHEN pse.grade_level < 9 THEN 'Trimesters'
        ELSE 'Semesters'
        END) AS GPA_Calc_Method
    --FIX ME: Calculate GPA for (S1 and S2) or (T1, T2 and T3) depending on pse grade level
FROM PSRW_SchoolEnrollment  pse
WHERE
    pse.grade_level > 5 --No grades for elementary students
    AND pse.yearid IN (SELECT SUBSTR(rel_terms, 1, 2) FROM relTerms) --Students from the past 4 years;
