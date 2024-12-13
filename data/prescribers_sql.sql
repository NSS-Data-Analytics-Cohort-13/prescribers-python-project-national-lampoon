WITH opioid_npi AS (SELECT p.npi, SUM(p.total_claim_count) AS total_claims
					FROM drug AS d
					INNER JOIN prescription AS p
					ON d.drug_name = p.drug_name
					WHERE d.opioid_drug_flag = 'Y'
					GROUP BY npi)

SELECT o.npi, o.total_claims, z.zip, z.fipscounty, f.county, f.state--, SUM(o.total_claims) AS total
FROM opioid_npi AS o
INNER JOIN prescriber AS p
ON o.npi=p.npi
INNER JOIN zip_fips AS z
ON p.nppes_provider_zip5=z.zip
INNER JOIN fips_county AS f
ON z.fipscounty=f.fipscounty
WHERE f.state = 'TN'
GROUP BY f.county, f.state
ORDER BY total DESC

SELECT SUM(p.total_claim_count) AS total_claims
					FROM drug AS d
					INNER JOIN prescription AS p
					ON d.drug_name = p.drug_name
					WHERE d.opioid_drug_flag = 'Y'
