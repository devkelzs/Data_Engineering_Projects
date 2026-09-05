CREATE OR ALTER PROCEDURE etl.usp_validate_patients
    @batch_id INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @records_inserted INT;
    DECLARE @records_updated INT;
    DECLARE @records_quarantined INT;


   
    -- 1. INSERT NEW VALID RECORDS INTO SILVER
    

    INSERT INTO silver.Patients
    (
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
        load_timestamp,
        last_updated_timestamp,
        record_hash
    )
    SELECT
        st.patient_id,
        st.first_name,
        st.last_name,
        st.gender,
        st.date_of_birth,
        st.email,
        st.phone,
        st.city,
        st.blood_group,
        st.registration_date,
        st.notes,
        st.is_valid_email,
        st.is_missing_email,
        st.is_valid_phone,
        st.is_missing_phone,
        st.is_valid_birthdate,
        st.is_missing_birthdate,
        st.is_valid_gender,
        st.is_missing_gender,
        st.is_complete_record,
        st.is_duplicate_candidate,
        st.record_quality_score,
        st.data_quality_issue,
        st.load_timestamp,
        st.last_updated_timestamp,
        st.record_hash
    FROM staging.Patients st
    WHERE st.record_status = 'NEW'
      AND st.passes_final_validation = 1
      AND NOT EXISTS
      (
          SELECT 1
          FROM silver.Patients s
          WHERE s.patient_id = st.patient_id
      );


    -- Capture number of NEW records inserted
    SET @records_inserted = @@ROWCOUNT;



    -- 2. UPDATE CHANGED VALID RECORDS IN SILVER


    UPDATE s
    SET
        s.first_name = st.first_name,
        s.last_name = st.last_name,
        s.gender = st.gender,
        s.date_of_birth = st.date_of_birth,
        s.email = st.email,
        s.phone = st.phone,
        s.city = st.city,
        s.blood_group = st.blood_group,
        s.registration_date = st.registration_date,
        s.notes = st.notes,

        s.is_valid_email = st.is_valid_email,
        s.is_missing_email = st.is_missing_email,
        s.is_valid_phone = st.is_valid_phone,
        s.is_missing_phone = st.is_missing_phone,
        s.is_valid_birthdate = st.is_valid_birthdate,
        s.is_missing_birthdate = st.is_missing_birthdate,
        s.is_valid_gender = st.is_valid_gender,
        s.is_missing_gender = st.is_missing_gender,
        s.is_complete_record = st.is_complete_record,
        s.is_duplicate_candidate = st.is_duplicate_candidate,

        s.record_quality_score = st.record_quality_score,
        s.data_quality_issue = st.data_quality_issue,

        s.last_updated_timestamp = st.last_updated_timestamp,
        s.record_hash = st.record_hash

    FROM silver.Patients s
    JOIN staging.Patients st
        ON s.patient_id = st.patient_id

    WHERE st.record_status = 'CHANGED'
      AND st.passes_final_validation = 1;


    -- Capture number of CHANGED records updated
    SET @records_updated = @@ROWCOUNT;


  
    -- 3. INSERT INVALID RECORDS INTO QUARANTINE
    

    INSERT INTO quarantine.Patients
    (
        patient_id_raw,
        first_name,
        last_name,
        gender,
        date_of_birth,
        email,
        phone,
        city,
        blood_group,
        registration_date,
        quarantine_reason,
        quarantine_timestamp
    )
    SELECT
        st.patient_id_raw,
        st.first_name,
        st.last_name,
        st.gender,
        CONVERT(VARCHAR(50), st.date_of_birth),
        st.email,
        st.phone,
        st.city,
        st.blood_group,
        CONVERT(VARCHAR(50), st.registration_date),
        st.quarantine_reason,
        GETDATE()
    FROM staging.Patients st
    WHERE st.passes_final_validation = 0
      AND NOT EXISTS
      (
          SELECT 1
          FROM quarantine.Patients q
          WHERE q.patient_id_raw = st.patient_id_raw
            AND q.first_name = st.first_name
            AND q.last_name = st.last_name
            AND q.quarantine_reason = st.quarantine_reason
      );


    -- Capture number of records sent to quarantine
    SET @records_quarantined = @@ROWCOUNT;



    -- 4. UPDATE MONITORING TABLE
   

    UPDATE monitoring.etl_batch_log
    SET
        records_inserted = @records_inserted,
        records_updated = @records_updated,
        records_quarantined = @records_quarantined

    WHERE batch_id = @batch_id;


END;
GO
