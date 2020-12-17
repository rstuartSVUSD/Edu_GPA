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
),
gpaTerms AS (SELECT 'Semesters' AS term_type, 'S1' AS Storecode FROM dual
             UNION
             SELECT 'Semesters' AS term_type, 'S2' AS Storecode FROM dual
             UNION
             SELECT 'Trimesters' AS term_type, 'T1' AS Storecode FROM dual
             UNION
             SELECT 'Trimesters' AS term_type, 'T2' AS Storecode FROM dual
             UNION
             SELECT 'Trimesters' AS term_type, 'T3' AS Storecode FROM dual)

SELECT
    e.studentid
    ,stu.student_number
    ,e.school_year
    ,e.yearid
    ,e.schoolname
    ,e.schoolid
    ,e.gpa_term_method
    ,gpaterms.storecode
    ,(SELECT 
            ROUND(
                SUM(DECODE(grade,'A+',4,'A',4,'A-',4,'B+',3,'B',3,'B-',3,'C+',2,'C',2,'C-',2,'D+',1,'D',1,'D-',1,'F',0))
                / GREATEST(SUM(DECODE(grade,'A+',1,'A',1,'A-',1,'B+',1,'B',1,'B-',1,'C+',1,'C',1,'C-',1,'D+',1,'D',1,'D-',1,'F',1)),0.001)
            ,2)
      FROM storedgrades sg 
      WHERE 
            sg.studentid = e.studentid 
            AND sg.schoolid = e.schoolid 
            AND sg.termid = (e.yearid || '00') 
            AND sg.storecode = gpaterms.storecode 
            AND sg.excludefromgpa = 0) AS GPA
FROM 
    (SELECT 
        pse.studentid
        ,(SELECT name FROM terms WHERE terms.yearid = pse.yearid AND terms.isyearrec = 1 AND terms.schoolid = 6052260) AS School_Year
        ,pse.yearid
        ,pse.schoolname
        ,pse.schoolid
        ,(CASE
            WHEN pse.grade_level < 9 THEN 'Trimesters'
            ELSE 'Semesters'
            END) AS GPA_Term_Method
        --FIX ME: Calculate GPA for (S1 and S2) or (T1, T2 and T3) depending on pse grade level
    FROM PSRW_SchoolEnrollment  pse
    WHERE
        pse.grade_level > 5 --No grades for elementary students
        AND pse.yearid IN (SELECT SUBSTR(rel_terms, 1, 2) FROM relTerms) --Students from the past 4 years
    ) e
JOIN gpaTerms ON gpaTerms.term_type = e.GPA_term_Method
JOIN students stu ON stu.id = e.studentid
