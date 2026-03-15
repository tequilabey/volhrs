*** in micro-s-2 ***

CREATE DATABASE VolHrs;
GO
USE VolHrs;
GO
IF not EXISTS (SELECT * FROM sys.schemas WHERE name = N'vh')
  exec( 'CREATE SCHEMA vh' ); -- AUTHORIZATION sa' );

IF OBJECT_ID ('vh.users', 'U') IS NOT NULL BEGIN
  exec vh.DelConstraints 'users'
	drop table vh.[users]
END
CREATE TABLE vh.[Users](
  UserId       INT IDENTITY(1,1) PRIMARY KEY,
  LoginName   VARCHAR(50) not null,
  PasswordHash   NVARCHAR(256) not NULL,
  FirstName    NVARCHAR(80) NOT NULL,
  LastName     NVARCHAR(80) NOT NULL,
  Mobile       NVARCHAR(20) NULL,
  Email        NVARCHAR(256) NULL,
  CreatedAt    DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE UNIQUE INDEX UX_Users_LoginName ON vh.Users(LoginName);

IF OBJECT_ID ('vh.Projects', 'U') IS NOT NULL BEGIN
  exec vh.DelConstraints 'Projects'
  alter table vh.TimeEntries drop constraint FK_TimeEntries_Projects;
	drop table vh.[Projects]
  truncate table vh.Projects
END
-- Projects
IF OBJECT_ID('vh.Projects','U') IS NULL
BEGIN
    CREATE TABLE vh.Projects(
      ProjectId   INT IDENTITY(1,1) PRIMARY KEY,
      Name        NVARCHAR(160) NOT NULL,
      IsPublic    BIT NOT NULL DEFAULT 1,
      CreatedAt   DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );

    CREATE UNIQUE INDEX UX_Projects_Name ON vh.Projects(Name);
END
GO

IF OBJECT_ID ('vh.TimeEntries', 'U') IS NOT NULL BEGIN
  exec vh.DelConstraints 'TimeEnTimeEntriestry'
	drop table vh.TimeEntries
END
-- TimeEntries
IF OBJECT_ID('vh.TimeEntries','U') IS NULL
BEGIN
    CREATE TABLE vh.TimeEntries(
      TimeEntryId BIGINT IDENTITY(1,1) PRIMARY KEY,
      UserId      INT NOT NULL
        CONSTRAINT FK_TimeEntries_Users
        FOREIGN KEY REFERENCES vh.Users(UserId),
      ProjectId   INT NOT NULL
        CONSTRAINT FK_TimeEntries_Projects
        FOREIGN KEY REFERENCES vh.Projects(ProjectId),
      EntryDate   DATE NOT NULL,
      Minutes     INT NOT NULL CHECK (Minutes > 0),
      Notes       NVARCHAR(2000) NULL,
      CreatedAt   DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );

    CREATE INDEX IX_TimeEntries_UserDate ON vh.TimeEntries(UserId, EntryDate DESC);
    CREATE INDEX IX_TimeEntries_ProjectDate ON vh.TimeEntries(ProjectId, EntryDate DESC);
END
GO
-- seed a couple rows so the UI has something to show
INSERT vh.[Users](FirstName, LastName, LoginName, passwordhash, Mobile, Email) VALUES ('Russ', 'Humphrey', 'russ', 'bronco', '206 399 0996', 'russ@doublejoy.com.com');
INSERT vh.Projects([Name], IsPublic) VALUES ('Volunteer Hours IT', 1), ('Membership IT', 1), ('Calendar IT', 1);

delete from vh.Projects
  SELECT *
  FROM vh.Projects AS p order by projectid

 update vh.projects set projectID = projectID-12

DBCC CHECKIDENT ('vh.Projects', RESEED, New_Next_Value 1) ;

INSERT vh.Projects([Name], IsPublic) VALUES
('Ladies Room', 1 ),('Reading Room', 1 ),('Dev Automation', 1 ),
('Dev Volunteer Hours', 1 ),('Dev Membership', 1 ),('Dev Calendar', 1 ),
('BC: Building Commttee', 1 ),('BC: Rentals Sub-Cmte', 1 ),('BC: Calendar Sub-Cmte', 1 )

select * from vh.Projects
delete from vh.project where projectID > 3

SELECT TOP 10 * FROM vh.Users ORDER BY UserId;
SELECT TOP 10 * FROM vh.Projects ORDER BY ProjectId;



truncate table vh.Projects
truncate table vh.Projects


ALTER TABLE vh.TimeEntries
ADD CONSTRAINT DF_TimeEntries_EntryDate
DEFAULT (CONVERT(date, SYSUTCDATETIME())) FOR EntryDate;


CREATE TABLE vh.Sessions(
  SessionId     BIGINT IDENTITY(1,1) PRIMARY KEY,
  UserId        INT NOT NULL FOREIGN KEY REFERENCES vh.Users(UserId),
  TokenHash     VARBINARY(32) NOT NULL, -- SHA-256
  ExpiresAtUtc  DATETIME2 NOT NULL,
  CreatedAtUtc  DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  LastSeenAtUtc DATETIME2 NULL
);

CREATE UNIQUE INDEX UX_Sessions_TokenHash ON vh.Sessions(TokenHash);
CREATE INDEX IX_Sessions_UserId ON vh.Sessions(UserId);
GO


update vh.Users set passwordhash = '$2b$12$pjqXuU19RagrgMbGbDUsmeBriVsDUD.DQJqTgU6k3zQDYrGydub6.',
    lastName = 'Humphrey' where userID = 1

select * from vh.Users



IF OBJECT_ID('vh.Roles','U') IS NULL
BEGIN
  CREATE TABLE vh.Roles(
    RoleId       BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserId       INT NOT NULL
      CONSTRAINT FK_Roles_Users FOREIGN KEY REFERENCES vh.Users(UserId),
    RoleCode     VARCHAR(30) NOT NULL,
    GrantedDate  DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    RevokedDate  DATETIME2 NULL
  );

  CREATE INDEX IX_Roles_UserId ON vh.Roles(UserId);
  CREATE INDEX IX_Roles_RoleCode ON vh.Roles(RoleCode);
  CREATE INDEX IX_Roles_Active ON vh.Roles(UserId, RoleCode, RevokedDate);
END
GO


INSERT vh.[Roles](userID, roleCode ) VALUES ( 1, 'admin' ) 
select * from vh.Users.
INSERT into vh.[Roles](userID, roleCode ) select userID, 'volhrs' from vh.users


SELECT TOP 10 * FROM vh.Projects ORDER BY ProjectId;
insert into vh.Projects( name, isPublic ) values ( 'Ladies Room',1 )
insert into vh.Projects( name, isPublic ) values ( 'Reading Room',1 )
insert into vh.Projects( name, isPublic ) values ( 'Dev Automation',1 )
insert into vh.Projects( name, isPublic ) values ( 'Dev Volunteer Hours',1 )
insert into vh.Projects( name, isPublic ) values ( 'Dev Membership',1 )
insert into vh.Projects( name, isPublic ) values ( 'Dev Calendar',1 )
insert into vh.Projects( name, isPublic ) values ( 'BC: Building Commttee',1 )
insert into vh.Projects( name, isPublic ) values ( 'BC: Rentals Sub-Cmte',1 )
insert into vh.Projects( name, isPublic ) values ( 'BC: Calendar Sub-Cmte',1 )
SELECT * FROM vh.Projects ORDER BY ProjectId;

SELECT * FROM vh.Roles
insert into vh.Roles( userID, roleCode ) values ( 1, 'admin' )


SELECT TOP 10 * FROM vh.Sessions
SELECT TOP 10 * FROM vh.timeEntries
INSERT INTO VH.TIMEENTRIES( userID, projectID, entryDate, minutes, notes, createdAt ) values( 1, 1,'2026-01-25',30,'worked on bench & big window','2026-01-25 00:13:59.79871' )
INSERT INTO VH.TIMEENTRIES( userID, projectID, entryDate, minutes, notes, createdAt ) values( 1, 4,'2026-01-25',120,'Nearly done','2026-01-25 01:50:08.61256' )
INSERT INTO VH.TIMEENTRIES( userID, projectID, entryDate, minutes, notes, createdAt ) values( 1, 3,'2026-01-25',120,'Dealing w/ incorrect furnace firing.  Will add a dedicated SQL server','2026-01-25 01:51:29.45504' )
INSERT INTO VH.TIMEENTRIES( userID, projectID, entryDate, minutes, notes, createdAt ) values( 1, 4,'2026-01-26',240,'Wrapping up VH, adding Admin stuff now','2026-01-26 02:49:13.01460' )
INSERT INTO VH.TIMEENTRIES( userID, projectID, entryDate, minutes, notes, createdAt ) values( 1, 4,'2026-01-26',120,'Still wrapping up details.  Needing a ''forgot password'' page','2026-01-26 03:25:30.49388' )

SELECT TOP 10 * FROM vh.Projects ORDER BY ProjectId;
SELECT TOP 10 * FROM vh.Roles ORDER BY UserId;
SELECT TOP 10 * FROM vh.Sessions
SELECT TOP 10 * FROM vh.timeEntries
SELECT TOP 10 * FROM vh.Users