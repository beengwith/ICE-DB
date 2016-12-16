DECLARE @begin_date DateTime
DECLARE @end_date DateTime
SET @begin_date=CAST('2016-05-01 00:00:00.000' AS DATETIME)
SET @end_date=CAST('2016-10-26 00:00:00.000' AS DATETIME)


DECLARE eCursor CURSOR FOR
SELECT
	--EmployeeID,
	Entries.L_UID as EmployeeCode,
	MIN(CONVERT(DATETIME, Entries.C_Date)) as Date
FROM
	(
		SELECT
			DISTINCT L_UID, C_Date
		FROM
			FPEntries
		WHERE
			C_Date >= REPLACE(CONVERT(CHAR(20), @begin_date, 102), '.', '') AND
			C_Date < REPLACE(CONVERT(CHAR(20), @end_date, 102), '.', '')
	) AS Entries
	JOIN 
	(
		SELECT
			Employee.EmployeeID,
			CAST(EmployeeCode AS INT) AS L_UID,
			REPLACE(CONVERT(CHAR(20), AttendanceDate, 102), '.', '') AS C_Date,
			AttendanceStatus
		FROM
			EmployeeAttendance
			JOIN
			Employee
			ON Employee.EmployeeID = EmployeeAttendance.EmployeeID
		WHERE
			AttendanceDate >= @begin_date
			AND AttendanceDate < @end_date
			AND AttendanceStatus = 'A'
	) AS Attendance
	ON Entries.L_UID = Attendance.L_UID
		AND Entries.C_Date = Attendance.C_Date

GROUP BY
	Entries.L_UID


OPEN eCursor
DECLARE @date DATETIME
DECLARE @ecode int

FETCH NEXT FROM eCursor INTO @ecode, @date
WHILE @@FETCH_STATUS=0 
BEGIN
	--EXEC dbo.ClearEntries @ecode, @date
	PRINT CONVERT(varchar(10), @ecode) + ' ' + CONVERT(varchar(10), @date, 102)
	FETCH NEXT FROM eCursor INTO @ecode, @date
END	
CLOSE eCursor
DEALLOCATE eCursor