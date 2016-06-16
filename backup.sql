declare @todays nvarchar(50)
set @todays=(cast('D:\ICE-DataBase\ICE-DB-Backup\ipd_' as nvarchar(50)) + CONVERT(nvarchar, getdate(), 112 ) + cast('.bak' as nvarchar))


Backup database Ice_Project_Directory
TO DISK = @todays
   WITH FORMAT,
      MEDIANAME = 'd_backup_ice_project_directory',
      NAME = 'Full Backup of Ice Project Directory';

 