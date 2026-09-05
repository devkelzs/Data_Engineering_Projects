INSERT INTO raw.Patients
(
    patient_id,
    first_name,
    last_name,
    gender,
    date_of_birth,
    registration_date,
    notes,
    email,
    phone,
    city,
    blood_group
)
VALUES
(
    '25001',
    'Test',
    'Patient',
    'M',
    '1995-06-15',
    '2026-09-03 10:00:00',
    'Incremental load test',
    'test.patient25001@gmail.com',
    '+237 677123456',
    'Yaounde',
    'O+'
);



UPDATE raw.Patients
SET city = 'Douala'
WHERE patient_id = '25001';


INSERT INTO raw.Patients
(
    patient_id,
    first_name,
    last_name,
    gender,
    date_of_birth,
    registration_date,
    notes,
    email,
    phone,
    city,
    blood_group
)
VALUES
(
    'INVALID_TEST_2',
    'Jane',
    'Quarantine',
    'F',
    '1992-04-10',
    '2026-09-04 15:30:00',
    'Quarantine test 2',
    'jane.test@mail.com',
    '+237690000000',
    'Yaounde',
    'A+'
);