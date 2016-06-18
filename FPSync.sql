USE Ice_Project_Directory

-- CREATING THE TABLE IF IT DOES NOT EXIST
IF  NOT EXISTS (
	SELECT * FROM sys.objects 
	WHERE object_id = OBJECT_ID(N'dbo.FPEntries') AND type in (N'U')
)
BEGIN
CREATE TABLE dbo.FPEntries (
    C_Date char(8),
    C_Time char(6),
	L_TID int,
	L_UID int
) 
END


-- FIND OUT LATEST ENTRIES TO LIMIT UPDATE TO NEW ENTRIES ONLY
DECLARE @lastdate char(8)
DECLARE @lasttime char(8)

IF (SELECT Count(*) FROM dbo.FPEntries ) != 0
BEGIN 
	SELECT TOP(1) @lastdate=C_Date, @lasttime=C_Time
	FROM dbo.FPEntries 
	ORDER BY C_Date DESC, C_Time DESC
END
ELSE
BEGIN
	SET @lastdate = '00000000'
	SET @lasttime = '000000'
END

PRINT @lastdate 
PRINT @lasttime


-- ALL NEW ENTRIES WILL BE ADDED TO THIS TABLE
DECLARE @NewFPEntries TABLE(
    C_Date char(8),
    C_Time char(6),
	L_TID int,
	L_UID int
) 

-- GET FROM UNIS
INSERT INTO @NewFPEntries 
	SELECT C_Date, C_Time, L_TID, L_UID
	FROM UNIS.dbo.tEnter
	WHERE 
		L_UID <> -1
		AND	NOT EXISTS ( 
				SELECT *
				FROM dbo.FPEntries
				WHERE
					C_Date=UNIS.dbo.tEnter.C_Date AND
					C_Time=UNIS.dbo.tEnter.C_Time AND
					L_TID=UNIS.dbo.tEnter.L_TID AND
					L_UID=UNIS.dbo.tEnter.L_UID	
			)
		

-- GET FROM ZKT
INSERT INTO @NewFPEntries
	SELECT
		REPLACE(CONVERT(CHAR(20), CHECKTIME, 102), '.', '') AS C_Date,
		REPLACE(CONVERT(CHAR(20), CHECKTIME, 108), ':', '') AS C_Time,
		(CASE WHEN CHECKTYPE='I' THEN 1 ELSE 2 END) as L_TID,
		CAST(BADGENUMBER AS INT) AS L_UID
	FROM zkt.dbo.CHECKINOUT JOIN zkt.dbo.USERINFO ON zkt.dbo.CHECKINOUT.USERID = zkt.dbo.USERINFO.USERID
	WHERE
		NOT EXISTS (
			SELECT *
			FROM dbo.FPEntries
			WHERE 
				C_Date=REPLACE(CONVERT(CHAR(20), CHECKTIME, 102), '.', '') AND
				C_Time=REPLACE(CONVERT(CHAR(20), CHECKTIME, 108), ':', '') AND
				L_TID=(CASE WHEN CHECKTYPE='I' THEN 1 ELSE 2 END) AND
				L_UID=CAST(BADGENUMBER AS INT)
		)

DECLARE @NewFPEntriesOrdered TABLE(
    C_Date char(8),
    C_Time char(6),
	L_TID int,
	L_UID int
) 

INSERT INTO @NewFPEntriesOrdered
	SELECT * FROM @NewFPEntries
	ORDER BY C_Date ASC, C_Time ASC

-- TAKING ALL NEW FP ENTRIES ONE BY ONE AND PROCESSING 
DECLARE eCursor CURSOR FOR
	SELECT C_Date, C_Time, L_TID, L_UID FROM @NewFPEntriesOrdered


OPEN eCursor

DECLARE @date char(8)
DECLARE @time char(6)
DECLARE @tid  int
DECLARE @uid  int

FETCH NEXT FROM eCursor INTO @date, @time, @tid, @uid
WHILE @@FETCH_STATUS=0 BEGIN

	IF (@uid <> -1)
	BEGIN
		DECLARE @mydate DATETIME
		DECLARE @mytime DATETIME
		SET @mydate = CAST(@date as DATETIME);
		SET @mytime = dbo.makeDateTime(@date, @time);
		INSERT INTO dbo.FPEntries VALUES (@date, @time, @tid, @uid)
		EXEC dbo.RecordEntry @eid=@uid, @tid=@tid, @date=@mydate, @time=@mytime;
	END --IF
	FETCH NEXT FROM eCursor INTO @date, @time, @tid, @uid
END

CLOSE eCursor
DEALLOCATE eCursor
