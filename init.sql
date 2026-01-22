-- Initialize PostgreSQL database for EHES Dashboard
-- This script runs automatically when the database container starts

-- Create database if it doesn't exist
-- (Handled by POSTGRES_DB environment variable)

-- Create tables for the application
CREATE TABLE IF NOT EXISTS test_results (
    id SERIAL PRIMARY KEY,
    client_id TEXT,
    project_id INTEGER,
    test_id TEXT,
    description TEXT,
    request_body JSONB,
    response JSONB,
    expected_results JSONB,
    status_code INTEGER,
    result TEXT,
    assertion_result TEXT,
    taking_time_seconds REAL,
    requestid_response JSONB,
    requestid_assertions JSONB,
    e2e_results TEXT,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (client_id, project_id, test_id)
);

-- Create metadata table for file uploads
CREATE TABLE IF NOT EXISTS upload_metadata (
    id SERIAL PRIMARY KEY,
    client_id TEXT,
    project_id INTEGER,
    username TEXT,
    uploaded_file_name TEXT,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_test_results_client_project ON test_results(client_id, project_id);
CREATE INDEX IF NOT EXISTS idx_test_results_status ON test_results(result);
CREATE INDEX IF NOT EXISTS idx_upload_metadata_client_project ON upload_metadata(client_id, project_id);

-- Grant permissions (adjust user as needed)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;
