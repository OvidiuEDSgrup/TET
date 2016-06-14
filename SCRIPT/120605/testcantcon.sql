declare @csub char(9),@ccod char(20),@cmodpl char(8),@ctip char(2),@ccontr char(20),@ctert char(13),@semn int,@cant float, @dtermen datetime, @pozcon int, @contrcor char(20) 
set @csub='1'
set @ccod='AA1KU2'
set @ctip='BK'
set @ctert='10241613S'
set @ccontr='63'
 select 1 from pozcon where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and (abs(cant_aprobata)-abs(cant_realizata)>=0.001 or abs(cant_aprobata)>=0.001 and sign(cant_aprobata)*sign(cant_realizata)<1)
select max(stare) from con where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr