sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
sp_configure 'clr enabled', 1;
GO
RECONFIGURE;
GO

ALTER DATABASE Ice_Project_Directory SET TRUSTWORTHY ON
GO


USE Ice_Project_Directory 

Drop Procedure RecordEntry
GO
DROP ASSEMBLY RecordAttendance
GO
CREATE ASSEMBLY RecordAttendance
AUTHORIZATION dbo
FROM 'D:\Assemblies\RecordAttendance.dll'
WITH PERMISSION_SET = UNSAFE
GO

CREATE PROCEDURE RecordEntry
	@eid int,
	@tid int,
	@date DateTime,
	@time DateTime 
AS EXTERNAL NAME RecordAttendance.[RecordAttendance.FingerPrintEntryRecorder].RecordEntry
GO

