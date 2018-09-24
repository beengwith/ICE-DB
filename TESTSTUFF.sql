-- select top(100) EmployeeId, convert(varchar(10), TrackDate, 102) as Date, convert(Varchar(10), InOutTime, 108) as Time, InOutStatus 
-- from attendancedetails
-- where employeeid = 107
-- order by adid desc



--delete from attendancedetails
--where employeeid = 107
--	and adid = (select max(isnull(adid, 0)) from attendancedetails where employeeid = 107)

--Select * from employee where employeename like '%shamsi%'

--Select * from employee where employeename like '%wakeel%'


Delete From attendancedetails where employeeid = 107 and trackdate >= '20180827'
Delete From EmployeeAttendance where employeeid = 107 and attendanceDate >= '20180827'


Exec RecordFingerPrintEntry 9600154, 1, '20180903', '080000'
Exec RecordFingerPrintEntry 9600154, 1, '20180903', '110000'
Exec RecordFingerPrintEntry 9600154, 2, '20180903', '184500'
Exec RecordFingerPrintEntry 9600154, 2, '20180904', '104500'
Exec RecordFingerPrintEntry 9600154, 1, '20180904', '105500'
Exec RecordFingerPrintEntry 9600154, 2, '20180905', '005500'
Exec RecordFingerPrintEntry 9600154, 1, '20180905', '015500'
Exec RecordFingerPrintEntry 9600154, 2, '20180905', '085500'
Exec RecordFingerPrintEntry 9600154, 1, '20180905', '185500'
Exec RecordFingerPrintEntry 9600154, 2, '20180906', '085500'
Exec RecordFingerPrintEntry 9600154, 1, '20180909', '085500'
Exec RecordFingerPrintEntry 9600154, 1, '20180910', '085500'


Declare @code int;
SET @code=9600154

Select top(20) 
    convert(varchar(10), TrackDate, 102) as Date,
    InOutTime, attd.InOutStatus, Employee.EmployeeCode, attd.EmployeeID
From
    attendancedetails as attd
    Join employee on employee.employeeid = attd.employeeid
Where employeecode = convert(varchar, @code)
Order By adid Desc


Select top(20)
    emp.EmployeeCode, eatt.EmployeeID, AttendanceDate,
    AttendanceStatus, timeStatus
From
    EmployeeAttendance as eatt
    Join Employee as emp on eatt.employeeid = emp.employeeid
Where emp.employeecode = convert(varchar, @code)
order By AttendanceDate Desc
