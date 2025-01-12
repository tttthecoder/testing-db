-- Create the employees table
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    salary DECIMAL(10, 2) NOT NULL,
    department VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create a unique index to constrain uniqueness by first_name, department, email, and salary
CREATE UNIQUE INDEX employees_unique_idx ON employees (first_name, department, email, salary);
