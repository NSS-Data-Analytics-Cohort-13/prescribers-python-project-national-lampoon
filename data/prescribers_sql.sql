--1. Which Tennessee counties had a disproportionately high number of opioid prescriptions?
WITH opioid_npi AS (SELECT p.npi, SUM(p.total_claim_count) AS total_claims
					FROM drug AS d
					INNER JOIN prescription AS p
					ON d.drug_name = p.drug_name
					WHERE d.opioid_drug_flag = 'Y'
					GROUP BY npi)

SELECT o.npi, o.total_claims, z.zip, z.fipscounty, f.county, f.state, z.tot_ratio
FROM opioid_npi AS o
INNER JOIN prescriber AS p
ON o.npi=p.npi
INNER JOIN zip_fips AS z
ON p.nppes_provider_zip5=z.zip
INNER JOIN fips_county AS f
ON z.fipscounty=f.fipscounty
WHERE f.state = 'TN'
ORDER BY zip


SELECT f.county, pop.population
FROM population AS pop
INNER JOIN fips_county AS f
ON pop.fipscounty=f.fipscounty
ORDER BY population DESC


SELECT SUM(p.total_claim_count) AS total_claims
					FROM drug AS d
					INNER JOIN prescription AS p
					ON d.drug_name = p.drug_name
					WHERE d.opioid_drug_flag = 'Y'

--2. Who are the top opioid prescibers for the state of Tennessee?
WITH opioid_npi AS (SELECT p.npi, SUM(p.total_claim_count) AS total_claims
					FROM drug AS d
					INNER JOIN prescription AS p
					ON d.drug_name = p.drug_name
					WHERE d.opioid_drug_flag = 'Y'
					GROUP BY npi)

SELECT p.nppes_provider_first_name|| ' ' || p.nppes_provider_last_org_name AS full_name, o.npi, o.total_claims
FROM opioid_npi AS o
INNER JOIN prescriber AS p
ON o.npi=p.npi
ORDER BY o.total_claims DESC

--3. What did the trend in overdose deaths due to opioids look like in Tennessee from 2015 to 2018?

--To determine total # of deaths per county
SELECT SUM (o.overdose_deaths) AS o_deaths, o.year, f.county
FROM overdose_deaths AS o
INNER JOIN fips_county AS f
ON CAST (f.fipscounty AS int) = o.fipscounty
GROUP BY f.county, o.year
ORDER BY f.county, o.year

--To determine total # of deaths per year
SELECT SUM (overdose_deaths), year
FROM overdose_deaths
GROUP BY year
ORDER BY year

--To determine if any other states are within the overdose_death table
SELECT o.overdose_deaths, o.year, o.fipscounty, f.state
FROM overdose_deaths AS o
INNER JOIN fips_county AS f
ON CAST (f.fipscounty AS int) = o.fipscounty
WHERE state = 'TN'

--4. Is there an association between rates of opioid prescriptions and overdose deaths by county?
WITH prescriptions AS (WITH opioid_npi AS (SELECT p.npi, SUM(p.total_claim_count) AS total_claims
							FROM drug AS d
							INNER JOIN prescription AS p
							ON d.drug_name = p.drug_name
							WHERE d.opioid_drug_flag = 'Y'
							GROUP BY npi)
		
		SELECT o.npi, o.total_claims, z.zip, z.fipscounty, f.county, f.state
		FROM opioid_npi AS o
		INNER JOIN prescriber AS p
		ON o.npi=p.npi
		INNER JOIN zip_fips AS z
		ON p.nppes_provider_zip5=z.zip
		INNER JOIN fips_county AS f
		ON z.fipscounty=f.fipscounty
		WHERE f.state = 'TN')

,

county_deaths AS (SELECT SUM (o.overdose_deaths) AS total_overdose, f.county
		FROM overdose_deaths AS o
		INNER JOIN fips_county AS f
		ON CAST (f.fipscounty AS int) = o.fipscounty
		GROUP BY f.county
		ORDER BY f.county)

SELECT p.county, SUM(p.total_claims) AS claims_total, c.total_overdose
FROM prescriptions AS p
INNER JOIN county_deaths AS c
ON p.county=c.county
GROUP BY p.county, c.total_overdose
ORDER BY c.total_overdose DESC, claims_total

--5. Is there any association between a particular type of opioid and number of overdose deaths?

--1st try
WITH prescriptions AS (WITH opioid_npi AS (SELECT p.npi, SUM(p.total_claim_count) AS total_claims
							FROM drug AS d
							INNER JOIN prescription AS p
							ON d.drug_name = p.drug_name
							WHERE d.opioid_drug_flag = 'Y'
							GROUP BY npi)
		
		SELECT o.npi, o.total_claims, z.zip, z.fipscounty, f.county, f.state
		FROM opioid_npi AS o
		INNER JOIN prescriber AS p
		ON o.npi=p.npi
		INNER JOIN zip_fips AS z
		ON p.nppes_provider_zip5=z.zip
		INNER JOIN fips_county AS f
		ON z.fipscounty=f.fipscounty
		WHERE f.state = 'TN')

,

county_deaths AS (SELECT SUM (o.overdose_deaths) AS total_overdose, f.county
		FROM overdose_deaths AS o
		INNER JOIN fips_county AS f
		ON CAST (f.fipscounty AS int) = o.fipscounty
		GROUP BY f.county
		ORDER BY f.county)

,

opioid_drug AS (SELECT d.drug_name, SUM(p.total_claim_count) AS total_claims
							FROM drug AS d
							INNER JOIN prescription AS p
							ON d.drug_name = p.drug_name
							WHERE d.opioid_drug_flag = 'Y'
							GROUP BY d.drug_name)


SELECT *
FROM prescriptions AS p
INNER JOIN county_deaths AS c
ON p.county=c.county
INNER JOIN opioid_drug AS o
ON p.fipscounty=o.fipscounty

--Too many joins
SELECT SUM(o.overdose_deaths), o.fipscounty, pscrpt.drug_name
FROM overdose_deaths AS o
INNER JOIN fips_county AS f --county
ON o.fipscounty=CAST (f.fipscounty AS int)
INNER JOIN zip_fips AS z --zip
ON o.fipscounty=CAST (z.fipscounty AS int)
INNER JOIN prescriber AS pscrb --zip, npi
ON z.zip=pscrb.nppes_provider_zip5
INNER JOIN prescription AS pscrpt --npi, drugname
ON pscrb.npi=pscrpt.npi
INNER JOIN drug AS d --drugname, opioidflag
ON pscrpt.drug_name=d.drug_name
WHERE d.opioid_drug_flag = 'Y'
GROUP BY o.fipscounty, f.county, pscrpt.drug_name

---Charlie's code
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