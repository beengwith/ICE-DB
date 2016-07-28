DECLARE @ActiveEmployee TABLE (
	EmployeeId Int,
	EmployeeCode Text,
	EmployeeName Text,
	Designation Text,
	Department Text
);


INSERT INTO @ActiveEmployee
SELECT 
	emp.EmployeeID,
	emp.EmployeeCode,
	emp.EmployeeName,
	des.Designation,
	dep.Department,
FROM
	Employee AS emp
	INNER JOIN Department AS dep
		ON dep.DepartmentID = emp.DepartmentID
	INNER JOIN Designation AS des
		ON des.DesignationID = emp.DesignationID
WHERE
	emp.EmployeeStatus=1
	AND emp.EmployeeCode NOT LIKE 'None'

select * From @ActiveEmployee