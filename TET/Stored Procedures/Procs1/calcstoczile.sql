--***
/*Procedura calculeaza stocul pe fiecare zi de la ultima luna inchisa pana la @datas si returneaza datele dintre @dataj_selectie si @datas. Daca exista date pentru lunile inchise acestea vor fi pastrate. Se poate opta doar pentru afisare fara recalcul (daca au fost generate stocurile anterior si exista date de afisat).*/
CREATE procedure calcstoczile
@gestiune char(9),@grupa char(13),@cod char(20),@dataj_selectie datetime, @datas datetime,@recalcul bit
as
begin
declare @data cursor
declare @data_zi datetime
declare @dataj datetime
declare @fetch int

set @dataj=dateadd(m,1,(select cast(val_numerica as char(4)) from par where parametru='ANULINC' and tip_parametru='GE')+'-'+
(select cast(val_numerica as char(2)) from par where parametru='LUNAINC' and tip_parametru='GE')+'-01')

--select @dataj

set @data = cursor for select data from calstd where data between @dataj and @datas order by data

if not exists (select * from sysobjects where name='tmp_stoc_zilnic') 
CREATE TABLE [dbo].[tmp_stoc_zilnic](
 [data] [datetime] NULL,
 [gestiune] [char](9) NULL,
 [cod] [char](20) NULL,
 [cod_intrare] [char](13) NULL,
 [pret] [float] NULL,
 [stoc] [float] NULL
) ON [PRIMARY]

if (@recalcul=1)
begin
create table #stoc_zilnic 
(data datetime,gestiune char(9),cod char(20),cod_intrare char(13),pret float,stoc float)

--select @gestiune,@grupa,@cod,@dataj

insert into #stoc_zilnic
select DateAdd(d,-1,@dataj),i.cod_gestiune,i.cod,i.cod_intrare,i.pret,i.stoc 
 from isstoc i
 left outer join nomencl n on n.cod=i.cod
 left outer join grupe g on n.grupa=g.grupa
 where i.data_lunii=DateAdd(d,-1,DateAdd(m,1,@dataj)) and i.tip_gestiune<>'F'
  and i.cod_gestiune like rtrim(@gestiune)+'%' and i.cod like (case when rtrim(@cod)='' then '%' else rtrim(@cod) end) 
  and g.grupa like rtrim(@grupa)+'%' 
 
open @data
fetch from @data into @data_zi
set @fetch=@@fetch_status
while @fetch=0
 begin
 insert into #stoc_zilnic
 select @data_zi,s.gestiune,s.cod,s.cod_intrare,s.pret,s.stoc from #stoc_zilnic s
  where s.data=DateAdd(d,-1,@data_zi) and s.stoc<>0

 update #stoc_zilnic 
  set stoc=stoc+
  isnull((select sum(case 
     when dd.tip_miscare='I' then dd.cantitate else -1*dd.cantitate end)
   from docstocd dd where dd.gestiune=#stoc_zilnic.gestiune and dd.cod=#stoc_zilnic.cod 
    and dd.cod_intrare=#stoc_zilnic.cod_intrare and dd.data=@data_zi),0)
  where data=@data_zi

 insert into #stoc_zilnic
  select @data_zi,dd.gestiune,dd.cod,dd.cod_intrare,dd.pret,sum(case 
     when dd.tip_miscare='I' then dd.cantitate else -1*dd.cantitate end) from docstocd dd
   left outer join nomencl n on n.cod=dd.cod
   left outer join grupe g on n.grupa=g.grupa
   where not exists (select * from #stoc_zilnic where dd.gestiune=#stoc_zilnic.gestiune and dd.cod=#stoc_zilnic.cod 
    and dd.cod_intrare=#stoc_zilnic.cod_intrare and #stoc_zilnic.data=@data_zi) and dd.data=@data_zi
    and dd.gestiune like rtrim(@gestiune)+'%' and dd.cod like (case when rtrim(@cod)='' then '%' else rtrim(@cod) end) 
    and g.grupa like rtrim(@grupa)+'%'
   group by dd.gestiune,dd.cod,dd.cod_intrare,dd.pret

 fetch from @data into @data_zi
 set @fetch=@@fetch_status
 end

delete from  tmp_stoc_zilnic where data between dateadd(d,-1,@dataj) and @datas
and tmp_stoc_zilnic.gestiune like rtrim(@gestiune)+'%' and tmp_stoc_zilnic.cod like (case when rtrim(@cod)='' then '%' else rtrim(@cod) end) 
and tmp_stoc_zilnic.cod in (select cod from nomencl where grupa like rtrim(@grupa)+'%')
insert into tmp_stoc_zilnic select * from #stoc_zilnic
select * from tmp_stoc_zilnic where data between @dataj_selectie and @datas

drop table #stoc_zilnic
end
else 

select * from tmp_stoc_zilnic t
left outer join nomencl n on n.cod=t.cod
left outer join grupe g on n.grupa=g.grupa
where data between @dataj_selectie and @datas
and t.gestiune like rtrim(@gestiune)+'%' and t.cod like (case when rtrim(@cod)='' then '%' else rtrim(@cod) end) 
and g.grupa like rtrim(@grupa)+'%'
and t.stoc<>0

end
