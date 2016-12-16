DECLARE @begin_date DateTime
DECLARE @end_date DateTime
SET @begin_date=CAST('2016-08-26 00:00:00.000' AS DATETIME)
SET @end_date=CAST('2016-10-26 00:00:00.000' AS DATETIME)

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
	StartTime datetime,
	EndTime datetime,
	AttendanceStatus varchar(50),
	WorkingHours int,
	RequiredHours int,
	OverTimeDifference int,
	Late int,
	HalfDay int,
	ShortLeave int,
	Food int	
);

INSERT INTO @DailyAttendanceData
	SELECT * FROM dbo.GetDailyAttendanceData( @begin_date, @end_date )

SELECT
	EmployeeID,
	EmployeeName,
	EmployeeCode,
	Department,
	Designation,
	JoiningDate,
	--AttendanceStatus,
	count(*) as TotalDaysCount,
	(SELECT Count(EmployeeID)
		FROM @DailyAttendanceData as dad
		WHERE
			 dad.AttendanceStatus = 'P'
			 AND dad.EmployeeID=Data.EmployeeID
		) as Presents,
	(SELECT Count(EmployeeID)
		FROM @DailyAttendanceData as dad
		WHERE
			 dad.AttendanceStatus = 'Holiday'
			 AND dad.EmployeeID=Data.EmployeeID
		) as Holidays,
	(SELECT Count(EmployeeID)
		FROM @DailyAttendanceData as dad
		WHERE
			 (dad.AttendanceStatus = 'A'
				 OR dad.AttendanceStatus is NULL)
			 AND dad.EmployeeID=Data.EmployeeID
		) as Absents,
	(SELECT Count(EmployeeID)
		FROM @DailyAttendanceData as dad
		WHERE
			 dad.AttendanceStatus is NULL
			 AND dad.EmployeeID=Data.EmployeeID
		) as Unrecorded,
	Sum(OverTimeDifference) as OverTime,
	Sum(late) as Lates,
	Sum(HalfDay) as HalfDays,
	Sum(ShortLeave) as ShortLeaves,
	(SELECT Count(EmployeeID)
		FROM @DailyAttendanceData as dad
		WHERE
			 dad.AttendanceStatus = 'C'
			 AND dad.EmployeeID=Data.EmployeeID
		) as Compensations,
	(SELECT Count(EmployeeID)
		FROM @DailyAttendanceData as dad
		WHERE
			 dad.AttendanceStatus = 'General Leave'
			 AND dad.EmployeeID=Data.EmployeeID
		) as GeneralLeaves,
	(SELECT Count(EmployeeID)
		FROM @DailyAttendanceData as dad
		WHERE
			 dad.AttendanceStatus = 'CL'
			 AND dad.EmployeeID=Data.EmployeeID
		) as CasualLeaves,
	(SELECT Count(EmployeeID)
		FROM @DailyAttendanceData as dad
		WHERE
			 dad.AttendanceStatus = 'SL'
			 AND dad.EmployeeID=Data.EmployeeID
		) as SickLeaves,
	(SELECT Count(EmployeeID)
		FROM @DailyAttendanceData as dad
		WHERE
			 dad.AttendanceStatus = 'AL'
			 AND dad.EmployeeID=Data.EmployeeID
		) as AnnualLeaves,
	(SELECT Count(EmployeeID)
		FROM @DailyAttendanceData as dad
		WHERE
			 dad.AttendanceStatus = 'Marriage Leave'
			 AND dad.EmployeeID=Data.EmployeeID
		) as MarriageLeaves,
	(SELECT Count(EmployeeID)
		FROM @DailyAttendanceData as dad
		WHERE
			 dad.AttendanceStatus = 'Others'
			 AND dad.EmployeeID=Data.EmployeeID
		) as Others,
	SUM(Food) as FoodOrders
FROM
	@DailyAttendanceData as Data
WHERE
	EmployeeName like '%usman%'
GROUP BY 
	EmployeeID,
	EmployeeCode,
	EmployeeName,
	Department,
	Designation,
	JoiningDate
ORDER By
	Department, EmployeeName

SELECT 
	EmployeeName,
	EmployeeCode,
	Department,
	Designation,
	CONVERT(varchar(50), Date, 102) as Date,
	DayName as DayOfTheWeek,
	Holiday,
	CONVERT(varchar(50), InTime, 108) as InTime,
	CONVERT(varchar(50), OutTime, 108) as OutTime,
	AttendanceStatus,
	CONVERT(varchar(5), 
       DATEADD(minute, workingHours, 0), 114) as WorkingHours,
	(CASE WHEN OverTimeDifference>=0 THEN '' ELSE '-' END) + CONVERT(varchar(5), 
       DATEADD(minute, abs(OverTimeDifference), 0), 114) as OverTimeDifference,
	Late,
	HalfDay,
	ShortLeave,
	Food
FROM
	@DailyAttendanceData
--WHERE
--	EmployeeName like '%usman%'
ORDER BY 
	Department, EmployeeName, Date


