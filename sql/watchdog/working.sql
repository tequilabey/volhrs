--create database watchdog
  drop TABLE ha_check
select * from HACheck

  CREATE TABLE HACheck (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    TsUtc datetime2(0) DEFAULT( SYSUTCDATETIME() ),
    NodeName NVARCHAR(46) NULL,
    HATailScaleIP VARCHAR(45) NULL,
    TailScaleOk Bit not null,
    TailScaleState NVARCHAR(45) NULL,
    PingOk Bit not null,
    SSHOk Bit not null,
    CurlOk Bit not null,
    CurlHttpCode INT Null,
    CurlTotalMs INT NULL,
    Details NVARCHAR(1024) NULL
  );
  CREATE INDEX IX_HACheck_TsUtc ON dbo.HACheck (TsUtc DESC);

  USE watchdog;
GO

SELECT s.name AS [schema], t.name AS [table]
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.name LIKE '%HACheck%' OR t.name LIKE '%hacheck%';
GO
truncate table HACheck

USE watchdog;
GO
SELECT COUNT(*) AS cnt FROM dbo.HACheck;
GO




USE watchdog;
GO

IF COL_LENGTH('dbo.HACheck', 'TargetName') IS NULL
BEGIN
  ALTER TABLE dbo.HACheck ADD TargetName NVARCHAR(32) NULL;
END

IF COL_LENGTH('dbo.HACheck', 'PortOk') IS NULL
BEGIN
  ALTER TABLE dbo.HACheck ADD PortOk BIT NULL;
END

IF COL_LENGTH('dbo.HACheck', 'PortNumber') IS NULL
BEGIN
  ALTER TABLE dbo.HACheck ADD PortNumber INT NULL;
END
GO

-- Mark existing rows as HA (optional)
UPDATE dbo.HACheck
SET TargetName = ISNULL(TargetName, N'ha')
WHERE TargetName IS NULL;
GO

-- Helpful index
IF NOT EXISTS (
  SELECT 1 FROM sys.indexes WHERE name = 'IX_HACheck_Target_TsUtc' AND object_id = OBJECT_ID('dbo.HACheck')
)
BEGIN
  CREATE INDEX IX_HACheck_Target_TsUtc ON dbo.HACheck (TargetName, TsUtc DESC);
END
GO


SELECT TOP 10 TsUtc, TargetName, PingOk, SSHOk, CurlOk, PortOk FROM dbo.HACheck ORDER BY Id DESC;