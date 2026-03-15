*********  home mac ******

EXEC master.dbo.sp_addlinkedserver 
    @server = N'micros2', -- A logical name for your linked server
    @srvproduct = N'',                  -- An empty string is fine for SQL Server connections
    @provider = N'MSOLEDBSQL',          -- Microsoft OLE DB Driver for SQL Server
    @datasrc = N'100.107.208.9';       -- The remote server's IP address (or 'IP_address,port_number' for non-default ports)
GO

EXEC master.dbo.sp_addlinkedsrvlogin 
    @rmtsrvname = N'micros2', -- The logical name defined above
    @locallogin = NULL,                     -- NULL means the mapping applies to all local logins
    @useself = N'False',                    -- Do not use current login's security context
    @rmtuser = N'sa',               -- Username on the remote SQL Server
    @rmtpassword = N'Slith^T0ves#';       -- Password for the remote user
GO


drop view if exists [vh.UserProjectsV]
go
create proc vh.UserProjectsV
as
BEGIN

  select  top 3 srt = 'A', te.userID, te.projectID, nbr = count(*),
        dateSpan = datediff( d, max(te.EntryDate), min(te.EntryDate)), newest = max(te.EntryDate)
	into #a
    from vh.TimeEntry te
    group by te.userID, te.projectID
    order by NBR

  select * from #a
    UNION
   select  srt = 'B', te.userID, te.projectID, nbr = count(*),
        dateSpan = datediff( d, max(te.EntryDate), min(te.EntryDate)), newest = max(te.EntryDate)
    from vh.TimeEntry te
    where projectID not in ( select distinct projectID from #a )
      group by te.userID, te.projectID


/*

IF EXISTS (
	SELECT * FROM sys.objects WHERE name = 'UserProjects' and schema_id = SCHEMA_ID( 'vh' );
	SELECT * FROM sys.views WHERE name = 'UserProjects' --and schema_id = SCHEMA_ID( 'vh' )
	 ) type = 'P' AND 
drop view [vh.UserProjects];

*/

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

select * from vh.users


SELECT TOP 10 * FROM vh.Projects ORDER BY ProjectId;
SELECT TOP 10 * FROM vh.Roles ORDER BY UserId;
SELECT TOP 10 * FROM vh.Sessions
SELECT TOP 10 * FROM vh.timeEntries

SELECT 'insert into vh.Projects( '''+ name +''','+rtrim(cast( IsPublic as char)) +' )' FROM vh.Projects ORDER BY ProjectId
insert into vh.Projects( name, isPublic ) values ( 'Ladies Room',1 )
insert into vh.Projects( name, isPublic ) values ( 'Reading Room',1 )
insert into vh.Projects( name, isPublic ) values ( 'Dev Automation',1 )
insert into vh.Projects( name, isPublic ) values ( 'Dev Volunteer Hours',1 )
insert into vh.Projects( name, isPublic ) values ( 'Dev Membership',1 )
insert into vh.Projects( name, isPublic ) values ( 'Dev Calendar',1 )
insert into vh.Projects( name, isPublic ) values ( 'BC: Building Commttee',1 )
insert into vh.Projects( name, isPublic ) values ( 'BC: Rentals Sub-Cmte',1 )
insert into vh.Projects( name, isPublic ) values ( 'BC: Calendar Sub-Cmte',1 )



SELECT 'insert into vh.Projects( '''+ name +''','+rtrim(cast( IsPublic as char)) +' )' FROM vh.Projects ORDER BY ProjectId

insert into vh.Roles( userID, ( 1, 'admin' )

select * from vh.TimeEntries
insert into vh.timeEntries( userID, projectID, entryDate, minutes, notes, createdAt

SELECT 'INSERT INTO VH.TIMEENTRIES( userID, projectID, entryDate, minutes, notes, createdAt ) values( ' + rtrim( convert( char, userID)) + ', '+ rtrim( convert( char, projectID))+','
    + '''' + convert( nvarchar(10), entryDate)+'''' + ',' +rtrim(convert( nvarchar(4), minutes )) +',''' + notes +''',''' + convert( varchar(25), createdAt ) + ''''
  FROM vh.TimeEntries order by timeentryid


  FROM VH.TIMEENTRY
  