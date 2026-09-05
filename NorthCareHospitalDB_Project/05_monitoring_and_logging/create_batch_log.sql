--Creates the monitoring schema if it does not exist already
IF NOT EXISTS 
(
    SELECT 1 
    FROM sys.schemas
    WHERE name = 'monitoring'
)
BEGIN
    EXEC('CREATE SCHEMA monitoring');
END;
GO

--creates the batch log table

CREATE TABLE monitoring.etl_batch_log
(
    batch_id INT IDENTITY(1,1) PRIMARY KEY,

    pipeline_name VARCHAR(100) NOT NULL,
    table_name VARCHAR(100) NOT NULL,

    start_time DATETIME2(0) NOT NULL,
    end_time DATETIME2(0),

    status VARCHAR(20) NOT NULL,

    records_read INT DEFAULT 0,
    records_staged INT DEFAULT 0,
    records_inserted INT DEFAULT 0,
    records_updated INT DEFAULT 0,
    records_quarantined INT DEFAULT 0,
    records_failed INT DEFAULT 0,

    error_message VARCHAR(1000),

    created_at DATETIME2(0) NOT NULL
        DEFAULT GETDATE()
);
GO
