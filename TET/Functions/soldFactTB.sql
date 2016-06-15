--***

create function soldFactTB(@tipFB varchar(1), @terti varchar(4000), @conturi varchar(2000), @tipint int, @datajos datetime, @datasus datetime,@valuta varchar(3))

--create function soldtb (@conturi varchar(4000), @tipint int, @datajos datetime, @datasus datetime,@valuta varchar(3))
returns @rez table (suma float, data datetime)  
as  
begin  
 --if @datajos is null set @datajos=isnull(select dbo.BOY(TB, ANUL.IND din par))  
  if @datasus is null set @datasus=dbo.EOM(isnull((select val_alfanumerica from par where Tip_parametru='TB' and Parametru='LUNA.IND'),getdate()))
  if @datajos is null set @datajos=dbo.BOY(@datasus)
 --if @datasus is null set @datasus=getdate()  
 --if @datasus is null set @datasus=isnull(select dbo.EOM(TB, LUNA.IND din par))  
 declare @dataimpl datetime,@datains datetime, @sc float,@sd float,@subunitate varchar(20)  
 select @dataimpl=dateadd(m,1,dateadd(d,-1,convert(datetime,convert(varchar(4),p1.val_numerica)+'-'+convert(varchar(2),p2.val_numerica)+'-1')))  
  from par p1, par p2 where p1.tip_parametru='GE' and p1.parametru like 'anulimpl' and p2.tip_parametru='GE' and p2.parametru like 'lunaimpl'  
 if (@datajos<@dataimpl) set @datajos=@dataimpl  
 select @subunitate=val_alfanumerica from par where tip_parametru='GE' and parametru='subpro'
 
 declare @r table (suma float, data datetime)  
 insert into @rez select 0, i.data from dbo.generezIntervaleTB(@tipint, @datajos, @datasus) i order by data
			--> am generat datele in care ne intereseaza soldul  
 
declare @iv int,@cont varchar(20)
declare @conturi2 table(cont varchar(20),tip varchar(1))  
set @conturi=isnull(@conturi,'')  if @conturi='' set @conturi='%'  set @conturi=rtrim(@conturi)+','  
while (isnull(@conturi,'')<>'')  
begin  
 set @iv=charindex(',',@conturi)  
 set @cont=substring(@conturi,1,@iv-1)  
 insert into @conturi2 select a.cont,c.tip_cont from arbconturi(@cont) a,conturi c   
   where a.cont=c.cont-- and c.are_analitice=0 
   and not exists (select 1 from @conturi2 co where co.cont=a.cont)  
 set @conturi=substring(@conturi,@iv+1,len(@conturi)-@iv)  
end

declare @tert varchar(20)
declare cr cursor for 
	select t.Tert from terti t where isnull(@terti,'')<>'' and charindex(','+rtrim(t.Tert)+',',','+@terti+',')>0
	union all select null where isnull(@terti,'')=''
open cr
fetch next from cr into @tert
while @@fetch_status=0
begin
	set @sd=0 set @datains=@datajos 
	delete @r
	insert into @r(data,suma)
	select r.data, sum(x.suma)
			from @rez r,(
			select f.data,(case when @valuta<>'' then sum(total_valuta-achitat_valuta) else sum(valoare+tva-achitat) end) suma
				from dbo.fFacturi(@tipFB,null,null,@tert,null,null,0,1,1, null, null) f
				where valuta=@valuta and exists(select 1 from @conturi2 c where c.cont=f.cont_de_tert)
				group by f.data
			) x where r.data>=x.data group by r.data
			
	update @rez set suma=rr.suma+r.suma 
		from @r r inner join @rez rr on r.data=rr.data
		--where data=r.data
	fetch next from cr into @tert
end
return  
end
