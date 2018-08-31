-- select top(100) EmployeeId, convert(varchar(10), TrackDate, 102) as Date, convert(Varchar(10), InOutTime, 108) as Time, InOutStatus 
-- from attendancedetails
-- where employeeid = 107
-- order by adid desc



--delete from attendancedetails
--where employeeid = 107
--	and adid = (select max(isnull(adid, 0)) from attendancedetails where employeeid = 107)

--Select * from employee where employeename like '%shamsi%'

--Select * from employee where employeename like '%wakeel%'


Delete From attendancedetails where employeeid = 107 and trackdate >= '20180803'
Delete From EmployeeAttendance where employeeid = 107 and attendanceDate >= '20180803'


Exec RecordFingerPrintEntry 9600154, 1, '20180803', '080000'
Exec RecordFingerPrintEntry 9600154, 1, '20180803', '110000'
Exec RecordFingerPrintEntry 9600154, 2, '20180803', '184500'
Exec RecordFingerPrintEntry 9600154, 2, '20180804', '104500'
Exec RecordFingerPrintEntry 9600154, 1, '20180804', '105500'
Exec RecordFingerPrintEntry 9600154, 2, '20180805', '005500'
Exec RecordFingerPrintEntry 9600154, 1, '20180805', '015500'
Exec RecordFingerPrintEntry 9600154, 2, '20180805', '085500'
Exec RecordFingerPrintEntry 9600154, 1, '20180805', '185500'
Exec RecordFingerPrintEntry 9600154, 2, '20180806', '085500'
Exec RecordFingerPrintEntry 9600154, 1, '20180809', '085500'
Exec RecordFingerPrintEntry 9600154, 1, '20180810', '085500'


Declare @code int;
SET @code=9600154

Select top(20) 
    convert(varchar(10), TrackDate, 102) as Date,
    InOutTime,
    attd.InOutStatus,
    Employee.EmployeeCode,
    attd.EmployeeID
From
    attendancedetails as attd
    Join employee on employee.employeeid = attd.employeeid
Where employeecode = convert(varchar, @code)
Order By adid Desc


select top(10)
    emp.EmployeeCode,
    eatt.EmployeeID,
    AttendanceDate,
    AttendanceStatus,
    timeStatus
from
    EmployeeAttendance as eatt
    Join Employee as emp on eatt.employeeid = emp.employeeid
Where
    emp.employeecode = convert(varchar, @code)
order by
    AttendanceDate Desc


