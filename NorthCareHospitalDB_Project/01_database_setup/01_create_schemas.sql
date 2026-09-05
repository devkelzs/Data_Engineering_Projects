CREATE SCHEMA staging;
GO

CREATE SCHEMA raw;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA quarantine;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = 'etl'
)
BEGIN
    EXEC('CREATE SCHEMA etl');
END;
GO
