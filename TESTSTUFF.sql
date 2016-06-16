select top(100) EmployeeId, convert(varchar(10), TrackDate, 102) as Date, convert(Varchar(10), InOutTime, 108) as Time, InOutStatus 
from attendancedetails
where employeeid = 418
order by adid desc



--delete from attendancedetails
--where employeeid = 107
--	and adid = (select max(isnull(adid, 0)) from attendancedetails where employeeid = 107)

-- Select * from employee where employeename like 'rana%'

Select * from employee where employeeid = 418