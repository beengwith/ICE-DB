DECLARE @EmpID INT;
DECLARE @begin_date DateTime
DECLARE @end_date DateTime


SET @begin_date=CAST('2017-01-01 00:00:00.000' AS DATETIME)
SET @end_date=CAST('2018-03-26 00:00:00.000' AS DATETIME)
SET @EmpID = (SELECT EmployeeId FROM Employee
			  WHERE EmployeeName like '%tai%jah%' )



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
	SELECT * FROM dbo.GetDailyAttendanceDataForEmployee( @begin_date, @end_date, 1, default )
	

SELECT
	--EmployeeID,
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
	Sum((CASE WHEN OvertimeDifference < 0 THEN 1 ELSE 0 END)*late) as Late_N_Short,
	Sum(HalfDay) as HalfDays,
	Sum(ShortLeave) as ShortLeaves,
	Sum(CASE
		WHEN
			AttendanceStatus='P'
				AND Holiday != ''
		THEN 1
		ELSE 0 END) as ExtraDays,
	Sum(CASE
		WHEN
			AttendanceStatus='P'
				AND Holiday = ''
				AND OvertimeDifference > 480
		THEN 1
		ELSE 0 END) as Nights,	
	SUM(Food) as FoodOrders,
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
	(dbo.GetLeavesRemaining(Data.EmployeeID, @end_date, 'CL', 10)) as CasualLeavesRemaining,
	(dbo.GetLeavesRemaining(Data.EmployeeID, @end_date, 'SL', 6)) as SickLeavesRemaining,
	(dbo.GetAnnualLeavesRemaining(Data.EmployeeID, @end_date, default, default)) as AnnualLeavesRemaining,
	(case
		when datediff(d, joiningdate, getdate()) >= 365
		then 1
		else 0
		end
	) as AnnualLeavesEligibility

FROM
	@DailyAttendanceData as Data
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
	(CASE
		WHEN
			AttendanceStatus='P'
				AND Holiday != ''
		THEN 1
		ELSE 0 END) as ExtraDay,
	(CASE
		WHEN
			AttendanceStatus='P'
				AND Holiday = ''
				AND OvertimeDifference > 480
		THEN 1
		ELSE 0 END) as Night,
	CONVERT(varchar(5), 
       DATEADD(minute, workingHours, 0), 114) as WorkingHours,
	(CASE WHEN OverTimeDifference>=0 THEN '' ELSE '-' END) + CONVERT(varchar(5), 
       DATEADD(minute, abs(OverTimeDifference), 0), 114) as OverTimeDifference,
	Late,
	(CASE WHEN OvertimeDifference < 0 THEN 1 ELSE 0 END) * late as Late_N_Short,
	HalfDay,
	ShortLeave,
	Food
FROM
	@DailyAttendanceData
ORDER BY
	Department, EmployeeName, Date