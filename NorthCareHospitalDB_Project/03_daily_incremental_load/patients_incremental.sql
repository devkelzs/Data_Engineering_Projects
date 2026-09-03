TRUNCATE TABLE staging.Patients;

WITH transformed_patient AS 
(
	SELECT 
		TRIM(patient_id) AS patient_id_raw,
		TRY_CAST(patient_id AS INT) AS patient_id,
	
		CASE
			WHEN NULLIF(TRIM(first_name), '') IS NULL THEN NULL
			WHEN LOWER(TRIM(first_name)) IN ('null', 'n/a', 'not_available') THEN NULL
			ELSE TRIM(first_name)
		END AS first_name,

		CASE
			WHEN NULLIF(TRIM(last_name), '') IS NULL THEN NULL
			WHEN LOWER(TRIM(last_name)) IN ('null', 'n/a', 'not_available') THEN NULL
			ELSE TRIM(last_name)
		END AS last_name,
		CASE 
			WHEN LOWER(TRIM(gender)) IN ('male','m') THEN 'M'
			WHEN LOWER(TRIM(gender)) IN ('female', 'f') THEN 'F'
			ELSE NULL
		END AS gender,

		TRY_CAST(date_of_birth AS DATE) AS date_of_birth,
		TRY_CAST(registration_date AS DATETIME2(0)) AS registration_date,
		NULLIF(TRIM(notes), '') AS notes,

		CASE 
			WHEN NULLIF(TRIM(email), '') IS NULL THEN NULL
			WHEN LOWER(TRIM(email)) IN ('null', 'n/a',  'not_available') THEN NULL
			ELSE LOWER(TRIM(email))
		END AS email,

		CASE 
			-- 1. Missing phone
			WHEN NULLIF(TRIM(phone), '') IS NULL THEN NULL
			WHEN LOWER(TRIM(phone)) IN ('null', 'n/a', 'not_available') THEN NULL
			-- 2. Already has +237
			WHEN p.cleaned_phone LIKE '+237%' THEN p.cleaned_phone
			-- 3. Starts with 237 but is missing +
			WHEN p.cleaned_phone LIKE '237%' THEN '+' + p.cleaned_phone
			-- 4. Local Cameroon number starting with 6
			WHEN p.cleaned_phone LIKE '6%' THEN '+237' + p.cleaned_phone
			-- 5. Cannot confidently standardize
			ELSE NULL
		END AS phone,

		CASE 
			WHEN NULLIF(TRIM(city), '') IS NULL THEN NULL
			WHEN LOWER(TRIM(city)) IN ('null', 'n/a',  'not_available') THEN NULL
			ELSE TRIM(city)
		END AS city,

		CASE 
			WHEN NULLIF(TRIM(blood_group), '') IS NULL THEN NULL
			-- FIX: Replaced the typo with correct blood_group evaluation
			WHEN LOWER(TRIM(blood_group)) IN ('null', 'n/a',  'not_available', 'unknown') THEN NULL
			ELSE TRIM(blood_group)
		END AS blood_group,

		---Quality Flags 
		-----Quality flags for birthdate
		CASE 
			WHEN date_of_birth IS NULL THEN 1
			WHEN TRIM(date_of_birth) = '' THEN 1
			WHEN LOWER(TRIM(date_of_birth)) IN ('null', 'n/a', 'not_available') THEN 1
			ELSE 0
		END AS is_missing_birthdate,

		CASE 
			WHEN TRY_CAST(date_of_birth AS DATE) IS NULL THEN 0
			WHEN TRY_CAST(date_of_birth AS DATE) <= CAST(GETDATE() AS DATE) THEN 1
			ELSE 0
		END AS is_valid_birthdate,

		---Quality flags for email
		CASE 
			WHEN email IS NULL THEN 1
			WHEN TRIM(email) = '' THEN 1
			WHEN LOWER(TRIM(email)) IN ('null', 'n/a', 'not_available') THEN 1 
			ELSE 0
		END AS is_missing_email,

		CASE 
			WHEN email IS NULL THEN 0
			WHEN TRIM(email) = '' THEN 0
			WHEN LOWER(TRIM(email)) IN ('null', 'n/a', 'not_available') THEN 0 
			WHEN LEN(TRIM(email)) - LEN(REPLACE(TRIM(email), '@', '')) <> 1 THEN 0
			WHEN TRIM(email) NOT LIKE '%@%' THEN 0
			WHEN CHARINDEX('@', TRIM(email)) = 1 THEN 0
			WHEN CHARINDEX('@', TRIM(email)) = LEN(TRIM(email)) THEN 0
			WHEN CHARINDEX('.', SUBSTRING(TRIM(email), CHARINDEX('@', TRIM(email)) + 1, LEN(TRIM(email)))) = 0 THEN 0
			ELSE 1
		END AS is_valid_email,

		---Quality flags for phone
		CASE
			WHEN phone IS NULL THEN 1
			WHEN TRIM(phone) = '' THEN 1
			WHEN LOWER(TRIM(phone)) IN ('null', 'n/a', 'not_available') THEN 1
			ELSE 0 
		END AS is_missing_phone,

		CASE
			WHEN phone IS NULL THEN 0
			WHEN TRIM(phone) = '' THEN 0
			WHEN LOWER(TRIM(phone)) IN ('null', 'n/a', 'not_available') THEN 0
			-- +237XXXXXXXXX
			WHEN LEFT(p.cleaned_phone, 4) = '+237'
				 AND LEN(p.cleaned_phone) = 13
				 AND SUBSTRING(p.cleaned_phone, 5, 1) = '6'
				THEN 1
			-- 237XXXXXXXXX
			WHEN LEFT(p.cleaned_phone, 3) = '237'
				 AND LEN(p.cleaned_phone) = 12
				 AND SUBSTRING(p.cleaned_phone, 4, 1) = '6'
				THEN 1
			-- Local 9-digit Cameroon number
			WHEN LEN(p.cleaned_phone) = 9
				 AND LEFT(p.cleaned_phone, 1) = '6'
				THEN 1
			ELSE 0
		END AS is_valid_phone,

		---Quality flags for gender
		CASE 
			WHEN gender IS NULL 
				OR TRIM(gender) = ''
				OR LOWER(TRIM(gender)) IN ('null', 'n/a', 'not_available') 
			THEN 1
			ELSE 0
		END AS is_missing_gender,

		CASE 
			WHEN LOWER(TRIM(gender)) IN ('m', 'f', 'female', 'male') THEN 1
			ELSE 0
		END AS is_valid_gender,

		CASE
			 WHEN first_name IS NOT NULL
				AND last_name IS NOT NULL
				AND date_of_birth IS NOT NULL
				AND COUNT(*) OVER (
					 PARTITION BY
						   UPPER(TRIM(first_name)),
						   UPPER(TRIM(last_name)),
						   date_of_birth
                ) > 1
                THEN 1
                ELSE 0
		END AS is_duplicate_candidate


	FROM raw.Patients

	CROSS APPLY (
		SELECT
			REPLACE(REPLACE(REPLACE(REPLACE(TRIM(phone), ' ', ''), '-', ''), '(', ''), ')', '') AS cleaned_phone
	) p	
),

with_hash AS 
(
    SELECT 
        *,
         HASHBYTES(
            'SHA2_256',
            CAST(
                CONCAT(
                    COALESCE(TRIM(first_name), ''), '|',
                    COALESCE(TRIM(last_name), ''), '|',
                    COALESCE(TRIM(gender), ''), '|',
                    COALESCE(CONVERT(VARCHAR(10), date_of_birth, 23), ''), '|',
                    COALESCE(LOWER(TRIM(email)), ''), '|',
                    COALESCE(TRIM(phone), ''), '|',
                    COALESCE(TRIM(city), ''), '|',
                    COALESCE(TRIM(blood_group), ''), '|',
                    COALESCE(
                        CONVERT(VARCHAR(19), registration_date, 120),
                        ''
                    ), '|',
                    COALESCE(TRIM(notes), '')
                ) AS VARCHAR(1000)
            )
        ) AS record_hash

    FROM transformed_patient
),

record_classification AS 
(
    SELECT 
        r.*,

        CASE 
            WHEN s.patient_id IS NULL THEN 'NEW'
            WHEN ISNULL(r.record_hash, 0x) <> ISNULL(s.record_hash, 0x) THEN 'CHANGED'
            ELSE 'UNCHANGED'
        END AS record_status
    
    FROM with_hash r 
    LEFT JOIN silver.Patients s
        ON r.patient_id = s.patient_id  
    
),

incremental_patients AS
(
    SELECT *
    FROM record_classification
    WHERE record_status IN ('NEW', 'CHANGED')
),


with_complete_record AS
(
    SELECT
        *,
        
        CASE
            WHEN patient_id IS NOT NULL
                 AND (first_name IS NOT NULL OR last_name IS NOT NULL)
                 AND (is_valid_email = 1 OR is_valid_phone = 1)
                 AND is_valid_birthdate = 1
                 AND is_valid_gender = 1
                 AND registration_date IS NOT NULL
            THEN 1
            ELSE 0
        END AS is_complete_record

    FROM incremental_patients
),

with_quality_score AS 
(
	SELECT
		*,
    
		CASE WHEN is_valid_email = 1 THEN 15 ELSE 0 END
		+
		CASE WHEN is_valid_phone = 1 THEN 15 ELSE 0 END
		+
		CASE WHEN is_valid_birthdate = 1 THEN 15 ELSE 0 END
		+
		CASE WHEN is_valid_gender = 1 THEN 10 ELSE 0 END
		+
		CASE WHEN is_complete_record = 1 THEN 35 ELSE 0 END
		+
		CASE WHEN is_duplicate_candidate = 0 THEN 10 ELSE 0 END
		AS record_quality_score

	FROM with_complete_record
),

final_validation AS 
(
    SELECT
        *,

        CASE 
            WHEN NULLIF(TRIM(patient_id_raw), '') IS NULL THEN 0
            WHEN TRY_CAST(patient_id_raw AS INT) IS NULL THEN 0
            ELSE 1
        END AS passes_final_validation,

        CASE 
            WHEN NULLIF(TRIM(patient_id_raw), '') IS NULL 
                THEN 'Missing Patient ID'

            WHEN TRY_CAST(patient_id_raw AS INT) IS NULL 
                THEN 'Invalid Patient ID'

            ELSE NULL
        END AS quarantine_reason,

        -- Human-readable data quality issues
        NULLIF(
            CONCAT_WS('; ',

                CASE 
                    WHEN is_missing_birthdate = 1 
                        THEN 'Missing birthdate'
                    WHEN is_valid_birthdate = 0 
                        THEN 'Invalid birthdate'
                END,

                CASE 
                    WHEN is_missing_email = 1 
                        THEN 'Missing email'
                    WHEN is_valid_email = 0 
                        THEN 'Invalid email'
                END,

                CASE 
                    WHEN is_missing_phone = 1 
                        THEN 'Missing phone'
                    WHEN is_valid_phone = 0 
                        THEN 'Invalid phone'
                END,

                CASE 
                    WHEN is_missing_gender = 1 
                        THEN 'Missing gender'
                    WHEN is_valid_gender = 0 
                        THEN 'Invalid gender'
                END,

                CASE 
                    WHEN is_duplicate_candidate = 1 
                        THEN 'Duplicate candidate'
                END
            ),
            ''
        ) AS data_quality_issue,

        -- ETL metadata
        CAST(GETDATE() AS DATETIME2(0)) AS load_timestamp,

        CAST(GETDATE() AS DATETIME2(0)) AS last_updated_timestamp

    FROM with_quality_score
)

INSERT INTO staging.Patients
(
    patient_id_raw,
    patient_id,
    first_name,
    last_name,
    gender,
    date_of_birth,
    email,
    phone,
    city,
    blood_group,
    registration_date,
    notes,

    is_valid_email,
    is_missing_email,

    is_valid_phone,
    is_missing_phone,

    is_valid_birthdate,
    is_missing_birthdate,

    is_valid_gender,
    is_missing_gender,

    is_complete_record,
    is_duplicate_candidate,

    record_quality_score,

    data_quality_issue,

    passes_final_validation,

    quarantine_reason,

    load_timestamp,
    last_updated_timestamp,

    record_hash,

    record_status
)
SELECT
    patient_id_raw,
    patient_id,
    first_name,
    last_name,
    gender,
    date_of_birth,
    email,
    phone,
    city,
    blood_group,
    registration_date,
    notes,

    is_valid_email,
    is_missing_email,

    is_valid_phone,
    is_missing_phone,

    is_valid_birthdate,
    is_missing_birthdate,

    is_valid_gender,
    is_missing_gender,

    is_complete_record,
    is_duplicate_candidate,

    record_quality_score,

    data_quality_issue,

    passes_final_validation,

    quarantine_reason,

    load_timestamp,
    last_updated_timestamp,

    record_hash,

    record_status

FROM final_validation;
