CREATE DATABASE EL20;

use EL20


CREATE SCHEMA cal


CREATE TABLE cal.CalRun (
    run_id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_CalRun PRIMARY KEY,
    run_date DATE NOT NULL,
    started_at DATETIMEOFFSET(0) NOT NULL,
    finished_at DATETIMEOFFSET(0) NULL,
    status NVARCHAR(32) NOT NULL,              -- 'ok','error','partial'
    error_count INT NOT NULL CONSTRAINT DF_CalRun_error_count DEFAULT(0),

    total_events_processed INT NOT NULL CONSTRAINT DF_CalRun_total_events DEFAULT(0),
    total_hvacjson_events INT NOT NULL CONSTRAINT DF_CalRun_total_hvacjson DEFAULT(0),

    notes NVARCHAR(4000) NULL
);

CREATE INDEX IX_CalRun_run_date ON cal.CalRun(run_date);

go
CREATE TABLE cal.CalEvent (
    run_id UNIQUEIDENTIFIER NOT NULL,
    calendar_id NVARCHAR(256) NOT NULL,
    event_id NVARCHAR(512) NOT NULL,

    title NVARCHAR(512) NULL,
    start_dt DATETIMEOFFSET(0) NOT NULL,
    end_dt DATETIMEOFFSET(0) NOT NULL,
    description NVARCHAR(MAX) NULL,
    updated_dt DATETIMEOFFSET(0) NULL,

    CONSTRAINT PK_CalEvent PRIMARY KEY (run_id, calendar_id, event_id),
    CONSTRAINT FK_CalEvent_CalRun FOREIGN KEY (run_id)
        REFERENCES cal.CalRun(run_id)
);

CREATE INDEX IX_CalEvent_time ON cal.CalEvent(start_dt, end_dt);
CREATE INDEX IX_CalEvent_event_id ON cal.CalEvent(event_id);


go
-- Drop only if you're OK nuking the current table:
-- DROP TABLE IF EXISTS cal.HvacJsonBlock;
GO

--drop TABLE cal.HvacJsonBlock

CREATE TABLE cal.HvacJsonBlock
(
    block_id      BIGINT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_HvacJsonBlock PRIMARY KEY,

    run_id        UNIQUEIDENTIFIER NOT NULL,
    event_id      NVARCHAR(256)    NOT NULL,  -- increase if you want: 400
    block_name    NVARCHAR(32)     NOT NULL,  -- HVACJSON_0, HVACJSON_1, etc.

    block_hash BINARY(32) not null,

    raw_json      NVARCHAR(MAX) NOT NULL,
    parse_ok      BIT NOT NULL,
    parse_error   NVARCHAR(2000) NULL,

    created_at    DATETIME2(0) NOT NULL
        CONSTRAINT DF_HvacJsonBlock_created_at DEFAULT (SYSUTCDATETIME())
);
GO

ALTER TABLE cal.HvacJsonBlock DROP COLUMN block_hash;
GO
ALTER TABLE cal.HvacJsonBlock
ADD block_hash AS CONVERT(BINARY(32),
    HASHBYTES('SHA2_256',
        CONCAT(
            CONVERT(NVARCHAR(36), run_id), N'|',
            event_id, N'|',
            block_name
        )
    )
) PERSISTED;
GO

-- Ensure referential integrity / query performance:
CREATE INDEX IX_HvacJsonBlock_run_event ON cal.HvacJsonBlock(run_id, event_id);
CREATE INDEX IX_HvacJsonBlock_event ON cal.HvacJsonBlock(event_id);
CREATE UNIQUE INDEX UX_HvacJsonBlock_block_hash ON cal.HvacJsonBlock(block_hash);
GO




GO
CREATE TABLE cal.HvacJsonField (
    run_id UNIQUEIDENTIFIER NOT NULL,
    event_id NVARCHAR(64) NOT NULL,

    json_event NVARCHAR(512) NULL,
    json_location NVARCHAR(64) NULL,          -- HVACJSON location (reliable)
    json_type NVARCHAR(128) NULL,
    attending INT NULL,

    setpoint_name NVARCHAR(128) NULL,
    extra_json NVARCHAR(MAX) NULL,
    data_pointer NVARCHAR(512) NULL,            -- stored but NOT dereferenced

    CONSTRAINT PK_HvacJsonField PRIMARY KEY (run_id, event_id),
    CONSTRAINT FK_HvacJsonField_CalRun FOREIGN KEY (run_id)
        REFERENCES cal.CalRun(run_id)
);

CREATE INDEX IX_HvacJsonField_type ON cal.HvacJsonField(json_type);
CREATE INDEX IX_HvacJsonField_location ON cal.HvacJsonField(json_location);
CREATE INDEX IX_HvacJsonField_setpoint ON cal.HvacJsonField(setpoint_name);

GO
CREATE TABLE cal.HvacTrigger (
    trigger_id NVARCHAR(256) NOT NULL CONSTRAINT PK_HvacTrigger PRIMARY KEY,
    run_id UNIQUEIDENTIFIER NOT NULL,
    event_id NVARCHAR(512) NOT NULL,

    area NVARCHAR(128) NOT NULL,
    run_at DATETIMEOFFSET(0) NOT NULL,
    temp_f DECIMAL(5,2) NOT NULL,
    hold_until DATETIMEOFFSET(0) NOT NULL,

    enabled_default BIT NOT NULL CONSTRAINT DF_HvacTrigger_enabled DEFAULT(1),
    reason_json NVARCHAR(MAX) NULL,

    CONSTRAINT FK_HvacTrigger_CalRun FOREIGN KEY (run_id)
        REFERENCES cal.CalRun(run_id)
);

CREATE INDEX IX_HvacTrigger_time ON cal.HvacTrigger(run_at);
CREATE INDEX IX_HvacTrigger_area ON cal.HvacTrigger(area);

GO
CREATE TABLE cal.HvacTriggerOverride (
    trigger_id NVARCHAR(256) NOT NULL CONSTRAINT PK_HvacTriggerOverride PRIMARY KEY,

    enabled BIT NOT NULL,
    modified_run_at DATETIMEOFFSET(0) NULL,
    modified_temp_f DECIMAL(5,2) NULL,
    modified_hold_until DATETIMEOFFSET(0) NULL,

    notes NVARCHAR(1000) NULL,
    modified_at DATETIMEOFFSET(0) NOT NULL
        CONSTRAINT DF_HvacTriggerOverride_modified_at DEFAULT(SYSDATETIMEOFFSET())
);


GO
