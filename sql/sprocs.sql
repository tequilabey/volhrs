CREATE OR ALTER PROCEDURE vh.Projects_GetPublic
AS
BEGIN
  SET NOCOUNT ON;

  SELECT ProjectId, Name
  FROM vh.Projects
  WHERE IsPublic = 1
  ORDER BY Name;
END
GO


CREATE OR ALTER PROCEDURE vh.TimeEntries_Insert
  @UserId    INT,
  @ProjectId INT,
  @Minutes   INT,
  @Notes     NVARCHAR(2000) = NULL,
  @TimeEntryId BIGINT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  INSERT vh.TimeEntries(UserId, ProjectId, EntryDate, Minutes, Notes)
  VALUES (@UserId, @ProjectId, DEFAULT, @Minutes, @Notes);

  SET @TimeEntryId = SCOPE_IDENTITY();
END
GO


CREATE OR ALTER PROCEDURE vh.TimeEntries_GetByUser
  @UserId INT
AS
BEGIN
  SET NOCOUNT ON;

  SELECT TOP 200
    te.TimeEntryId,
    te.EntryDate,
    te.Minutes,
    te.Notes,
    p.Name AS ProjectName
  FROM vh.TimeEntries te
  JOIN vh.Projects p ON p.ProjectId = te.ProjectId
  WHERE te.UserId = @UserId
  ORDER BY te.EntryDate DESC, te.TimeEntryId DESC;

  SELECT SUM(Minutes) AS TotalMinutes
  FROM vh.TimeEntries
  WHERE UserId = @UserId;
END
GO


CREATE OR ALTER PROCEDURE vh.Projects_GetSummaryPublic
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    p.ProjectId,
    p.Name,
    SUM(te.Minutes) AS TotalMinutes,
    MAX(te.EntryDate) AS LastActivityDate
  FROM vh.Projects p
  LEFT JOIN vh.TimeEntries te ON te.ProjectId = p.ProjectId
  WHERE p.IsPublic = 1
  GROUP BY p.ProjectId, p.Name
  ORDER BY p.Name;

  SELECT TOP 20
    te.EntryDate,
    te.Minutes,
    p.Name AS ProjectName
  FROM vh.TimeEntries te
  JOIN vh.Projects p ON p.ProjectId = te.ProjectId
  WHERE p.IsPublic = 1
  ORDER BY te.EntryDate DESC, te.TimeEntryId DESC;
END
GO


CREATE OR ALTER PROCEDURE vh.Projects_GetPublicDetail
  @ProjectId INT
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    p.ProjectId,
    p.Name,
    p.IsPublic,
    SUM(te.Minutes) AS TotalMinutes,
    MAX(te.EntryDate) AS LastActivityDate
  FROM vh.Projects p
  LEFT JOIN vh.TimeEntries te ON te.ProjectId = p.ProjectId
  WHERE p.ProjectId = @ProjectId
  GROUP BY p.ProjectId, p.Name, p.IsPublic;

  SELECT TOP 50
    te.EntryDate,
    te.Minutes,
    te.Notes
  FROM vh.TimeEntries te
  WHERE te.ProjectId = @ProjectId
  ORDER BY te.EntryDate DESC, te.TimeEntryId DESC;
END
GO


CREATE OR ALTER PROCEDURE vh.Users_Create
  @LoginName    VARCHAR(50),
  @PasswordHash NVARCHAR(256),
  @FirstName    NVARCHAR(80),
  @LastName     NVARCHAR(80),
  @Mobile       NVARCHAR(20) = NULL,
  @Email        NVARCHAR(256) = NULL,
  @UserId       INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  -- basic guardrails
  IF (LEN(LTRIM(RTRIM(@LoginName))) = 0) THROW 50001, 'LoginName required', 1;
  IF (LEN(LTRIM(RTRIM(@PasswordHash))) = 0) THROW 50002, 'PasswordHash required', 1;
  IF (LEN(LTRIM(RTRIM(@FirstName))) = 0) THROW 50003, 'FirstName required', 1;
  IF (LEN(LTRIM(RTRIM(@LastName))) = 0) THROW 50004, 'LastName required', 1;

  -- uniqueness
  IF EXISTS (SELECT 1 FROM vh.Users WHERE LoginName = @LoginName)
    THROW 50005, 'LoginName already exists', 1;

  INSERT vh.Users (LoginName, PasswordHash, FirstName, LastName, Mobile, Email)
  VALUES (@LoginName, @PasswordHash, @FirstName, @LastName, @Mobile, @Email);

  SET @UserId = SCOPE_IDENTITY();
END
GO


CREATE OR ALTER PROCEDURE vh.Users_GetByLoginName
  @LoginName VARCHAR(50)
AS
BEGIN
  SET NOCOUNT ON;

  SELECT TOP 1
    UserId,
    LoginName,
    PasswordHash,
    FirstName,
    LastName,
    Email,
    Mobile
  FROM vh.Users
  WHERE LoginName = @LoginName;
END
GO


CREATE OR ALTER PROCEDURE vh.Sessions_Create
  @UserId INT,
  @TokenHash VARBINARY(32),
  @ExpiresAtUtc DATETIME2
AS
BEGIN
  SET NOCOUNT ON;

  INSERT vh.Sessions(UserId, TokenHash, ExpiresAtUtc, LastSeenAtUtc)
  VALUES (@UserId, @TokenHash, @ExpiresAtUtc, SYSUTCDATETIME());
END
GO


CREATE OR ALTER PROCEDURE vh.Sessions_GetUserByTokenHash
  @TokenHash VARBINARY(32)
AS
BEGIN
  SET NOCOUNT ON;

  SELECT TOP 1
    s.SessionId,
    s.UserId,
    s.ExpiresAtUtc,
    u.LoginName,
    u.FirstName,
    u.LastName
  FROM vh.Sessions s
  JOIN vh.Users u ON u.UserId = s.UserId
  WHERE s.TokenHash = @TokenHash
    AND s.ExpiresAtUtc > SYSUTCDATETIME();
END
GO


CREATE OR ALTER PROCEDURE vh.Sessions_Touch
  @SessionId BIGINT,
  @NewExpiresAtUtc DATETIME2
AS
BEGIN
  SET NOCOUNT ON;

  UPDATE vh.Sessions
  SET ExpiresAtUtc = @NewExpiresAtUtc,
      LastSeenAtUtc = SYSUTCDATETIME()
  WHERE SessionId = @SessionId;
END
GO


CREATE OR ALTER PROCEDURE vh.Sessions_Delete
  @TokenHash VARBINARY(32)
AS
BEGIN
  SET NOCOUNT ON;

  DELETE vh.Sessions WHERE TokenHash = @TokenHash;
END
GO


CREATE OR ALTER PROCEDURE vh.Roles_GetActiveByUserId
  @UserId INT
AS
BEGIN
  SET NOCOUNT ON;

  SELECT RoleCode
  FROM vh.Roles
  WHERE UserId = @UserId
    AND RevokedDate IS NULL
    AND GrantedDate <= SYSUTCDATETIME()
  ORDER BY RoleCode;
END
GO


CREATE OR ALTER PROCEDURE vh.Projects_ListAll
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    p.ProjectId,
    p.Name,
    p.IsPublic
  FROM vh.Projects AS p
  ORDER BY p.Name;
END
GO


CREATE OR ALTER PROCEDURE vh.Projects_Upsert
  @ProjectId INT = NULL,
  @Name NVARCHAR(200),
  @IsPublic BIT
AS
BEGIN
  SET NOCOUNT ON;

  IF (LEN(LTRIM(RTRIM(@Name))) = 0)
    THROW 50101, 'Project name is required', 1;

  IF @ProjectId IS NULL OR @ProjectId = 0
  BEGIN
    INSERT vh.Projects(Name, IsPublic)
    VALUES (@Name, @IsPublic);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS ProjectId;
    RETURN;
  END

  UPDATE vh.Projects
  SET Name = @Name,
      IsPublic = @IsPublic
  WHERE ProjectId = @ProjectId;

  SELECT @ProjectId AS ProjectId;
END
GO


CREATE OR ALTER PROCEDURE vh.Projects_Delete
  @ProjectId INT
AS
BEGIN
  SET NOCOUNT ON;

  DELETE vh.Projects WHERE ProjectId = @ProjectId;
END
GO


CREATE OR ALTER PROCEDURE vh.Users_ListAll
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    u.UserId,
    u.LoginName,
    u.FirstName,
    u.LastName,
    u.Email,
    u.Mobile,
    u.CreatedAt
  FROM vh.Users u
  ORDER BY u.LastName, u.FirstName, u.LoginName;

  SELECT
    r.UserId,
    r.RoleCode,
    r.GrantedDate
  FROM vh.Roles r
  WHERE r.RevokedDate IS NULL
  ORDER BY r.UserId, r.RoleCode;
END
GO


CREATE OR ALTER PROCEDURE vh.Users_Upsert
  @UserId     INT = NULL,
  @LoginName  VARCHAR(50),
  @FirstName  NVARCHAR(80),
  @LastName   NVARCHAR(80),
  @Email      NVARCHAR(256) = NULL,
  @Mobile     NVARCHAR(20) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  SET @LoginName = LTRIM(RTRIM(@LoginName));
  SET @FirstName = LTRIM(RTRIM(@FirstName));
  SET @LastName  = LTRIM(RTRIM(@LastName));

  IF (LEN(@LoginName)=0) THROW 51001, 'LoginName required', 1;
  IF (LEN(@FirstName)=0) THROW 51002, 'FirstName required', 1;
  IF (LEN(@LastName)=0)  THROW 51003, 'LastName required', 1;

  IF (@UserId IS NULL OR @UserId = 0)
  BEGIN
    IF EXISTS (SELECT 1 FROM vh.Users WHERE LoginName = @LoginName)
      THROW 51004, 'LoginName already exists', 1;

    INSERT vh.Users(LoginName, PasswordHash, FirstName, LastName, Email, Mobile)
    VALUES (@LoginName, N'__TEMP__', @FirstName, @LastName, NULLIF(@Email,''), NULLIF(@Mobile,''));

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS UserId;
    RETURN;
  END

  IF EXISTS (SELECT 1 FROM vh.Users WHERE LoginName=@LoginName AND UserId<>@UserId)
    THROW 51005, 'LoginName already exists', 1;

  UPDATE vh.Users
  SET LoginName = @LoginName,
      FirstName = @FirstName,
      LastName  = @LastName,
      Email     = NULLIF(@Email,''),
      Mobile    = NULLIF(@Mobile,'')
  WHERE UserId = @UserId;

  SELECT @UserId AS UserId;
END
GO


CREATE OR ALTER PROCEDURE vh.Users_SetPasswordHash
  @UserId INT,
  @PasswordHash NVARCHAR(256)
AS
BEGIN
  SET NOCOUNT ON;

  IF (LEN(LTRIM(RTRIM(@PasswordHash))) = 0)
    THROW 51010, 'PasswordHash required', 1;

  UPDATE vh.Users
  SET PasswordHash = @PasswordHash
  WHERE UserId = @UserId;
END
GO


CREATE OR ALTER PROCEDURE vh.Roles_Grant
  @UserId INT,
  @RoleCode VARCHAR(30)
AS
BEGIN
  SET NOCOUNT ON;

  SET @RoleCode = LOWER(LTRIM(RTRIM(@RoleCode)));
  IF (LEN(@RoleCode)=0) THROW 51020, 'RoleCode required', 1;

  IF EXISTS (
    SELECT 1 FROM vh.Roles
    WHERE UserId=@UserId AND RoleCode=@RoleCode AND RevokedDate IS NULL
  )
    RETURN;

  INSERT vh.Roles(UserId, RoleCode, GrantedDate, RevokedDate)
  VALUES (@UserId, @RoleCode, SYSUTCDATETIME(), NULL);
END
GO


CREATE OR ALTER PROCEDURE vh.Roles_Revoke
  @UserId INT,
  @RoleCode VARCHAR(30)
AS
BEGIN
  SET NOCOUNT ON;

  SET @RoleCode = LOWER(LTRIM(RTRIM(@RoleCode)));
  UPDATE vh.Roles
  SET RevokedDate = SYSUTCDATETIME()
  WHERE UserId=@UserId AND RoleCode=@RoleCode AND RevokedDate IS NULL;
END
GO


CREATE OR ALTER PROCEDURE vh.Users_Delete
  @UserId INT
AS
BEGIN
  SET NOCOUNT ON;

  -- revoke roles first (optional hygiene)
  UPDATE vh.Roles SET RevokedDate = SYSUTCDATETIME()
  WHERE UserId=@UserId AND RevokedDate IS NULL;

  DELETE vh.Users WHERE UserId=@UserId;
END
GO
