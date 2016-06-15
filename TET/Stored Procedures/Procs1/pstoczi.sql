--***
create procedure pstoczi @cCodPar char(20),@dDataJos datetime,@dDataSus datetime
as
create table #stoczi (data datetime,cod char(13),codgest char(13),
stoc_initial float,intrari float, iesiri float, stoc float)
--truncate table #stoczi
declare @data1 datetime, @data2 datetime, @datat datetime

set @data1=@dDataJos
set @data2=@dDataSus

declare @gdata datetime, @gcod char(13), @gcodgest char(13), @gcant int,
 @gfetch int, @cintrari float, @ciesiri float
declare @cdata datetime, @ccod char(13), @ccodgest char(13), @ccant int, @ctip_miscare char(1),
 @nStoc float
declare @datatmp datetime

if not exists (select * from #stoczi where data=dateadd(day,-1,@data1))
begin
 if exists (select * from #stoczi where cod=@cCodPar)
 begin
  set @data1=dateadd(day,1,(select max(data) from #stoczi where data<@data1))
 end
 else
 if exists (select * from isstoc where month(data_lunii)<=month(@data1) and year(data_lunii)<=year(@data1) and cod=@cCodPar)
 begin
  set @datat=(select max(data_lunii) from isstoc 
   where month(data_lunii)<=month(@data1) and year(data_lunii)<=year(@data1))
  set @datat=dateadd(day,-1,cast(month(@datat) as char)+'/01/'+cast(year(@datat) as char))

  if exists (select * from sysobjects where name='tmptmp') drop table tmptmp
  select @datat as data, cod as cod, cod_gestiune as codgest, sum(stoc) as stoc_initial,
   0 as intrari, 0 as iesiri, sum(stoc) as stoc
  into tmptmp from isstoc where cod=@cCodPar AND data_lunii=(select max(data_lunii) from isstoc 
   where month(data_lunii)<=month(@data1) and year(data_lunii)<=year(@data1))
  group by cod_gestiune, cod

  insert into #stoczi select * from tmptmp

  set @data1=dateadd(day,1,@datat)
  
 end
 else
 begin
  set @datat=(select max(data) from stocuri where data<@data1)
  
  if exists (select * from sysobjects where name='tmptmp') drop table tmptmp
  select @datat as data, cod as cod,cod_gestiune as codgest, sum(stoc) as stoc_initial,0 as intrari,
   0 as iesiri, sum(stoc) as stoc
  into tmptmp from stocuri where data<@data1 and cod=@cCodPar
  group by cod_gestiune, cod

  insert into #stoczi select * from tmptmp

  set @data1=dateadd(day,1,@datat)

 end
end 
 
--print @data1

declare tmp cursor for select data, cod, gestiune, cantitate, tip_miscare from pozdoc
where tip_miscare in ('I','E') and (data between @data1 and @data2) and cod=@cCodPar order by gestiune,cod,data

open tmp
 fetch next from tmp into @cdata, @ccod, @ccodgest, @ccant, @ctip_miscare
 set @gdata=@cdata
 set @gcod=@ccod
 set @gcodgest=@ccodgest
 set @gfetch=@@fetch_status
 while @gfetch=0
 begin
  set @nStoc=isnull((select stoc from #stoczi where cod=@gcod and codgest=@gcodgest and data=dateadd(day,-1,@data1)),0)
  set @datatmp=@data1
  while @datatmp<@gdata
  begin
   insert into #stoczi select @datatmp, @gcod, @gcodgest, @nStoc, '0', '0', @nStoc
   set @datatmp=dateadd(day,1,@datatmp)
  end
  while @gfetch=0 and @gcod=@ccod and @gcodgest=@ccodgest
  begin
   set @cintrari=0
   set @ciesiri=0
   while @gdata=@cdata and @gfetch=0
   begin
    if @ctip_miscare='I' set @cintrari=@cintrari+isnull(@ccant,0)
    if @ctip_miscare='E' set @ciesiri=@ciesiri+abs(isnull(@ccant,0))
    fetch next from tmp into @cdata, @ccod, @ccodgest, @ccant, @ctip_miscare
    set @gfetch=@@fetch_status
   end
   insert into #stoczi select @gdata, @gcod, @gcodgest, @nStoc, @cintrari, @ciesiri, @nStoc+@cintrari-@ciesiri
   set @nStoc=@nStoc+@cintrari-@ciesiri

   set @datatmp=dateadd(day,1,@gdata)
   while @datatmp<@cdata
   begin   
    insert into #stoczi select @datatmp, @gcod, @gcodgest, @nStoc, '0', '0', @nStoc
    set @datatmp=dateadd(day,1,@datatmp)
   end

   set @datatmp=dateadd(day,1,@gdata)
   set @gdata=@cdata
  end
  while @datatmp<=@data2
  begin
   insert into #stoczi select @datatmp, @gcod, @gcodgest, @nStoc, '0', '0', @nStoc
   set @datatmp=dateadd(day,1,@datatmp)
  end
  set @gcod=@ccod
  set @gcodgest=@ccodgest
 end
close tmp
deallocate tmp
select * from #stoczi
