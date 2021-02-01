USE DatabaseName1;

------- For each DRecNo get the names of the active ingredients (a list of names of substances of the different combinations)

DROP TABLE IF EXISTS DatabaseName2.SDGProject.DrecnoATC;
	SELECT DISTINCT DTC.Drecno, 
    STRING_AGG(S.Name, ';') AS SubstanceName,
	DTC.AtcCode,
	A.Name AS ATCName
INTO DatabaseName2.SDGProject.DrecnoATC
	FROM SchemaName2.DrecnoAtc AS DTC
		JOIN SchemaName2.DrecnoSubstance AS DS ON DTC.Drecno = DS.Drecno
        JOIN SchemaName2.Substance AS S ON S.SubstanceID = DS.SubstanceID AND S.IsPreferred = 1
		JOIN SchemaName2.Atc AS A ON A.AtcCode = DTC.AtcCode
	WHERE DS.Seq1 = '01'
    GROUP BY DTC.AtcCode, DTC.Drecno, A.Name
	ORDER BY 1;

-- 34228 rows
GO 

DROP TABLE IF EXISTS DatabaseName2.SDGProject.ATCDrugCountYearly;
CREATE TABLE DatabaseName2.SDGProject.ATCDrugCountYearly (
	Year INT,
	ATCcode char(6),
	ATCName nvarchar(1500),
	NDrug INT,
	Primary key (Year, ATCcode)
)
INSERT INTO DatabaseName2.SDGProject.ATCDrugCountYearly
SELECT YEAR(R.DateInDatabase) AS 'Year',
	   DA.AtcCode,
	   DA.ATCName AS ATCName,
       COUNT(DISTINCT R.ReportsID) AS              NDrug
    FROM SchemaName1.Reports AS R
         JOIN SchemaName1.Drugs AS D ON D.ReportsID = R.ReportsID
         JOIN SchemaName2.Product AS WP ON WP.ProductID = D.UMCValidated_ProductID
		 JOIN DatabaseName2.SDGProject.DrecnoATC AS DA ON DA.Drecno = WP.Drecno collate SQL_Latin1_General_CP1_CI_AS
	WHERE 1 = 1
          AND R.IsForeignCase = 0
          AND ( R.PreferredCase_ReportID IS NULL OR R.PreferredCase_ReportID = R.ReportsID )
          AND D.CharacterizationID IN ( 1, 3 )
    GROUP BY YEAR(R.DateInDatabase),
	         DA.AtcCode, 
             DA.ATCName
	ORDER BY Year

---43197 rows
GO

DROP TABLE IF EXISTS DatabaseName2.SDGProject.ATCReactionCountYearly;
CREATE TABLE DatabaseName2.SDGProject.ATCReactionCountYearly (
	Year INT,
	PT_CODE INT,
	ReactionName nvarchar(1500),
	NReaction INT,
	Primary key (Year, PT_CODE)
)

INSERT INTO DatabaseName2.SDGProject.ATCReactionCountYearly
SELECT YEAR(R.DateInDatabase) AS             'Year', 
       MED.PT_CODE, 
       MED.PT_NAME AS             ReactionName, 
       COUNT(DISTINCT R.ReportsID) AS NReaction

	FROM SchemaName1.Reports AS R
		JOIN SchemaName1.Reaction AS RE ON RE.ReportsID = R.ReportsID
		JOIN Terminology.TerminologySchema.MEDDRA_MD_HIERARCHY AS MED ON MED.PT_CODE = RE.UMCValidated_ReactionMeddraPtCode AND MED.PRIMARY_SOC_FG = 'Y'
	WHERE 1=1
		AND R.IsForeignCase = 0
		AND (R.PreferredCase_ReportID is NULL or R.PreferredCase_ReportID = R.ReportsID)
	GROUP BY YEAR(R.DateInDatabase), 
				 MED.PT_CODE, 
				 MED.PT_NAME

-- 234356 rows
GO


DROP TABLE IF EXISTS DatabaseName2.SDGProject.ATCnObservedPerYear;
CREATE TABLE DatabaseName2.SDGProject.ATCnObservedPerYear (
	Year INT,
	AtcCode char(6),
	PT_CODE INT,
	NObserved INT,
	Primary key (Year, AtcCode, PT_CODE)
);
GO
INSERT INTO DatabaseName2.SDGProject.ATCnObservedPerYear
SELECT DISTINCT 
       YEAR(R.DateInDatabase) AS            'Year', 
       DA.AtcCode AS AtcCode, 
       MED.PT_CODE AS PT_CODE, 
       COUNT(DISTINCT R.ReportsID) AS NObserved
    FROM SchemaName1.Reports AS R
         JOIN SchemaName1.Drugs AS D ON D.ReportsID = R.ReportsID
		 JOIN SchemaName2.Product AS WP ON WP.ProductID = D.UMCValidated_ProductID
		 JOIN DatabaseName2.SDGProject.DrecnoATC AS DA ON DA.Drecno = WP.Drecno collate SQL_Latin1_General_CP1_CI_AS
		 JOIN SchemaName1.Reaction AS RE ON RE.ReportsID = R.ReportsID
		 JOIN Terminology.TerminologySchema.MEDDRA_MD_HIERARCHY AS MED ON MED.PT_CODE = RE.UMCValidated_ReactionMeddraPtCode AND MED.PRIMARY_SOC_FG = 'Y'
	WHERE 1=1
		AND R.IsForeignCase = 0
		AND (R.PreferredCase_ReportID is NULL or R.PreferredCase_ReportID = R.ReportsID)
		AND D.CharacterizationID in (1,3)
    GROUP BY YEAR(R.DateInDatabase), 
             DA.AtcCode, 
             MED.PT_CODE;
GO
-- Took 2:16 -- 10427069


-- Y x D x R
-----------------------------------------------------
DROP TABLE IF EXISTS DatabaseName2.SDGProject.ATCAllCountsYearCombination;
CREATE TABLE DatabaseName2.SDGProject.ATCAllCountsYearCombination (
	Year INT,
	ATCcode char(6),
	PT_CODE INT,
	NObserved INT,
	NDrug INT,
	NReaction INT,
	Ntot INT
	primary key (year, ATCcode, PT_CODE)
)
INSERT INTO DatabaseName2.SDGProject.ATCAllCountsYearCombination
SELECT OY.[Year], 
       OY.AtcCode, 
       OY.PT_CODE, 
       OY.NObserved, 
       DY.NDrug, 
       RY.NReaction,
	   TY.Ntot
    FROM DatabaseName2.SDGProject.ATCnObservedPerYear AS		OY
    JOIN DatabaseName2.SDGProject.ATCDrugCountYearly AS		DY ON DY.ATCcode = OY.ATCcode  AND DY.[Year] = OY.[Year]
    JOIN DatabaseName2.SDGProject.ATCReactionCountYearly AS	RY ON RY.Year = OY.Year AND RY.PT_CODE = OY.PT_CODE
	JOIN DatabaseName2.SDGProject.TotalCountYearly			TY ON TY.Year = OY.Year
ORDER BY OY.[Year];

-- Took 33s --10427069 rows (as expected, should be the same number of rows as #ATCnObservedPerYear)
GO

--HERE IS THE PROBLEM

--DROP TABLE IF EXISTS DatabaseName2.SDGProject.ATCCumulCountsDrug
/*CREATE TABLE DatabaseName2.SDGProject.ATCCumulCountsDrug (
	Year INT,
	ATCcode char(6),
	CumulNDrug INT,
	PRIMARY KEY (Year, ATCcode)
)
INSERT INTO DatabaseName2.SDGProject.ATCCumulCountsDrug
SELECT TCY.year
	, DA.AtcCode
	, SUM(ISNULL(DCY.NDrug, 0)) AS CumulNDrug
	FROM DatabaseName2.SDGProject.TotalCountYearly			TCY
	CROSS JOIN DatabaseName2.SDGProject.DrecnoATC	DA
	LEFT JOIN DatabaseName2.SDGProject.ATCDrugCountYearly		DCY ON (DCY.ATCcode collate SQL_Latin1_General_CP1_CI_AS = DA.AtcCode AND DCY.Year<=TCY.year)
	GROUP BY TCY.Year, DA.AtcCode, DA.ATCName
	ORDER BY TCY.year, DA.AtcCode

-- Took 2s -- 1,389,183 rows which is, as expected, 53*26211


-- for testing

select * from DatabaseName2.SDGProject.TotalCountYearly
select * from DatabaseName2.SDGProject.DrecnoATC
select * from DatabaseName2.SDGProject.ATCDrugCountYearly
select * 
	FROM DatabaseName2.SDGProject.TotalCountYearly			TCY
	CROSS JOIN DatabaseName2.SDGProject.DrecnoATC	DA
	LEFT JOIN DatabaseName2.SDGProject.ATCDrugCountYearly		DCY ON (DCY.ATCcode collate SQL_Latin1_General_CP1_CI_AS = DA.AtcCode AND DCY.Year<=TCY.year)
	--GROUP BY TCY.Year, DA.AtcCode, DA.ATCName
	ORDER BY TCY.year, DA.AtcCode
	
SELECT TCY.year
	, DA.AtcCode
	, SUM(ISNULL(DCY.NDrug, 0)) AS CumulNDrug
	FROM DatabaseName2.SDGProject.TotalCountYearly			TCY
	CROSS JOIN DatabaseName2.SDGProject.DrecnoATC	DA
	LEFT JOIN DatabaseName2.SDGProject.ATCDrugCountYearly		DCY on DCY.ATCcode collate SQL_Latin1_General_CP1_CI_AS = DA.AtcCode and DCY.ATCName  collate SQL_Latin1_General_CP1_CI_AS = DCY.ATCName
	WHERE DCY.Year<=TCY.year
	--AND DA.AtcCode = 'D06BX'
	GROUP BY TCY.Year, DA.AtcCode, DA.ATCName
	ORDER BY TCY.year, DA.AtcCode

GO*/
----
DROP TABLE IF EXISTS DatabaseName2.SDGProject.ATCPTAllCountsYearly;
/*CREATE TABLE DatabaseName2.SDGProject.ATCPTAllCountsYearly (
	Year INT,
	ATCcode char(6),
	PT_CODE INT,
	NObserved INT,
	NDrug INT,
	NReaction INT,
	NTot INT,
	Primary key (Year, ATCcode, PT_CODE)
)*/
SELECT TCY.Year, 
       Atc.AtcCode, 
       PT.PT_CODE, 
       ISNULL(ATCyc.NObserved, 0) AS NObserved, 
       ISNULL(ATCyc.NDrug, 0) AS     NDrug, 
       ISNULL(ATCyc.NReaction, 0) AS NReaction, 
       ISNULL(TCY.Ntot, 0) AS      Ntot

INTO DatabaseName2.SDGProject.ATCPTAllCountsYearly

    FROM DatabaseName2.SDGProject.TotalCountYearly AS TCY
         CROSS JOIN SchemaName1.SchemaName2.Atc
         CROSS JOIN Terminology.TerminologySchema.MEDDRA_PREF_TERM AS PT
         JOIN ( SELECT DISTINCT 
                       ATCcode, 
                       PT_CODE
                    FROM DatabaseName2.SDGProject.ATCAllCountsYearCombination
              ) AS tmp
                   ON tmp.ATCcode COLLATE SQL_Latin1_General_CP1_CI_AS = Atc.AtcCode
                      AND tmp.PT_CODE = PT.PT_CODE
         LEFT JOIN DatabaseName2.SDGProject.ATCAllCountsYearCombination AS ATCyc
                   ON ATCyc.Year = TCY.Year
                      AND ATCyc.ATCcode COLLATE SQL_Latin1_General_CP1_CI_AS = Atc.AtcCode
                      AND ATCyc.PT_CODE = PT.PT_CODE;
					  
-- 114429862 rows 33 s

---
GO


DROP TABLE IF EXISTS DatabaseName2.SDGProject.ATCPTAllCumulativeCountsYearly;
/*CREATE TABLE DatabaseName2.SDGProject.ATCPTAllCumulativeCountsYearly (
	Year INT,
	ATCcode char(6),
	PT_CODE INT,
	NObservedCumulative INT,
	NDrugCumulative INT,
	NReactionCumulative INT,
	NtotCumulative INT,
	Primary key (Year, ATCcode, PT_CODE)
)*/

SELECT ACY1.Year, 
       ACY1.AtcCode, 
       ACY1.PT_CODE, 
       SUM(ACY2.NObserved) AS NObservedCumulative, 
       SUM(ACY2.NDrug) AS     NDrugCumulative, 
       SUM(ACY2.NReaction) AS NReactionCumulative, 
       SUM(ACY2.Ntot) AS      NtotCumulative
INTO DatabaseName2.SDGProject.ATCPTAllCumulativeCountsYearly
    FROM DatabaseName2.SDGProject.ATCPTAllCountsYearly AS ACY1
         CROSS JOIN DatabaseName2.SDGProject.ATCPTAllCountsYearly AS ACY2
    WHERE 1 = 1
          AND ACY2.Year <= ACY1.Year
          AND ACY1.AtcCode = ACY2.AtcCode
          AND ACY1.PT_CODE = ACY2.PT_CODE
    GROUP BY ACY1.Year, 
             ACY1.AtcCode, 
             ACY1.PT_CODE;

--- 114429862 rows 5:19 

--The following table is to know how the cumulative count has been done whith the cross joins

SELECT *
		--ACY1.Year, 
  --     ACY1.AtcCode, 
  --     ACY1.PT_CODE, 
  --     SUM(ACY2.NObserved) AS NObservedCumulative, 
  --     SUM(ACY2.NDrug) AS     NDrugCumulative, 
  --     SUM(ACY2.NReaction) AS NReactionCumulative, 
  --     SUM(ACY2.Ntot) AS      NtotCumulative
--INTO #ATCPTAllCumulativeCountsYearly
    FROM DatabaseName2.SDGProject.ATCPTAllCountsYearly AS ACY1
         CROSS JOIN DatabaseName2.SDGProject.ATCPTAllCountsYearly AS ACY2
    WHERE 1 = 1
          AND ACY2.Year <= ACY1.Year
          AND ACY1.AtcCode = ACY2.AtcCode
          AND ACY1.PT_CODE = ACY2.PT_CODE
		  and ACY1.AtcCode = 'A01AB'
		  and ACY1.PT_CODE = 10002424
    --GROUP BY ACY1.Year, 
    --         ACY1.AtcCode, 
    --         ACY1.PT_CODE
			 order by 1

---
GO

DROP TABLE IF EXISTS DatabaseName2.SDGProject.ATCCumObservedCumExpectedTable
CREATE TABLE DatabaseName2.SDGProject.ATCCumObservedCumExpectedTable (
	Year INT,
	ATCcode char(6),
	PT_CODE INT,
	CumulNObserved INT,
	CumulNDrug INT,
	CumulNReaction INT,
	CumulNTot INT,
	CumulNExpected FLOAT,
	Primary key (Year, ATCcode, PT_CODE)
)
INSERT INTO DatabaseName2.SDGProject.ATCCumObservedCumExpectedTable
SELECT Year, 
       AtcCode, 
       PT_CODE, 
       NObservedCumulative, 
       NDrugCumulative, 
       NReactionCumulative, 
       NtotCumulative,
	   CAST(NDrugCumulative AS FLOAT)*CAST(NReactionCumulative AS FLOAT)/CAST(NtotCumulative AS FLOAT) AS CumulNExpected 
    FROM DatabaseName2.SDGProject.ATCPTAllCumulativeCountsYearly
ORDER BY AtcCode, [Year];

--- 114429862 rows 6:42
GO

---- Calculation of IC 
	
DROP TABLE IF EXISTS DatabaseName2.SDGProject.ATCCumObservedCumExpectedICTable
CREATE TABLE DatabaseName2.SDGProject.ATCCumObservedCumExpectedICTable (
	Year INT,
	ATCcode char(6),
	PT_CODE INT,
	CumulNObserved INT,
	CumulNDrug INT,
	CumulNReaction INT,
	CumulNTot INT,
	CumulNExpected FLOAT,
	IC FLOAT,
	Primary key (Year, ATCcode, PT_CODE)
)
INSERT INTO DatabaseName2.SDGProject.ATCCumObservedCumExpectedICTable
SELECT Year, 
       ATCcode, 
       PT_CODE, 
       CumulNObserved,
	   CumulNDrug,
	   CumulNReaction,
	   CumulNTot,
	   CumulNExpected,
	   ROUND(LOG((CAST(CumulNObserved AS FLOAT) + 0.5)/(CAST(CumulNExpected AS FLOAT) + 0.5), 2),2) AS IC
	
    FROM DatabaseName2.SDGProject.ATCCumObservedCumExpectedTable
	--WHERE Year = '1967' AND CumulNDrug > 0
ORDER BY ATCcode, Year;

---114,429,862 rows 4:03
GO

--- IC with shrinkage

DROP TABLE IF EXISTS DatabaseName2.SDGProject.ATCCumObservedCumExpectedICTableShrinkage; 
CREATE TABLE DatabaseName2.SDGProject.ATCCumObservedCumExpectedICTableShrinkage (
	Year INT,
	ATCcode char(6),
	PT_CODE INT,
	CumulNObserved INT,
	CumulNExpected FLOAT,
	IC FLOAT,
	IC025 FLOAT,
	IC975 FLOAT,
	Primary key (Year, ATCcode, PT_CODE)
)
INSERT INTO DatabaseName2.SDGProject.ATCCumObservedCumExpectedICTableShrinkage
SELECT CNONEIC.Year, 
       CNONEIC.ATCcode, 
       CNONEIC.PT_CODE, 
       CNONEIC.CumulNObserved,
	   CNONEIC.CumulNExpected,
	   CNONEIC.IC,
	   CNONEIC.IC + IClx.IC025 as IC025, 
	   CNONEIC.IC + IClx.IC975 as IC975
    FROM DatabaseName2.SDGProject.ATCCumObservedCumExpectedICTable CNONEIC
	JOIN SignalData_EducationalSprint_2018Dec.aux.IC_lx IClx ON CNONEIC.CumulNObserved = IClx.Observed
ORDER BY CNONEIC.ATCcode, CNONEIC.Year;

---114429862 rows 10:00
