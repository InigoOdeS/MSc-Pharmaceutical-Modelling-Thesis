USE DatabaseName1;

DROP TABLE IF EXISTS DatabaseName2.SDGProject.SDGsSubstances;
	SELECT SDGC.GroupId, 
		   SchemaName3.GroupName,
		   SDGC.DrugRecordNumber,
		   SDGC.DrugName
INTO DatabaseName2.SDGProject.SDGsSubstances
	FROM SchemaName3.SDGContent SDGC
		JOIN SchemaName3.SDG SDG ON SchemaName3.GroupId = SDGC.GroupId
	WHERE SDGC.SequenceNumber1 = '01' AND SDGC.SequenceNumber2 = '001'--I tried creating a temporary table without SDGC.SequenceNumber2 = '001' and I get the same number of rows as if I put just SDGC.SequenceNumber1 = '01'. In both case is 163350
-- AND SDGC.GroupId = '10'
--- 163350 rows 

DROP TABLE IF EXISTS DatabaseName2.SDGProject.SDGsSubstancesYear;
SELECT TCY.year,
	   SDGC.GroupId, 
	   SchemaName3.GroupName,
	   SDGC.DrugRecordNumber,
	   SDGC.DrugName
INTO DatabaseName2.SDGProject.SDGsSubstancesYear
	FROM SchemaName3.SDGContent SDGC
     JOIN SchemaName3.SDG SDG ON SchemaName3.GroupId = SDGC.GroupId
	 CROSS JOIN DatabaseName2.SDGProject.TotalCountYearly TCY
	WHERE SDGC.SequenceNumber1 = '01' AND SDGC.SequenceNumber2 = '001'--I tried creating a temporary table without SDGC.SequenceNumber2 = '001' and I get the same number of rows as if I put just SDGC.SequenceNumber1 = '01'. In both case is 163350

---
GO

DROP TABLE IF EXISTS DatabaseName2.SDGProject.SDGsDrugCountYearly;
CREATE TABLE DatabaseName2.SDGProject.SDGsDrugCountYearly (
	Year INT,
	GroupId INT,
	GroupName nvarchar(1500),
	NDrug INT,
	Primary key (Year, GroupId)
)
INSERT INTO DatabaseName2.SDGProject.SDGsDrugCountYearly
SELECT YEAR(R.DateInDatabase) AS 'Year', 
       SDGsSubs.GroupId, 
       SDGsSubs.GroupName, 
       COUNT(DISTINCT R.ReportsID) AS              NDrug
FROM SchemaName1.Reports AS R
     JOIN SchemaName1.Drug AS D ON D.ReportsID = R.ReportsID
     JOIN SchemaName2.Product AS WP ON WP.ProductID = D.ProductID
     JOIN DatabaseName2.SDGProject.SDGsSubstancesYear AS SDGsSubs ON SDGsSubs.DrugRecordNumber = WP.Drecno collate SQL_Latin1_General_CP1_CI_AS
WHERE 1 = 1
     AND R.IsForeignCase = 0
     AND ( R.PreferredCase_ReportID IS NULL OR R.PreferredCase_ReportID = R.ReportsID )
     AND D.CharacterizationID IN ( 1, 3 )
GROUP BY YEAR(R.DateInDatabase), 
          SDGsSubs.GroupId,
		  SDGsSubs.GroupName
ORDER BY YEAR(R.DateInDatabase);
---
GO
--- 15686 rows
---

DROP TABLE IF EXISTS DatabaseName2.SDGProject.SDGReactionCountYearly;
CREATE TABLE DatabaseName2.SDGProject.SDGReactionCountYearly (
	Year INT,
	PT_CODE INT,
	ReactionName nvarchar(1500),
	NReaction INT,
	Primary key (Year, PT_CODE)
) 
INSERT INTO DatabaseName2.SDGProject.SDGReactionCountYearly
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
			--AND MED.PT_NAME = 'Rash'
	GROUP BY YEAR(R.DateInDatabase), 
				 MED.PT_CODE, 
				 MED.PT_NAME

GO
--- 234356 rows
---

DROP TABLE IF EXISTS DatabaseName2.SDGProject.SDGnObservedPerYear;
CREATE TABLE DatabaseName2.SDGProject.SDGnObservedPerYear (
	Year INT,
	GroupId INT,
	GroupName nvarchar(1500),
	PT_CODE INT,
	ReactionName nvarchar(1500),
	NObserved INT,
	Primary key (Year, GroupId, PT_CODE)
)
INSERT INTO DatabaseName2.SDGProject.SDGnObservedPerYear
SELECT DISTINCT 
       YEAR(R.DateInDatabase) AS            'Year', 
       SDGsSubs.GroupId, 
       SDGsSubs.GroupName, 
       MED.PT_CODE, 
       MED.PT_NAME AS             ReactionName,
       COUNT(DISTINCT R.ReportsID) AS NObserved
	FROM SchemaName1.Reports AS R
		 JOIN SchemaName1.Drug AS D ON D.ReportsID = R.ReportsID
		 JOIN SchemaName2.Product AS WP ON WP.ProductID = D.ProductID
		 JOIN DatabaseName2.SDGProject.SDGsSubstances AS SDGsSubs ON SDGsSubs.DrugRecordNumber = WP.Drecno collate SQL_Latin1_General_CP1_CI_AS
		 JOIN SchemaName1.Reaction AS RE ON RE.ReportsID = R.ReportsID
		 JOIN Terminology.TerminologySchema.MEDDRA_MD_HIERARCHY AS MED ON MED.PT_CODE = RE.UMCValidated_ReactionMeddraPtCode AND MED.PRIMARY_SOC_FG = 'Y'
	WHERE 1=1
		AND R.IsForeignCase = 0
		AND (R.PreferredCase_ReportID is NULL or R.PreferredCase_ReportID = R.ReportsID)
		AND D.CharacterizationID in (1,3)
		--AND SDGsSubs.GroupId = ''
		--AND MED.PT_NAME = 'Rash'
	GROUP BY YEAR(R.DateInDatabase), 
			 SDGsSubs.GroupId, 
			 SDGsSubs.GroupName, 
			 MED.PT_CODE, 
			 MED.PT_NAME
--ORDER BY YEAR(R.DateInDatabase)

--- 11180320 rows
---
GO

DROP TABLE IF EXISTS DatabaseName2.SDGProject.SDGAllCountsYearCombination;
CREATE TABLE DatabaseName2.SDGProject.SDGAllCountsYearCombination (
	Year INT,
	GroupId INT,
	GroupName nvarchar(1500),
	PT_CODE INT,
	ReactionName nvarchar(1500),
	NObserved INT,
	NDrug INT,
	NReaction INT,
	Ntot INT,
	primary key (Year, GroupId, PT_CODE)
)
INSERT INTO DatabaseName2.SDGProject.SDGAllCountsYearCombination
SELECT SDGOY.[Year], 
       SDGOY.GroupId, 
       SDGOY.GroupName, 
       SDGOY.PT_CODE, 
       SDGOY.ReactionName, 
       SDGOY.NObserved, 
       SDGDY.NDrug, 
       SDGRY.NReaction,
	   TY.Ntot
FROM DatabaseName2.SDGProject.SDGnObservedPerYear 		SDGOY
   JOIN DatabaseName2.SDGProject.SDGsDrugCountYearly		SDGDY ON SDGDY.GroupId = SDGOY.GroupId  AND SDGDY.[Year] = SDGOY.[Year]
   JOIN DatabaseName2.SDGProject.SDGReactionCountYearly 	SDGRY ON SDGRY.Year = SDGOY.Year AND SDGRY.PT_CODE = SDGOY.PT_CODE
   JOIN DatabaseName2.SDGProject.TotalCountYearly        TY ON TY.Year = SDGOY.Year
--WHERE SDGOY.GroupId = '14' AND SDGOY.ReactionName = 'Nausea'
ORDER BY SDGOY.[Year];

--11180320 rows
---
GO


  
DROP TABLE IF EXISTS DatabaseName2.SDGProject.SDGAllCountsAllYearsCombination;
CREATE TABLE DatabaseName2.SDGProject.SDGAllCountsAllYearsCombination (
	Year INT,
	GroupId INT,
	PT_CODE INT,
	NObserved INT,
	NDrug INT,
	NReaction INT,
	Ntot INT,
	primary key (Year, GroupId, PT_CODE)
) INSERT INTO DatabaseName2.SDGProject.SDGAllCountsAllYearsCombination
SELECT TCY.Year, 
       SchemaName3.GroupId, 
       MD.PT_CODE, 
       ISNULL(CCC.NObserved, 0) AS NObserved,
	   ISNULL(CCC.NDrug, 0) AS NDrug,
	   ISNULL(CCC.NReaction, 0) AS NReaction,
	   ISNULL(TCY.Ntot, 0) AS Ntot
    FROM DatabaseName2.SDGProject.TotalCountYearly AS TCY
         CROSS JOIN SchemaName1.SchemaName3.SDG
         CROSS JOIN Terminology.TerminologySchema.MEDDRA_PREF_TERM AS MD
         JOIN ( SELECT DISTINCT 
                       GroupId, 
                       PT_CODE
                    FROM DatabaseName2.SDGProject.SDGAllCountsYearCombination
              ) AS tmp
                   ON tmp.GroupId = SchemaName3.GroupId
                      AND tmp.PT_CODE = md.PT_CODE
         LEFT JOIN DatabaseName2.SDGProject.SDGAllCountsYearCombination AS CCC
                   ON TCY.Year = CCC.Year
                      AND CCC.GroupId = SchemaName3.GroupId
                      AND CCC.PT_CODE = MD.PT_CODE;  
					  
-- 96170885 rows 
---
GO 

DROP TABLE IF EXISTS DatabaseName2.SDGProject.SDGCumulCountsCombinationAllYears
CREATE TABLE DatabaseName2.SDGProject.SDGCumulCountsCombinationAllYears (
	Year INT,
	GroupId char(6),
	PT_CODE INT,
	CumulNObserved INT,
	CumulNDrug INT,
	CumulNReaction INT,
	CumulNtot INT,
	Primary key (Year, GroupId, PT_CODE)
)
INSERT INTO DatabaseName2.SDGProject.SDGCumulCountsCombinationAllYears
SELECT L1.Year, 
       L1.GroupId, 
       L1.PT_CODE, 
       SUM(L2.NObserved) AS CumulNObserved,
	   SUM(L2.NDrug) AS CumulNDrug,
	   SUM(L2.NReaction) AS CumulNReaction,
	   SUM(L2.Ntot) AS CumulNtot
    FROM DatabaseName2.SDGProject.SDGAllCountsAllYearsCombination AS L1
         CROSS JOIN DatabaseName2.SDGProject.SDGAllCountsAllYearsCombination AS L2
    WHERE 1 = 1
          AND L2.Year <= L1.Year
          AND L1.PT_CODE = L2.PT_CODE
          AND L1.GroupId = L2.GroupId
          --AND ( ( L1.GroupId = 1283
          --        AND L1.PT_CODE = 10037844 )
          --      OR ( L1.GroupId = 22
          --           AND L1.PT_CODE = 10019211 ) )
    GROUP BY L1.Year, 
             L1.GroupId, 
             L1.PT_CODE

--- 96170885 rows
---
GO



----- Calculation of the CumNexpected

DROP TABLE IF EXISTS DatabaseName2.SDGProject.SDGCumObservedCumExpectedTable
CREATE TABLE DatabaseName2.SDGProject.SDGCumObservedCumExpectedTable (
	Year INT,
	GroupId char(6),
	PT_CODE INT,
	CumulNObserved INT,
	CumulNDrug INT,
	CumulNReaction INT,
	CumulNTot INT,
	CumulNExpected FLOAT,
	Primary key (Year, GroupId, PT_CODE)
)
INSERT INTO DatabaseName2.SDGProject.SDGCumObservedCumExpectedTable
SELECT Year, 
       GroupId, 
       PT_CODE, 
       CumulNObserved, 
       CumulNDrug, 
       CumulNReaction, 
       CumulNTot,
	   CAST(CumulNDrug AS FLOAT)*CAST(CumulNReaction AS FLOAT)/CAST(CumulNTot AS FLOAT) AS CumulNExpected 
    FROM DatabaseName2.SDGProject.SDGCumulCountsCombinationAllYears
ORDER BY GroupId, [Year];

--- 96170885 rows

--test
SELECT * 
FROM DatabaseName2.SDGProject.SDGCumObservedCumExpectedTable
WHERE PT_CODE = 10028813 AND GroupId = '000827'
ORDER BY GroupId, [Year]



---- Calculation of IC 

	
DROP TABLE IF EXISTS DatabaseName2.SDGProject.SDGCumObservedCumExpectedICTable
CREATE TABLE DatabaseName2.SDGProject.SDGCumObservedCumExpectedICTable (
	Year INT,
	GroupId char(6),
	PT_CODE INT,
	CumulNObserved INT,
	CumulNDrug INT,
	CumulNReaction INT,
	CumulNTot INT,
	CumulNExpected FLOAT,
	IC FLOAT,
	Primary key (Year, GroupId, PT_CODE)
)
INSERT INTO DatabaseName2.SDGProject.SDGCumObservedCumExpectedICTable
SELECT Year, 
       GroupId, 
       PT_CODE, 
       CumulNObserved,
	   CumulNDrug,
	   CumulNReaction,
	   CumulNTot,
	   CumulNExpected,
	   ROUND(LOG((CAST(CumulNObserved AS FLOAT) + 0.5)/(CAST(CumulNExpected AS FLOAT) + 0.5), 2),2) AS IC
    FROM DatabaseName2.SDGProject.SDGCumObservedCumExpectedTable
ORDER BY GroupId, Year;

---96170885 rows

--test 

SELECT * 
FROM DatabaseName2.SDGProject.CumObservedCumExpectedICTable
WHERE PT_CODE = 10028813 AND Drecno = '000827'
ORDER BY Drecno, [Year]

--- IC with shrinkage

DROP TABLE IF EXISTS DatabaseName2.SDGProject.SDGCumObservedCumExpectedICTableShrinkage; 
CREATE TABLE DatabaseName2.SDGProject.SDGCumObservedCumExpectedICTableShrinkage (
	Year INT,
	GroupId char(6),
	PT_CODE INT,
	CumulNObserved INT,
	CumulNExpected FLOAT,
	IC FLOAT,
	IC025 FLOAT,
	IC975 FLOAT,
	Primary key (Year, GroupId, PT_CODE)
)
INSERT INTO DatabaseName2.SDGProject.SDGCumObservedCumExpectedICTableShrinkage
SELECT CNONEIC.Year, 
       CNONEIC.GroupId, 
       CNONEIC.PT_CODE, 
       CNONEIC.CumulNObserved,
	   CNONEIC.CumulNExpected,
	   CNONEIC.IC,
	   CNONEIC.IC + IClx.IC025 as IC025, 
	   CNONEIC.IC + IClx.IC975 as IC975
    FROM DatabaseName2.SDGProject.SDGCumObservedCumExpectedICTable CNONEIC
	JOIN SignalData_EducationalSprint_2018Dec.aux.IC_lx IClx ON CNONEIC.CumulNObserved = IClx.Observed
ORDER BY CNONEIC.GroupId, CNONEIC.Year;

---96170885 rows

--test

SELECT * 
FROM DatabaseName2.SDGProject.SDGCumObservedCumExpectedICTableShrinkage
WHERE PT_CODE = '10007554' AND GroupId = '1189'
ORDER BY GroupId, [Year]

