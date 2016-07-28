DECLARE eCursor CURSOR FOR
	SELECT EmployeeId, EmployeeName, EmployeeStatus, EmployeeCode, EmployeeLogin FROM Employee WHERE EmployeeStatus=0

OPEN eCursor

DECLARE @EmployeeId Int
DECLARE @EmployeeName varchar(50)
DECLARE @EmployeeStatus bit
DECLARE @EmployeeCode varchar(50)
DECLARE @EmployeeLogin varchar(50)

FETCH NEXT FROM eCursor INTO @EmployeeId, @EmployeeName, @EmployeeStatus, @EmployeeCode, @EmployeeLogin
WHILE @@FETCH_STATUS=0 BEGIN
	UPDATE Employee
		SET	
			EmployeeLogin = (CASE
				WHEN @EmployeeLogin like '%.old' THEN
					@EmployeeLogin
				WHEN @EmployeeLogin = '' THEN
					''
				ELSE
					@EmployeeLogin + '.old'
			END),
			Employeename = (CASE
				WHEN @EmployeeName not like '%inactive%' THEN
					@EmployeeName + ' (Inactive)'
				ELSE
					@EmployeeName
			END),
			EmployeeCode = (CASE
				WHEN Len(@EmployeeCode) > 7 THEN
					@EmployeeCode
				ELSE
					@EmployeeCode + '0'
			END)
		WHERE
			EmployeeId = @EmployeeId 
	FETCH NEXT FROM eCursor INTO @EmployeeId, @EmployeeName, @EmployeeStatus, @EmployeeCode, @EmployeeLogin
END

CLOSE eCursor
DEALLOCATE eCursor


