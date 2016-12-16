DECLARE @begin_date DateTime
DECLARE @end_date DateTime
SET @begin_date=CAST('2016-06-26 00:00:00.000' AS DATETIME)
SET @end_date=CAST('2016-10-23 00:00:00.000' AS DATETIME)

DECLARE @DailyAttendanceData TABLE (
	EmployeeID int,
	EmployeeName varchar(100),
	EmployeeCode varchar(10),
	Department varchar(50),
	Designation varchar(50),
	JoiningDate datetime,
	Date datetime,
	DayName varchar(10),
	Holiday varchar(50),
	InTime datetime,
	OutTime datetime,
	AttendanceStatus varchar(50),
	WorkingHours int,
	RequiredHours int,
	OverTimeDifference int,
	Late int,
	HalfDay int,
	ShortLeave int	
);

INSERT INTO @DailyAttendanceData
	SELECT * FROM dbo.GetDailyAttendanceData( @begin_date, @end_date )


DECLARE eCursor CURSOR FOR
	SELECT 
		EmployeeCode,
		MIN(Date) as Date
	FROM
		@DailyAttendanceData
	WHERE
		AttendanceStatus='P' AND InTime is NULL AND OutTime is NULL
	GROUP BY
		EmployeeCode


OPEN eCursor
DECLARE @eid int
DECLARE @date datetime

FETCH NEXT FROM eCursor INTO @eid, @date
WHILE @@FETCH_STATUS=0 BEGIN
	PRINT convert(varchar(10), @eid) + ' ' + convert(varchar(10), @date, 102)
	EXEC dbo.ClearEntries @eid, @date
	FETCH NEXT FROM eCursor INTO @eid, @date
END
CLOSE eCursor
DEALLOCATE eCursor