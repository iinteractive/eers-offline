
CREATE TABLE tbl_report_requests (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,

    -- User information
    user_id    INTEGER  NOT NULL, -- user who owns the report
    session_id CHAR(32) NOT NULL, -- session where the request was initiated    
    
    -- Report information
    report_format VARCHAR(20) NOT NULL, -- the output format (PDF, Excel, etc)
    report_type   VARCHAR(20) NOT NULL, -- the "type" of report (could be anything, future-proofin++)      
    report_spec   TEXT        NOT NULL, -- JSON structure of the demographics, etc    
    
    -- Date/Timestamp
    request_submitted DATETIME, -- timestamp of when the report was initially requested
    job_submitted     DATETIME, -- timestamp of when the request was picked up by the gen servers
    job_completed     DATETIME, -- timestamp of when the request has been fufilled
    
    -- Status info
    status VARCHAR(20), -- {submitted, pending, completed, error, deleted, n/a}               
    
    -- Misc.
    additional_metadata TEXT, -- misc crap which might be applicable
    
    -- Results
    -- NOTE: results are returned as "attachments"
    attachment_type VARCHAR(255), -- type of attachment sent back (uri, gif, pdf, error message, etc.)        
    attachment_body TEXT          -- the attachment payload
);

