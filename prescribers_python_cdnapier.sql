--Which Tennessee counties had a disproportionately high number of opioid prescriptions?

WITH final_table AS(
WITH total_count_table AS(
WITH TN_counties AS (
					  SELECT f.county, z.zip, f.state
					  FROM fips_county AS f
					  INNER JOIN zip_fips AS z
					  	USING(fipscounty)
					  WHERE state = 'TN'
					  )
SELECT 	 p.npi, p.nppes_provider_first_name|| ' '|| p.nppes_provider_last_org_name AS full_name,
         t.county, 
		 t.zip,
		 rx.drug_name,
         SUM(rx.total_claim_count) OVER(PARTITION BY p.npi, t.county,rx.drug_name) AS total_count
FROM prescriber AS p
INNER JOIN prescription AS rx
	USING (npi)
INNER JOIN TN_counties AS t
    ON p.nppes_provider_zip5=t.zip
WHERE  rx.drug_name IN(
  						 SELECT drug_name
					     FROM drug
					     WHERE opioid_drug_flag='Y'
					    )
ORDER BY t.zip, p.npi, rx.drug_name
-----------
)

SELECT *,
       COUNT (drug_name) OVER(PARTITION BY npi, zip, drug_name) AS rx_count_per_county
FROM total_count_table
ORDER BY zip, npi, drug_name
------------
)

SELECT county,
       SUM(total_count/rx_count_per_county) AS split_claim_count
FROM final_table
GROUP BY county
ORDER BY split_claim_count DESC;

-------------------------------
--Who are the top opioid prescribers in TN?
SELECT 	p.npi, p.nppes_provider_first_name|| ' '|| p.nppes_provider_last_org_name         AS full_name, 
		SUM(rx.total_claim_count)AS total_count
FROM prescriber AS p
INNER JOIN prescription AS rx
	USING (npi)
INNER JOIN drug AS d
	USING(drug_name)
WHERE d.opioid_drug_flag='Y'
GROUP BY p.npi, full_name
ORDER BY total_count DESC;
---------------

--What did the trend in overdose deaths due to opioids look like in Tennessee from 2015 to 2018?
SELECT year,
       SUM(overdose_deaths) AS total_deaths
FROM overdose_deaths
WHERE fipscounty IN (
					 SELECT DISTINCT CAST(z.fipscounty AS int)
					  FROM fips_county AS f
					  INNER JOIN zip_fips AS z
					  	USING(fipscounty)
					  WHERE state = 'TN'
					 )
GROUP BY year
ORDER BY year
-------------------

--Is there an association between rates of opioid prescriptions and overdose deaths by county?

SELECT f.county, 
       SUM(o.overdose_deaths) AS total_deaths
FROM overdose_deaths AS o
INNER JOIN fips_county AS f
	ON CAST(f.fipscounty AS int) = o.fipscounty
WHERE o.fipscounty IN (
					 SELECT DISTINCT CAST(z.fipscounty AS int)
					  FROM fips_county AS f
					  INNER JOIN zip_fips AS z
					  	USING(fipscounty)
					  WHERE state = 'TN'
					 )
GROUP BY f.county
ORDER BY total_deaths DESC;
--------------------

--Is there any association between a particular type of opioid and number of overdose deaths?

WITH final_table AS(
WITH total_count_table AS(
WITH TN_counties AS (
					  SELECT f.county, z.zip, f.state
					  FROM fips_county AS f
					  INNER JOIN zip_fips AS z
					  	USING(fipscounty)
					  WHERE state = 'TN'
					  )
SELECT 	 p.npi, p.nppes_provider_first_name|| ' '|| p.nppes_provider_last_org_name AS full_name,
         t.county, 
		 t.zip,
		 rx.drug_name,
         SUM(rx.total_claim_count) OVER(PARTITION BY p.npi, t.county,rx.drug_name) AS total_count
FROM prescriber AS p
INNER JOIN prescription AS rx
	USING (npi)
INNER JOIN TN_counties AS t
    ON p.nppes_provider_zip5=t.zip
WHERE  rx.drug_name IN(
  						 SELECT drug_name
					     FROM drug
					     WHERE opioid_drug_flag='Y'
					    )
ORDER BY t.zip, p.npi, rx.drug_name
)

SELECT *,
       COUNT (drug_name) OVER(PARTITION BY npi, zip, drug_name) AS rx_count_per_county
FROM total_count_table

)
SELECT county, drug_name,
       SUM(total_count/rx_count_per_county) AS split_claim_count
FROM final_table
GROUP BY county, drug_name
ORDER BY split_claim_count DESC;

