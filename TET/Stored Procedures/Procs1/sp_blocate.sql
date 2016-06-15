
CREATE procedure [dbo].[sp_blocate]--- 1995/11/28 15:48
       @loginame sysname = NULL --or 'active'
as

create table #ceva(
	spid int,
	   ecid int,
	   status varchar(100),
       loginame varchar(100),
	   hostname varchar(100),
	   blk varchar(5),
	   dbname varchar(100),
	   cmd varchar(100),
	   request_id varchar(100)
)
insert into #ceva
exec sp_who
-- loginame arg is null

select spid,
	   ecid,
	   status,
       loginame,
	   hostname,
	   blk,
	   dbname,
	   cmd,
	   request_id
from  #ceva
where blk>0
return (0) -- sp_who



