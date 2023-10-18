--Get the basics on the data including determining from a high-level perspective if there were significant changes from 
--prior year data (2021).

SELECT COUNT(*)
FROM "2022_toxins" t;
-- There were 157,446 toxic release records for 2022
SELECT COUNT(*)
FROM "2021_toxins" t;
-- There were 155,030 toxic release records for 2021
SELECT COUNT(DISTINCT "4. FACILITY NAME")
FROM "2022_toxins" t;
-- There were 18,888 unique facilities with releases in 2022
SELECT COUNT(DISTINCT "4. FACILITY NAME")
FROM "2021_toxins" t;
-- There were 18,619 unique facilities with releases in 2021


-- Identify the worst (top 10) States for total releases in 2022
SELECT "8. ST", "62. ON-SITE RELEASE TOTAL", "85. OFF-SITE RELEASE TOTAL",
	ROUND("62. ON-SITE RELEASE TOTAL" + "85. OFF-SITE RELEASE TOTAL",1) AS RELEASE_TOTAL
FROM "2022_toxins" t
WHERE "RELEASE_TOTAL" > 0
GROUP BY "8. ST"
ORDER BY "RELEASE_TOTAL" DESC LIMIT 10;


-- Identify the worst (top 10) Cities for total releases in 2022
SELECT "6. CITY", "8. ST","62. ON-SITE RELEASE TOTAL", "85. OFF-SITE RELEASE TOTAL",
	ROUND("62. ON-SITE RELEASE TOTAL" + "85. OFF-SITE RELEASE TOTAL",1) AS RELEASE_TOTAL
FROM "2022_toxins" t
WHERE "RELEASE_TOTAL" > 0
GROUP BY "8. ST"
ORDER BY "RELEASE_TOTAL" DESC LIMIT 10;


-- Identify facilities with the highest levels of releases in total.
SELECT "4. FACILITY NAME", "1. YEAR",  "6. CITY" ,"7. COUNTY","8. ST", "9. ZIP",
	"12. LATITUDE", "13. LONGITUDE","20. INDUSTRY SECTOR", "34. CHEMICAL", "35. ELEMENTAL METAL INCLUDED",
	"39. CLEAN AIR ACT CHEMICAL", "41. METAL", "42. METAL CATEGORY", "43. CARCINOGEN", "44. PBT",
	"45. PFAS", "47. UNIT OF MEASURE", "62. ON-SITE RELEASE TOTAL", "85. OFF-SITE RELEASE TOTAL",
	ROUND("62. ON-SITE RELEASE TOTAL" + "85. OFF-SITE RELEASE TOTAL",1) AS RELEASE_TOTAL,
FROM "2022_toxins" t
WHERE "RELEASE_TOTAL" > 0
GROUP BY "4. FACILITY NAME"
ORDER BY "RELEASE_TOTAL" DESC LIMIT 20;


-- Look at a quartile division of on-site release values to get a sense of the relative levels of on-site releases.
SELECT	
	"1. YEAR",
	MAX(CASE WHEN Quartile = 1 THEN "62. ON-SITE RELEASE TOTAL" END) Q1,
	MAX(CASE WHEN Quartile = 2 THEN "62. ON-SITE RELEASE TOTAL" END) Median,
	MAX(CASE WHEN Quartile = 3 THEN "62. ON-SITE RELEASE TOTAL" END) Q3,
	MAX("62. ON-SITE RELEASE TOTAL") AS Maximum,
	COUNT(Quartile) AS Count
FROM (
	SELECT
		"4. FACILITY NAME",
		"62. ON-SITE RELEASE TOTAL",
		NTILE(4) OVER (PARTITION BY "4. FACILITY NAME" ORDER BY "62. ON-SITE RELEASE TOTAL") AS Quartile
	FROM "2022_toxins" t
) Vals
GROUP BY
	"1. YEAR"
ORDER BY
	"1. YEAR";
--Median on-site toxic release value is 1,899,659 pounds (round to 1.9 million); the maximum is 327,375,324 pounds.


-- Identify facilities with the highest levels (TOP 20) of carcinogen-related releases.
SELECT "4. FACILITY NAME", "1. YEAR","43. CARCINOGEN", "44. PBT",
	"45. PFAS", "47. UNIT OF MEASURE", "62. ON-SITE RELEASE TOTAL", "85. OFF-SITE RELEASE TOTAL",
	ROUND("62. ON-SITE RELEASE TOTAL" + "85. OFF-SITE RELEASE TOTAL",0) AS RELEASE_TOTAL
FROM "2022_toxins" t
WHERE "RELEASE_TOTAL" > 0 AND "43. CARCINOGEN" = "YES"
GROUP BY "4. FACILITY NAME"
ORDER BY "RELEASE_TOTAL" DESC LIMIT 20;

-- Compare 2022 with 2021 releases to determine which locations repeated as a top carcinogen release facility.
SELECT "4. FACILITY NAME", "1. YEAR", "43. CARCINOGEN", "44. PBT",
	"45. PFAS", "47. UNIT OF MEASURE", "62. ON-SITE RELEASE TOTAL", "85. OFF-SITE RELEASE TOTAL",
	ROUND("62. ON-SITE RELEASE TOTAL" + "85. OFF-SITE RELEASE TOTAL",0) AS RELEASE_TOTAL
FROM "2022_toxins" t
WHERE "RELEASE_TOTAL" > 0 AND "43. CARCINOGEN" = "YES"
GROUP BY "4. FACILITY NAME"
UNION ALL
SELECT "4. FACILITY NAME", "1. YEAR","43. CARCINOGEN", "44. PBT",
	"45. PFAS", "47. UNIT OF MEASURE", "62. ON-SITE RELEASE TOTAL", "85. OFF-SITE RELEASE TOTAL",
	ROUND("62. ON-SITE RELEASE TOTAL" + "85. OFF-SITE RELEASE TOTAL",0) AS RELEASE_TOTAL
FROM "2021_toxins" t
WHERE "RELEASE_TOTAL" > 0 AND "43. CARCINOGEN" = "YES"
GROUP BY "4. FACILITY NAME"
ORDER BY "RELEASE_TOTAL" DESC LIMIT 20;


--Use a CTE to determine the average levels of the largest chemical release types (I chose more than 1,000 pound per event), 
--compard to the number of release events for that chemical type.
WITH ChemCount AS (
  SELECT "34. CHEMICAL" AS CHEMICAL, COUNT("34. CHEMICAL") as release_count
  FROM "2022_toxins"
  GROUP BY "34. CHEMICAL"
)
SELECT "34. CHEMICAL" AS CHEMICAL, ROUND(AVG("62. ON-SITE RELEASE TOTAL" + "85. OFF-SITE RELEASE TOTAL"),0) AS avg_release, cc.release_count
FROM "2022_toxins" t
JOIN ChemCount cc
ON t."34. CHEMICAL" = cc.CHEMICAL
GROUP BY "34. CHEMICAL"
HAVING avg_release > 1000
ORDER BY avg_release DESC;


--Identify the facilities/locations, in all states except Alaska (oil drilling) and Nevada (mining) the lower 48 US States, 
--of carcinogen chemical releases in number and high size released onsite (i.e., on/into land, in water, 
--and into the air). While there are likely many factors determining the most seriously impacted communities of toxic releases, 
--this data is likely one indicator of the most impacted locations.
WITH FacilityCount AS (
  SELECT "4. FACILITY NAME" AS FN, COUNT("34. CHEMICAL") as release_count
  FROM "2022_toxins"
  WHERE "43. CARCINOGEN" = 'YES'
  GROUP BY "4. FACILITY NAME"
)
SELECT t."4. FACILITY NAME" AS FN, t."6. CITY", t."8. ST", CAST(t."62. ON-SITE RELEASE TOTAL" AS INTEGER), fc.release_count
FROM "2022_toxins" t
JOIN FacilityCount fc ON t."4. FACILITY NAME" = fc.FN
WHERE "62. ON-SITE RELEASE TOTAL" > 1000 AND fc.release_count > 2 AND t."43. CARCINOGEN" = 'YES' AND t."8. ST" NOT IN ('AK', 'PR', 'NV')
GROUP BY t."4. FACILITY NAME", t."6. CITY", t."8. ST"
ORDER BY "62. ON-SITE RELEASE TOTAL" DESC
LIMIT 20;


--Some toxic chemical releases are destined for recycling or for energy recovery. Which released chemicals fell into this category in 2022,
--and of those how much of such released chemicals were not recycled or used to recover chemicals for energy purposes?
WITH RecycledCHEM AS (
  SELECT "34. CHEMICAL" AS CHEMICAL, CAST(SUM("112. 8.4 – RECYCLING ON SITE" + "113. 8.5 – RECYCLING OFF SITE") AS INTEGER) AS RECYCLED_RECOVERY
  FROM "2022_toxins"
  GROUP BY "34. CHEMICAL"
),
EnergyCHEM AS (
  SELECT "34. CHEMICAL" AS CHEMICAL, CAST(SUM("110. 8.2 – ENERGY RECOVERY ON SITE" + "111. 8.3 – ENERGY RECOVERY OFF SITE") AS INTEGER) AS ENERGY_RECOVERY
  FROM "2022_toxins"
  GROUP BY "34. CHEMICAL"
),
ReleasedCHEM AS (
  SELECT "34. CHEMICAL" AS CHEMICAL, CAST(("62. ON-SITE RELEASE TOTAL" + "85. OFF-SITE RELEASE TOTAL") AS INTEGER) AS RELEASE_TOTAL
  FROM "2022_toxins"
  GROUP BY "34. CHEMICAL"
)
SELECT sc.CHEMICAL, sc.RELEASE_TOTAL, rc.RECYCLED_RECOVERY, ec.ENERGY_RECOVERY,
  (rc.RECYCLED_RECOVERY + ec.ENERGY_RECOVERY) AS TOTAL_RECOVERY,
  ROUND(((rc.RECYCLED_RECOVERY + ec.ENERGY_RECOVERY) * 1.0 / sc.RELEASE_TOTAL), 1) AS RecovAsPercentOfReleased
FROM "2022_toxins" AS t
JOIN RecycledCHEM rc ON t."34. CHEMICAL" = rc.CHEMICAL
JOIN EnergyCHEM ec ON t."34. CHEMICAL" = ec.CHEMICAL
JOIN ReleasedCHEM sc ON t."34. CHEMICAL" = sc.CHEMICAL
GROUP BY "34. CHEMICAL"
HAVING sc.RELEASE_TOTAL > 1000
ORDER BY RecovAsPercentOfReleased DESC;


--Create selected views for future visualizations.
CREATE VIEW WorstReleaseLoc_carcinogens AS
WITH FacilityCount AS (
  SELECT "4. FACILITY NAME" AS FN, COUNT("34. CHEMICAL") as release_count
  FROM "2022_toxins"
  WHERE "43. CARCINOGEN" = 'YES'
  GROUP BY "4. FACILITY NAME"
)
SELECT t."4. FACILITY NAME" AS FN, t."6. CITY", t."8. ST", CAST(t."62. ON-SITE RELEASE TOTAL" AS INTEGER), fc.release_count
FROM "2022_toxins" t
JOIN FacilityCount fc ON t."4. FACILITY NAME" = fc.FN
WHERE "62. ON-SITE RELEASE TOTAL" > 1000 AND fc.release_count > 2 AND t."43. CARCINOGEN" = 'YES' AND t."8. ST" NOT IN ('AK', 'PR', 'NV')
GROUP BY t."4. FACILITY NAME", t."6. CITY", t."8. ST"
ORDER BY "62. ON-SITE RELEASE TOTAL" DESC
LIMIT 20;


CREATE VIEW LargestChemicalReleases AS
WITH ChemCount AS (
  SELECT "34. CHEMICAL" AS CHEMICAL, COUNT("34. CHEMICAL") as release_count
  FROM "2022_toxins"
  GROUP BY "34. CHEMICAL"
)
SELECT "34. CHEMICAL" AS CHEMICAL, ROUND(AVG("62. ON-SITE RELEASE TOTAL" + "85. OFF-SITE RELEASE TOTAL"),0) AS avg_release, cc.release_count
FROM "2022_toxins" t
JOIN ChemCount cc
ON t."34. CHEMICAL" = cc.CHEMICAL
GROUP BY "34. CHEMICAL"
HAVING avg_release > 1000
ORDER BY avg_release DESC;


CREATE VIEW ReusedVsReleased AS
WITH RecycledCHEM AS (
  SELECT "34. CHEMICAL" AS CHEMICAL, CAST(SUM("112. 8.4 – RECYCLING ON SITE" + "113. 8.5 – RECYCLING OFF SITE") AS INTEGER) AS RECYCLED_RECOVERY
  FROM "2022_toxins"
  GROUP BY "34. CHEMICAL"
),
EnergyCHEM AS (
  SELECT "34. CHEMICAL" AS CHEMICAL, CAST(SUM("110. 8.2 – ENERGY RECOVERY ON SITE" + "111. 8.3 – ENERGY RECOVERY OFF SITE") AS INTEGER) AS ENERGY_RECOVERY
  FROM "2022_toxins"
  GROUP BY "34. CHEMICAL"
),
ReleasedCHEM AS (
  SELECT "34. CHEMICAL" AS CHEMICAL, CAST(("62. ON-SITE RELEASE TOTAL" + "85. OFF-SITE RELEASE TOTAL") AS INTEGER) AS RELEASE_TOTAL
  FROM "2022_toxins"
  GROUP BY "34. CHEMICAL"
)
SELECT sc.CHEMICAL, sc.RELEASE_TOTAL, rc.RECYCLED_RECOVERY, ec.ENERGY_RECOVERY,
  (rc.RECYCLED_RECOVERY + ec.ENERGY_RECOVERY) AS TOTAL_RECOVERY,
  ROUND(((rc.RECYCLED_RECOVERY + ec.ENERGY_RECOVERY) * 1.0 / sc.RELEASE_TOTAL), 1) AS RecovAsPercentOfReleased
FROM "2022_toxins" AS t
JOIN RecycledCHEM rc ON t."34. CHEMICAL" = rc.CHEMICAL
JOIN EnergyCHEM ec ON t."34. CHEMICAL" = ec.CHEMICAL
JOIN ReleasedCHEM sc ON t."34. CHEMICAL" = sc.CHEMICAL
GROUP BY "34. CHEMICAL"
HAVING sc.RELEASE_TOTAL > 1000
ORDER BY RecovAsPercentOfReleased DESC;