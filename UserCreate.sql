Create login ICEDbReader with password='gibberish';
Create user ICEDbReader for login ICEDbReader;
Grant Execute to ICEDbReader;
exec sp_addrolemember 'db_datareader', ICEDbReader



select * from master..syslogins