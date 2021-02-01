USE DatabaseName1;

------- For each DRecNo get the names of the active ingredients (a list of names of substances of the different combinations)

DROP TABLE IF EXISTS DatabaseName2.SDGProject.DrecnoSubstring;
	SELECT DS.Drecno, 
       STRING_AGG(S.Name, ';') AS Name
INTO DatabaseName2.SDGProject.DrecnoSubstring
	FROM SchemaName2.DrecnoSubstance AS DS
        JOIN SchemaName2.Substance AS S ON S.SubstanceID = DS.SubstanceID AND S.IsPreferred = 1
    WHERE DS.Seq1 = '01'
    GROUP BY DS.Drecno
ORDER BY 1;

select * from DatabaseName2.SDGProject.DrecnoSubstring

Select * 
FROM DatabaseName2.SDGProject.DrecnoSubstring DS
JOIN SchemaName2.Product	PR ON PR.Drecno = DS.Drecno AND PR.Seq1='01' AND PR.Seq2='001'
where DS.Name != PR.Name

-- I would recommend to use SchemaName2.Product instead
/*
DROP TABLE IF EXISTS #DrecnoSubstring
CREATE TABLE #DrecnoSubstring (
	Drecno char(6) primary key,
	Name nvarchar(1500)
)
INSERT INTO #DrecnoSubstring
SELECT DISTINCT Drecno, Name
	FROM SchemaName2.Product
	WHERE Seq1='01' AND SEQ2='001' 

-- basically instantaneous -- 26211 rows
*/

GO

DROP TABLE IF EXISTS DatabaseName2.SDGProject.DrugsCountYearly;
CREATE TABLE DatabaseName2.SDGProject.DrugsCountYearly (
	Year INT,
	Drecno char(6),
	SubstanceName nvarchar(1500),
	NDrug INT,
	Primary key (Year, Drecno)
)
INSERT INTO DatabaseName2.SDGProject.DrugsCountYearly
SELECT YEAR(R.DateInDatabase) AS 'Year', 
       WP.Drecno, 
       DrecnoSubst.Name AS                        SubstanceName, 
       COUNT(DISTINCT R.ReportsID) AS              NDrug

    FROM SchemaName1.Reports AS R
         JOIN SchemaName1.Drugs AS D ON D.ReportsID = R.ReportsID
         JOIN SchemaName2.Product AS WP ON WP.ProductID = D.UMCValidated_ProductID
         JOIN DatabaseName2.SDGProject.DrecnoSubstring AS DrecnoSubst ON DrecnoSubst.Drecno = WP.Drecno collate SQL_Latin1_General_CP1_CI_AS
    WHERE 1 = 1
          AND R.IsForeignCase = 0
          AND ( R.PreferredCase_ReportID IS NULL OR R.PreferredCase_ReportID = R.ReportsID )
          AND D.CharacterizationID IN ( 1, 3 )
          --AND DrecnoSubst.Name = 'Diclofenac'
    GROUP BY YEAR(R.DateInDatabase), 
             WP.Drecno, 
             DrecnoSubst.Name
	ORDER BY Year

-- Took 29s -- 164168 rows


-- For testing
Select * from DatabaseName2.SDGProject.DrugsCountYearly
where SubstanceName='Metformin'
order by year 


GO
------

DROP TABLE IF EXISTS DatabaseName2.SDGProject.ReactionCountYearly
CREATE TABLE DatabaseName2.SDGProject.ReactionCountYearly (
	Year INT,
	PT_CODE INT,
	ReactionName nvarchar(1500),
	NReaction INT,
	Primary key (Year, PT_CODE)
)
INSERT INTO DatabaseName2.SDGProject.ReactionCountYearly
SELECT YEAR(R.DateInDatabase) AS             'Year', 
       MED.PT_CODE, 
       MED.PT_NAME AS             ReactionName, 
       COUNT(DISTINCT R.ReportsID) AS NReaction
    FROM SchemaName1.Reports AS R
		JOIN SchemaName1.Reaction AS RE ON RE.ReportsID = R.ReportsID
		JOIN Meddra.Meddra.MEDDRA_MD_HIERARCHY AS MED ON MED.PT_CODE = RE.UMCValidated_ReactionMeddraPtCode AND MED.PRIMARY_SOC_FG = 'Y'
	WHERE 1=1
		AND R.IsForeignCase = 0
		AND (R.PreferredCase_ReportID is NULL or R.PreferredCase_ReportID = R.ReportsID)
		--AND MED.PT_NAME = 'Rash'
    GROUP BY YEAR(R.DateInDatabase), 
             MED.PT_CODE, 
             MED.PT_NAME

-- Took 12s -- 234189 rows



-- for testing
Select * from DatabaseName2.SDGProject.ReactionCountYearly
where ReactionName='Rash'
order by year

GO
---- 


-- year x D x E
DROP TABLE IF EXISTS DatabaseName2.SDGProject.nObservedPerYear
CREATE TABLE DatabaseName2.SDGProject.nObservedPerYear (
	Year INT,
	Drecno char(6),
	SubstanceName nvarchar(1500),
	PT_CODE INT,
	ReactionName nvarchar(1500),
	NObserved INT,
	Primary key (Year, Drecno, PT_CODE)
)
INSERT INTO DatabaseName2.SDGProject.nObservedPerYear
SELECT DISTINCT 
       YEAR(R.DateInDatabase) AS            'Year', 
       WP.Drecno, 
       DrecnoSubst.Name AS SubstanceName, 
       MED.PT_CODE, 
       MED.PT_NAME AS             ReactionName, 
       COUNT(DISTINCT R.ReportsID) AS NObserved
    FROM SchemaName1.Reports AS R
         JOIN SchemaName1.Drugs AS D ON D.ReportsID = R.ReportsID
		 JOIN SchemaName2.Product AS WP ON WP.ProductID = D.UMCValidated_ProductID
		 JOIN DatabaseName2.SDGProject.DrecnoSubstring AS DrecnoSubst ON DrecnoSubst.Drecno = WP.Drecno collate SQL_Latin1_General_CP1_CI_AS
         JOIN SchemaName1.Reaction AS RE ON RE.ReportsID = R.ReportsID
		 JOIN Meddra.Meddra.MEDDRA_MD_HIERARCHY AS MED ON MED.PT_CODE = RE.UMCValidated_ReactionMeddraPtCode AND MED.PRIMARY_SOC_FG = 'Y'
	WHERE 1=1
		AND R.IsForeignCase = 0
		AND (R.PreferredCase_ReportID is NULL or R.PreferredCase_ReportID = R.ReportsID)
		AND D.CharacterizationID in (1,3)
		--AND DrecnoSubst.Name in ('Paracetamol')
		--AND MED.PT_NAME = 'Rash'
    GROUP BY YEAR(R.DateInDatabase), 
             WP.Drecno, 
             DrecnoSubst.Name, 
             MED.PT_CODE, 
             MED.PT_NAME

-- Took 2:17 -- 10,750,914 rows

-- for testing
-- checked in VigiLyze, seem to follow the number of reports given over time
-- (not perfect, because duplicates are included in new VigiLyze)
select * from DatabaseName2.SDGProject.nObservedPerYear
where SubstanceName='Metformin' and ReactionName = 'Nausea'
order by year





GO

----


DROP TABLE IF EXISTS DatabaseName2.SDGProject.TotalCountYearly;
create table DatabaseName2.SDGProject.TotalCountYearly (
	year INT Primary key,
	Ntot INT
)
INSERT INTO DatabaseName2.SDGProject.TotalCountYearly
	SELECT YEAR(R.DateInDatabase) AS            'Year', 
       COUNT(DISTINCT R.ReportsID) AS Ntot
    FROM SchemaName1.Reports AS R
	WHERE 1=1
		AND R.IsForeignCase = 0
		AND (R.PreferredCase_ReportID is NULL or R.PreferredCase_ReportID = R.ReportsID)
    GROUP BY YEAR(R.DateInDatabase)

-- Took 1s -- 53 rows

-- for testing
select * from DatabaseName2.SDGProject.TotalCountYearly

GO




-- Y x D x R
-----------------------------------------------------
DROP TABLE IF EXISTS DatabaseName2.SDGProject.AllCountsYearCombination;
CREATE TABLE DatabaseName2.SDGProject.AllCountsYearCombination (
	year INT,
	Drecno char(6),
	SubstanceName nvarchar(1500),
	PT_CODE INT,
	ReactionName nvarchar(1500),
	NObserved INT,
	NDrug INT,
	NReaction INT,
	Ntot INT
	primary key (year, Drecno, PT_CODE)
)
INSERT INTO DatabaseName2.SDGProject.AllCountsYearCombination
SELECT OY.[Year], 
       OY.Drecno, 
       OY.SubstanceName, 
       OY.PT_CODE, 
       OY.ReactionName, 
       OY.NObserved, 
       DY.NDrug, 
       RY.NReaction,
	   TY.Ntot
    FROM DatabaseName2.SDGProject.nObservedPerYear AS		OY
    JOIN DatabaseName2.SDGProject.DrugsCountYearly AS		DY ON DY.Drecno = OY.Drecno  AND DY.[Year] = OY.[Year]
    JOIN DatabaseName2.SDGProject.ReactionCountYearly AS	RY ON RY.Year = OY.Year AND RY.PT_CODE = OY.PT_CODE
	JOIN DatabaseName2.SDGProject.TotalCountYearly			TY ON TY.Year = OY.Year
ORDER BY OY.[Year];

-- Took 37s -- 10,750,914 rows (as expected, should be the same number of rows as #nObservedPerYear)

-- For testing
select * from DatabaseName2.SDGProject.AllCountsYearCombination
where SubstanceName='Diclofenac' and ReactionName = 'Nausea'
order by year

GO
----





-- I don't think you need this one
-- you have all you need from the table above.
-- It's best to replicate data as little as possible
/*
DROP TABLE IF EXISTS DatabaseName2.SDGProject.allPossibleCombinations;

SELECT DISTINCT 
       DRecNo, 
       SubstanceName, 
       PT_CODE, 
       ReactionName
INTO DatabaseName2.SDGProject.allPossibleCombinations
    FROM DatabaseName2.SDGProject.nObservedPerYear AS OY;

GO
---
*/





----
----

DROP TABLE IF EXISTS DatabaseName2.SDGProject.CumulCountsAll
CREATE TABLE DatabaseName2.SDGProject.CumulCountsAll (
	Year INT PRIMARY KEY,
	CumulNTot INT
)
INSERT INTO DatabaseName2.SDGProject.CumulCountsAll
SELECT TCY1.Year, SUM(TCY2.Ntot)
	FROM DatabaseName2.SDGProject.TotalCountYearly			TCY1
	CROSS JOIN DatabaseName2.SDGProject.TotalCountYearly	TCY2
	WHERE TCY2.Year<=TCY1.Year
	GROUP BY TCY1.Year
-- Instantaneous -- 53 rows

-- for testing
SELECT * 
FROM DatabaseName2.SDGProject.CumulCountsAll CCA
JOIN DatabaseName2.SDGProject.TotalCountYearly TCY ON TCY.Year = CCA.Year
-- seems to work
select * from DatabaseName2.SDGProject.TotalCountYearly





DROP TABLE IF EXISTS DatabaseName2.SDGProject.CumulCountsDrug
CREATE TABLE DatabaseName2.SDGProject.CumulCountsDrug (
	Year INT,
	Drecno char(6),
	CumNDrug INT,
	PRIMARY KEY (Year, Drecno)
)
INSERT INTO DatabaseName2.SDGProject.CumulCountsDrug
SELECT TCY.year
	, DS.Drecno
	, SUM(ISNULL(DCY.NDrug, 0))
	FROM DatabaseName2.SDGProject.TotalCountYearly			TCY
	CROSS JOIN DatabaseName2.SDGProject.DrecnoSubstring		DS
	LEFT JOIN DatabaseName2.SDGProject.DrugsCountYearly		DCY ON (DCY.Drecno collate SQL_Latin1_General_CP1_CI_AS = DS.Drecno AND DCY.Year<=TCY.year)
	GROUP BY TCY.Year, DS.Drecno
	ORDER BY TCY.year, DS.Drecno

-- Took 2s -- 1,389,183 rows which is, as expected, 53*26211


-- for testing
select * 
from DatabaseName2.SDGProject.CumulCountsDrug	CCD
LEFT JOIN DatabaseName2.SDGProject.DrugsCountYearly	DCY ON DCY.Drecno = CCD.Drecno AND DCY.Year = CCD.Year
WHERE CCD.Drecno='002377'
ORDER BY CCD.Year
-- seems ok by keep in mind that the CumulNDrug NULLs are representing 0

GO




DROP TABLE IF EXISTS DatabaseName2.SDGProject.CumulCountsReaction
CREATE TABLE DatabaseName2.SDGProject.CumulCountsReaction (
	Year INT,
	PT_CODE INT,
	CumulNReaction INT,
	Primary key (Year, PT_CODE)
)
INSERT INTO DatabaseName2.SDGProject.CumulCountsReaction
SELECT TCY.year
	, MEDDRA.PT_CODE
	, SUM(ISNULL(RCY.NReaction, 0))
	FROM DatabaseName2.SDGProject.TotalCountYearly			TCY
	CROSS JOIN (SELECT DISTINCT PT_CODE FROM DatabaseName2.SDGProject.ReactionCountYearly)	MEDDRA -- get all reactions that have been reported on at least one report
	LEFT JOIN DatabaseName2.SDGProject.ReactionCountYearly		RCY ON (RCY.PT_CODE = MEDDRA.PT_CODE AND RCY.Year<=TCY.year)
	GROUP BY TCY.Year, MEDDRA.PT_CODE
	ORDER BY TCY.year, MEDDRA.PT_CODE

-- Took 1s -- 1,070,653 rows -- 53 x 20201

-- for testing
SELECT COUNT(DISTINCT PT_CODE) FROM DatabaseName2.SDGProject.ReactionCountYearly
SELECT *
FROM DatabaseName2.SDGProject.CumulCountsReaction	CCR
LEFT JOIN DatabaseName2.SDGProject.ReactionCountYearly	RCY ON RCY.PT_CODE = CCR.PT_CODE AND RCY.Year = CCR.Year
WHERE CCR.PT_CODE = 10062254
ORDER BY CCR.Year, RCY. Year
-- seems ok. Same thing as above



	

DROP TABLE IF EXISTS DatabaseName2.SDGProject.CumulCountsCombination
CREATE TABLE DatabaseName2.SDGProject.CumulCountsCombination (
	Year INT,
	Drecno char(6),
	PT_CODE INT,
	CumulNObserved INT,
	Primary key (Year, Drecno, PT_CODE)
)
INSERT INTO DatabaseName2.SDGProject.CumulCountsCombination
SELECT TCY.year, 
		DP.Drecno, 
		DP.PT_CODE, 
		SUM(ISNULL(ACYC.NObserved, 0))
    FROM DatabaseName2.SDGProject.TotalCountYearly															TCY
	CROSS JOIN (SELECT DISTINCT Drecno, PT_CODE FROM DatabaseName2.SDGProject.AllCountsYearCombination)		DP
	LEFT JOIN DatabaseName2.SDGProject.AllCountsYearCombination	ACYC ON ACYC.Drecno = DP.Drecno AND ACYC.PT_CODE = DP.PT_CODE AND ACYC.Year <= TCY.year
	GROUP BY TCY.Year, DP.Drecno, DP.PT_CODE
	ORDER BY TCY.Year, DP.Drecno, DP.PT_CODE



-- Took 10:56 -- Go get coffee -- 173,910,808 rows (53 x 3,281,336)
-- Big table! Mamma mia!
-- (as expected, more rows than in #AllCountsYearCombination because there were some years where some combs were not reported on)


-- for testing
SELECT DISTINCT Drecno, PT_CODE FROM DatabaseName2.SDGProject.AllCountsYearCombination
-- 3,281,336 unique combinations

SELECT *
FROM DatabaseName2.SDGProject.CumulCountsCombination		CCC
LEFT JOIN DatabaseName2.SDGProject.AllCountsYearCombination	ACYC ON ACYC.Drecno = CCC.Drecno AND ACYC.PT_CODE = CCC.PT_CODE AND ACYC.Year = CCC.Year
WHERE CCC.PT_CODE = 10028813 AND CCC.Drecno = '000827'
ORDER BY CCC.Year, ACYC. Year
--10028813 --nausea
--'000827' -- metformin
-- seems OK


-- Finally the big final table of cumulative numbers!!
-- I recommend to keep the strings (the drug and reaction names) out of this big table
-- you can always get the names later
-- unless you need them it all the time...
DROP TABLE IF EXISTS DatabaseName2.SDGProject.CumulAllCountsYearCombination
CREATE TABLE DatabaseName2.SDGProject.CumulAllCountsYearCombination (
	Year INT,
	Drecno char(6),
	PT_CODE INT,
	CumulNObserved INT,
	CumulNDrug INT,
	CumulNReaction INT,
	CumulNTot INT,
	Primary key (Year, Drecno, PT_CODE)
)
INSERT INTO DatabaseName2.SDGProject.CumulAllCountsYearCombination
SELECT CCC.Year
		,CCC.Drecno
		,CCC.PT_CODE
		,CCC.CumulNObserved
		,CCD.CumNDrug
		,CCR.CumulNReaction
		,CCA.CumulNTot
	FROM DatabaseName2.SDGProject.CumulCountsCombination			CCC
	LEFT JOIN DatabaseName2.SDGProject.CumulCountsDrug				CCD ON CCD.Drecno = CCC.Drecno AND CCD.Year = CCC.Year
	LEFT JOIN DatabaseName2.SDGProject.CumulCountsReaction			CCR ON CCR.PT_CODE = CCC.PT_CODE AND CCR.Year = CCC.Year
	LEFT JOIN DatabaseName2.SDGProject.CumulCountsAll				CCA ON CCA.Year = CCC.Year
	ORDER BY CCC.Year, CCC.Drecno, CCC.PT_CODE

-- Took 8:12 -- 173,910,808 orws, as expected



----- Calculation of the CumNexpected

DROP TABLE IF EXISTS DatabaseName2.SDGProject.CumObservedCumExpectedTable
CREATE TABLE DatabaseName2.SDGProject.CumObservedCumExpectedTable (
	Year INT,
	Drecno char(6),
	PT_CODE INT,
	CumulNObserved INT,
	CumulNDrug INT,
	CumulNReaction INT,
	CumulNTot INT,
	CumNExpected FLOAT,
	Primary key (Year, Drecno, PT_CODE)
)
INSERT INTO DatabaseName2.SDGProject.CumObservedCumExpectedTable
SELECT Year, 
       Drecno, 
       PT_CODE, 
       CumulNObserved, 
       CumulNDrug, 
       CumulNReaction, 
       CumulNTot,
	   CAST(CumulNDrug AS FLOAT)*CAST(CumulNReaction AS FLOAT)/CAST(CumulNTot AS FLOAT) AS CumulNExpected 
    FROM DatabaseName2.SDGProject.CumulAllCountsYearCombination
ORDER BY Drecno, [Year];

--test
SELECT * 
FROM DatabaseName2.SDGProject.CumObservedCumExpectedTable
WHERE PT_CODE = 10028813 AND Drecno = '000827'
ORDER BY Drecno, [Year]



---- Calculation of IC 

	
DROP TABLE IF EXISTS DatabaseName2.SDGProject.CumObservedCumExpectedICTable
CREATE TABLE DatabaseName2.SDGProject.CumObservedCumExpectedICTable (
	Year INT,
	Drecno char(6),
	PT_CODE INT,
	CumulNObserved INT,
	CumulNDrug INT,
	CumulNReaction INT,
	CumulNTot INT,
	CumNExpected FLOAT,
	IC FLOAT,
	Primary key (Year, Drecno, PT_CODE)
)
INSERT INTO DatabaseName2.SDGProject.CumObservedCumExpectedICTable
SELECT Year, 
       Drecno, 
       PT_CODE, 
       CumulNObserved,
	   CumulNDrug,
	   CumulNReaction,
	   CumulNTot,
	   CumNExpected,
	   ROUND(LOG((CAST(CumulNObserved AS FLOAT) + 0.5)/(CAST(CumNExpected AS FLOAT) + 0.5), 2),2) AS IC
    FROM DatabaseName2.SDGProject.CumObservedCumExpectedTable 
ORDER BY Drecno, Year;

--test 

SELECT * 
FROM DatabaseName2.SDGProject.CumObservedCumExpectedICTable
WHERE PT_CODE = 10028813 AND Drecno = '000827'
ORDER BY Drecno, [Year]

--- IC with shrinkage

DROP TABLE IF EXISTS DatabaseName2.SDGProject.CumObservedCumExpectedICTableShrinkage; 
CREATE TABLE DatabaseName2.SDGProject.CumObservedCumExpectedICTableShrinkage (
	Year INT,
	Drecno char(6),
	PT_CODE INT,
	CumulNObserved INT,
	CumNExpected FLOAT,
	IC FLOAT,
	IC025 FLOAT,
	IC975 FLOAT,
	Primary key (Year, Drecno, PT_CODE)
)
INSERT INTO DatabaseName2.SDGProject.CumObservedCumExpectedICTableShrinkage
SELECT CNONEIC.Year, 
       CNONEIC.Drecno, 
       CNONEIC.PT_CODE, 
       CNONEIC.CumulNObserved,
	   CNONEIC.CumNExpected,
	   CNONEIC.IC,
	   CNONEIC.IC + IClx.IC025 as IC025, 
	   CNONEIC.IC + IClx.IC975 as IC975
    FROM DatabaseName2.SDGProject.CumObservedCumExpectedICTable CNONEIC
	JOIN SignalData_EducationalSprint_2018Dec.aux.IC_lx IClx ON CNONEIC.CumulNObserved = IClx.Observed
ORDER BY CNONEIC.Drecno, CNONEIC.Year;

--test

SELECT * 
FROM DatabaseName2.SDGProject.CumObservedCumExpectedICTableShrinkage
WHERE PT_CODE = 10037844 AND Drecno = '000200'
ORDER BY Drecno, [Year]







-------------------------------------------------------


truncate table DatabaseName2.[SDGProject].[CumtempCombination];

insert into  DatabaseName2.SDGProject.CumtempCombination
SELECT BCT.[Year], 
       BCT.Drecno, 
       BCT.SubstanceName, 
       BCT.PT_CODE, 
       BCT.ReactionName, 
       SUM(ISNULL(TC.NObserved, 0)) OVER(partition by BCT.Drecno, BCT.PT_CODE
       ORDER BY BCT.[year]) AS CumNObserved, 
       SUM(ISNULL(TC.NDrug, 0)) OVER(partition by BCT.Drecno
       ORDER BY BCT.[year]) AS CumNDrug, 
       SUM(ISNULL(TC.NReaction, 0)) OVER(partition by BCT.PT_CODE
       ORDER BY BCT.[year]) AS CumNReaction, 
       SUM(BCT.Ntot) OVER(partition by BCT.Drecno, BCT.PT_CODE
       ORDER BY BCT.[year]) AS CumNtot

    FROM DatabaseName2.SDGProject.baseCombinationTable AS BCT
         LEFT JOIN DatabaseName2.SDGProject.tempCombination AS TC
                   ON TC.[Year] = BCT.[Year] AND TC.Drecno = BCT.Drecno AND TC.PT_CODE = BCT.PT_CODE
	WHERE 1 = 1
        -- AND ( BCT.SubstanceName = 'paracetamol'
         --       AND BCT.ReactionName = 'rash' )
       --  OR ( BCT.SubstanceName = 'ibuprofen'
         --     AND BCT.ReactionName = 'pyrexia' )
	
ORDER BY Drecno, [Year];

GO
----

DROP TABLE IF EXISTS DatabaseName2.SDGProject.CumObservedCumExpectedTable;

SELECT [Year], 
       Drecno, 
       SubstanceName, 
       PT_CODE, 
       ReactionName, 
       CumNObserved, 
       CumNDrug, 
       CumNReaction, 
       CumNtot,
	   CAST(CumNDrug AS FLOAT)*CAST(CumNReaction AS FLOAT)/CAST(CumNtot AS FLOAT) AS CumNExpected 
INTO DatabaseName2.SDGProject.CumObservedCumExpectedTable
    FROM DatabaseName2.SDGProject.CumtempCombination 
	--WHERE 1 = 1
       --   AND ( SubstanceName = 'paracetamol'
      --          AND ReactionName = 'rash' )
        --  OR ( SubstanceName = 'ibuprofen'
         --      AND ReactionName = 'pyrexia' )
ORDER BY Drecno, [Year];

GO
----


---

DROP TABLE IF EXISTS DatabaseName2.SDGProject.CumObservedCumExpectedICTableShrinkage; 

SELECT CumNObsNExp.[Year], 
       CumNObsNExp.Drecno, 
       CumNObsNExp.SubstanceName, 
       CumNObsNExp.PT_CODE, 
       CumNObsNExp.ReactionName, 
       CumNObsNExp.CumNObserved,
	   CumNObsNExp.CumNExpected,
	   CumNObsNExp.IC
	   CumNObsNExp.IC + IClx.IC025 as IC025, 
	   CumNObsNExp.IC + IClx.IC975 as IC975

INTO DatabaseName2.SDGProject.CumObservedCumExpectedICTableShrinkage
    FROM DatabaseName2.SDGProject.CumObservedCumExpectedICTable AS CumNObsNExp
	JOIN SignalData_EducationalSprint_2018Dec.aux.IC_lx AS IClx on CumNObsNExp.CumNObserved = IClx.Observed
ORDER BY CumNObsNExp.Drecno, CumNObsNExp.[Year];

SELECT *
FROM DatabaseName2.SDGProject.CumObservedCumExpectedICTableShrinkage 
WHERE Drecno = '072101' AND PT_CODE = '10007554'
ORDER BY Drecno, [Year];