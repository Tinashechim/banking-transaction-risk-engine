CREATE SCHEMA IF NOT EXISTS banking;

CREATE TABLE banking.customers (
    customer_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO banking.customers
(first_name, last_name, email, phone)
VALUES
('John', 'Smith', 'john.smith@example.com', '0712345678');



