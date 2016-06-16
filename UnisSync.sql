USE Ice_Project_Directory

IF  NOT EXISTS (
	SELECT * FROM sys.objects 
	WHERE object_id = OBJECT_ID(N'dbo.UNISEntries') AND type in (N'U')
)
BEGIN
CREATE TABLE dbo.UNISEntries (
    C_Date char(8),
    C_Time char(6),
	L_TID int,
	L_UID int
) 
END


DECLARE @lastdate char(8)
DECLARE @lasttime char(8)

IF (SELECT Count(*) FROM dbo.UNISEntries ) != 0
BEGIN 
	SELECT TOP(1) @lastdate=C_Date, @lasttime=C_Time
	FROM dbo.UNISEntries 
	ORDER BY C_Date DESC, C_Time DESC
END
ELSE
BEGIN
	SET @lastdate = '0000000'
	SET @lasttime = '000000'
END

PRINT @lastdate 
PRINT @lasttime

DECLARE eCursor CURSOR FOR
	SELECT C_Date, C_Time, L_TID, L_UID FROM UNIS.dbo.tEnter
	WHERE C_Date + C_Time >= @lastdate + @lasttime

OPEN eCursor

DECLARE @date char(8)
DECLARE @time char(6)
DECLARE @tid  int
DECLARE @uid  int

FETCH NEXT FROM eCursor INTO @date, @time, @tid, @uid
WHILE @@FETCH_STATUS=0 BEGIN

	IF (@uid <> -1)
	BEGIN
		DECLARE @datetime varchar(16)
		SET @datetime = @date + ' ' + SUBSTRING(@time, 1, 2) + ':' + SUBSTRING(@time, 3, 2)+ ':' + SUBSTRING(@time, 5, 2)
		DECLARE @mydate DATETIME
		DECLARE @mytime DATETIME
		SET @mydate = CAST(@date as DATETIME);
		SET @mytime = CAST(@datetime as DATETIME);
		PRINT (@date + ' ' + @time + ' ' + cast(@tid as varchar(1)) + ' ' +  cast(@uid as varchar(8)))
		INSERT INTO dbo.UNISEntries VALUES (@date, @time, @tid, @uid)
		EXEC dbo.RecordEntry @eid=@uid, @tid=@tid, @date=@mydate, @time=@mytime;
	END --IF
	FETCH NEXT FROM eCursor INTO @date, @time, @tid, @uid
END

CLOSE eCursor
DEALLOCATE eCursor
