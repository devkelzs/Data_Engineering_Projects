CREATE OR ALTER PROCEDURE etl.usp_run_patients_pipeline
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE @batch_id INT;

    BEGIN TRY
        -- STEP 1: CREATE A NEW BATCH


        INSERT INTO monitoring.etl_batch_log
        (
            pipeline_name,
            table_name,
            start_time,
            status
        )
        VALUES
        (
            'Healthcare Pipeline',
            'Patients',
            GETDATE(),
            'RUNNING'
        );


        -- STEP 2: CAPTURE THE BATCH ID

        SET @batch_id = SCOPE_IDENTITY();

        -- STEP 3: RUN INCREMENTAL LOAD

        EXEC etl.usp_load_patients_incremental
            @batch_id = @batch_id;

        -- STEP 4: RUN VALIDATION

        EXEC etl.usp_validate_patients
            @batch_id = @batch_id;

        -- STEP 5: MARK BATCH AS SUCCESSFUL
    
        UPDATE monitoring.etl_batch_log
        SET
            status = 'SUCCESS',
            end_time = GETDATE()
        WHERE batch_id = @batch_id;

        END TRY

    BEGIN CATCH

        -- STEP 6: Failure handling
        DECLARE @error_message VARCHAR(1000);

        SET @error_message = ERROR_MESSAGE();

        -- MARK BATCH AS FAILED
        
        UPDATE monitoring.etl_batch_log
            SET
                status = 'FAILED',
                end_time = GETDATE(),
                error_message = @error_message
            WHERE batch_id = @batch_id;

    END CATCH;


END;
GO

