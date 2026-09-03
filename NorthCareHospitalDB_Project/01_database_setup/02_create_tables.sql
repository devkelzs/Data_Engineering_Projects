--FOR silver Patients table

/*CREATE TABLE silver.Patients
(
    patient_id INT NOT NULL,

    first_name VARCHAR(50),
    last_name VARCHAR(50),
    gender VARCHAR(5),
    date_of_birth DATE,
    email VARCHAR(255),
    phone VARCHAR(50),
    city VARCHAR(250),
    blood_group VARCHAR(5),
    registration_date DATETIME2(0),
    notes VARCHAR(250),

    is_valid_email BIT NOT NULL,
    is_missing_email BIT NOT NULL,

    is_valid_phone BIT NOT NULL,
    is_missing_phone BIT NOT NULL,

    is_valid_birthdate BIT NOT NULL,
    is_missing_birthdate BIT NOT NULL,

    is_valid_gender BIT NOT NULL,
    is_missing_gender BIT NOT NULL,

    is_complete_record BIT NOT NULL,
    is_duplicate_candidate BIT NOT NULL,

    record_quality_score DECIMAL(5,2),

    data_quality_issue VARCHAR(500),

    load_timestamp DATETIME2(0) NOT NULL,
    last_updated_timestamp DATETIME2(0) NOT NULL,

    record_hash VARBINARY(32)
);
*/

-- For quarantine patients table
/*
CREATE TABLE quarantine.Patients
(
    quarantine_id INT IDENTITY(1,1) PRIMARY KEY,

    patient_id_raw VARCHAR(50),

    first_name VARCHAR(50),
    last_name VARCHAR(50),
    gender VARCHAR(50),

    date_of_birth VARCHAR(50),

    email VARCHAR(255),
    phone VARCHAR(50),

    city VARCHAR(250),
    blood_group VARCHAR(50),

    registration_date VARCHAR(50),

    quarantine_reason VARCHAR(500),

    quarantine_timestamp DATETIME2
);
*/

--- For staging patient tables 
/*
CREATE TABLE staging.Patients
(
    patient_id_raw VARCHAR(50),
    patient_id INT,

    first_name VARCHAR(50),
    last_name VARCHAR(50),
    gender VARCHAR(5),
    date_of_birth DATE,
    email VARCHAR(255),
    phone VARCHAR(50),
    city VARCHAR(250),
    blood_group VARCHAR(5),
    registration_date DATETIME2(0),
    notes VARCHAR(250),

    is_valid_email BIT NOT NULL,
    is_missing_email BIT NOT NULL,

    is_valid_phone BIT NOT NULL,
    is_missing_phone BIT NOT NULL,

    is_valid_birthdate BIT NOT NULL,
    is_missing_birthdate BIT NOT NULL,

    is_valid_gender BIT NOT NULL,
    is_missing_gender BIT NOT NULL,

    is_complete_record BIT NOT NULL,
    is_duplicate_candidate BIT NOT NULL,

    record_quality_score DECIMAL(5,2),

    data_quality_issue VARCHAR(500),

    passes_final_validation BIT NOT NULL,

    quarantine_reason VARCHAR(500),

    load_timestamp DATETIME2(0) NOT NULL,
    last_updated_timestamp DATETIME2(0) NOT NULL,

    record_hash VARBINARY(32),

    record_status VARCHAR(20)
);
*/