CREATE OR ALTER PROCEDURE vh.DelConstraints
    @t varchar(20) 
AS BEGIN

  declare @cmd varchar(255)

  while (select count(*) from INFORMATION_SCHEMA.KEY_COLUMN_USAGE where TABLE_NAME = @t AND TABLE_SCHEMA = 'vh') > 0 BEGIN
    SELECT top 1 @cmd = 'alter table vh.' + @t + ' drop constraint ' + CONSTRAINT_NAME
    FROM  INFORMATION_SCHEMA.KEY_COLUMN_USAGE
    WHERE TABLE_NAME = @t AND TABLE_SCHEMA = 'vh'
	print @cmd;
    exec (@cmd);
  end

END

/*
alter table vh.users drop constraint PK__Users__1788CC4CFA0057D4

select * from INFORMATION_SCHEMA.KEY_COLUMN_USAGE where TABLE_SCHEMA = 'vh'
select * from INFORMATION_SCHEMA.KEY_COLUMN_USAGE where TABLE_NAME = 'users' AND TABLE_SCHEMA = 'vh'
select * from INFORMATION_SCHEMA.KEY_COLUMN_USAGE where TABLE_NAME = 'timeentry' AND TABLE_SCHEMA = 'vh'

vh.DelConstraints 'project'

alter table vh.timeentry drop constraint FK__TimeEntry__UserI__6DF800E3
FK__TimeEntry__UserI__6DF800E3
PK__TimeEntr__36FCE7C95BF02E02

  select count(*) from INFORMATION_SCHEMA.KEY_COLUMN_USAGE where TABLE_NAME = 'timeentry' AND TABLE_SCHEMA = 'vh'
  select * from INFORMATION_SCHEMA.KEY_COLUMN_USAGE where TABLE_NAME = 'timeentry' AND TABLE_SCHEMA = 'vh'


*/