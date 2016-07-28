ALTER FUNCTION GetSandwichables(
	@begin_date datetime,
	@end_date datetime,
	@saturdays_optional bit=0
)
--DECLARE @begin_date datetime
--DECLARE @end_date datetime
--DECLARE @saturdays_optional bit
--SET @begin_date = CAST('2015-08-28 00:00:00.000' as datetime)
--SET @end_date   = CAST('2015-09-27 00:00:00.000' as datetime)
--SET @saturdays_optional = 0
RETURNS @Sandwichable TABLE (
	EmployeeAttendanceId Int UNIQUE,
	EmployeeId Int,
	HolidayDate DateTime,
	HolidayStatus Text,
	NewStatus Text
)
AS BEGIN

	DECLARE eCursor CURSOR FOR
		SELECT EmployeeId FROM Employee WHERE EmployeeStatus=1
	
	OPEN eCursor
	
	DECLARE @id Int
	FETCH NEXT FROM eCursor INTO @id
	WHILE @@FETCH_STATUS=0 BEGIN
		INSERT INTO @Sandwichable 
			SELECT * FROM GetEmpSandwichables(@id, @begin_date, @end_date, @saturdays_optional, DEFAULT)
		FETCH NEXT FROM eCursor INTO @id
	END
	
	CLOSE eCursor
	DEALLOCATE eCursor
	
	RETURN
END

