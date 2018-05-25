DECLARE @begin_date DateTime
DECLARE @end_date DateTime
DECLARE @employee_id varchar(10)
DECLARE @employee_code varchar(10)
DECLARE @employee_name varchar(50)
DECLARE @department varchar(50)
DECLARE @designation varchar(50)
DECLARE @late_time_mins int
DECLARE @employee_status varchar(1)
DECLARE @saturday_optional bit


SET @begin_date=CAST('2017-01-01 00:00:00.000' AS DATETIME)
SET @end_date=CAST('2017-01-10 00:00:00.000' AS DATETIME)
SET @late_time_mins=30
SET @saturday_optional=1

SET @employee_id='%'
SET @employee_name='%tai%jah%'
SET @employee_code='%'
SET @department='%'
SET @designation='%'
SET @employee_status='%'


			SELECT
				adIn.EmployeeID,
				adIn.InOutID,
				adIn.TrackDate,
				adIn.InOutTime AS InTime,
				adOut.InOutTime AS OutTime,
				DATEDIFF(MINUTE, adIn.InOutTime, 
						ISNULL(adOut.InOutTime, adIn.InOutTime)) as diff
			FROM
				(
					SELECT 
						InOutID,
						EmployeeID,
						TrackDate,
						InOutTime
					FROM AttendanceDetails
					WHERE
						TrackDate >= @begin_date
						AND TrackDate < @end_date
						AND InOutStatus='In'
				) as adIn 
				LEFT JOIN
				(
					SELECT
						InOutID,
						EmployeeID,
						TrackDate,
						InOutTime
					FROM AttendanceDetails
					WHERE
						TrackDate >= @begin_date
						AND TrackDate < @end_date
						AND InOutStatus='Out'
				) as adOut 
				ON adIn.InOutID = adOut.InOutID
					AND adIn.EmployeeID = adOut.EmployeeID
	





--DECLARE @EmployeeInfo TABLE (
--	EmployeeID int,
--	EmployeeCode varchar(10),
--	EmployeeName varchar(100),
--	Designation varchar(50),	
--	Department varchar(50),
--	JoiningDate datetime,
--	CompanyName varchar(50),
--	StartTime datetime,
--	EndTime datetime
--);

--INSERT INTO @EmployeeInfo
--	SELECT * 
--	FROM GetEmployeeInfo(@employee_id, @employee_name, @employee_code, @department, @designation, @employee_status)

--DECLARE @DaysInfo TABLE (
--	Date DateTime,
--	DayName varchar(20),
--	Description varchar(50)
--);
--	
--INSERT INTO @DaysInfo
--	SELECT * FROM GetDaysInfo(@begin_date, @end_date, @saturday_optional)
--