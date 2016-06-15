--***
create procedure rapInterventii(@DataJos datetime,@DataSus datetime,@Masina varchar(100),@TipInterventie varchar(100),@Element varchar(100),
			@tip_activitate varchar(100),@locm nvarchar(100),
		@ordonare int=1)
as

set transaction isolation level read uncommitted
select @TipInterventie=case when @TipInterventie='X' then null else @TipInterventie end
declare @parametri varchar(2000)
set @parametri='<row '+(case when @DataJos is null then '' else 'datajos="'+convert(varchar(20),@DataJos,101)+'" ' end)+
					+(case when @DataSus is null then '' else 'datasus="'+convert(varchar(20),@DataSus,101)+'" ' end)+
					+(case when @Masina is null then '' else 'codMasina="'+@Masina+'" ' end)+
					+(case when @TipInterventie is null then '' else 'tipinterventii="'+@TipInterventie+'" ' end)+
					+(case when @Element is null then '' else 'element="'+@Element+'" ' end)+
		'/>'	--> parametri pentru procedura fIaInterventii
/*--tst
	select * from dbo.fIaInterventii('',@parametri) f	--*/
IF OBJECT_ID('tempdb..#ema') IS NOT NULL
		drop table #ema
IF OBJECT_ID('tempdb..#interventii') IS NOT NULL
		drop table #interventii
IF OBJECT_ID('tempdb..#c_masini') IS NOT NULL
		drop table #c_masini
declare @elem_ef varchar(20)	--> codul elementului (km/ore efectivi) care se cer pe raport
select @elem_ef=(case when @tip_activitate='P' then 'kmef' else 'OEchv' end)

select cod_masina into #c_masini from masini m where (@locm is null or m.loc_de_munca like @locm)
		and (@Masina is null or m.cod_masina=@Masina)
		and exists (select 1 from grupemasini g inner join tipmasini t on g.tip_masina=t.Cod 
						where t.Tip_activitate=@tip_activitate and g.Grupa=m.grupa)
create index indxm on #c_masini(cod_masina)

select	f.*,(case when @ordonare=1	then masina
									else element end)+'|'+convert(varchar(20),data,102) as ordonare
into #interventii from dbo.fIaInterventii('',@parametri) f
	inner join #c_masini m on f.masina=m.cod_masina
order by f.nr_inmatriculare, f.element, f.data

create index f_indx on #interventii(masina,data)

select row_number() over (partition by a.masina, e.element order by a.data) as id,
		a.Masina, e.Element, max(e.Valoare) Valoare, a.data, a.data data_urm--, pa.Data--, pa.Data_plecarii, pa.Ora_plecarii 
		into #ema
		from #c_masini m inner join
			activitati a on m.cod_masina=a.Masina
			inner join elemactivitati e on e.fisa=a.fisa and e.data=a.data
		where Element=@elem_ef
group by a.Data, Masina, Element

create index indx on #ema(data, data_urm, element, id, masina)

update e set data_urm=isnull(ee.Data,'2300-1-1')
	from #ema e left join #ema ee on e.id+1=ee.id and e.Masina=ee.Masina and e.Element=ee.Element
/*--tst
	select * from #ema	--*/
select	isnull((select min(e.Valoare) from #ema e where i.masina=e.masina and e.valoare<>0 and e.Element=@elem_ef and
			(i.data >= e.data and i.data<e.data_urm)),0) as elem_efectiv,
	i.masina, i.den_masina as denumire, i.nr_inmatriculare, i.element,  i.denumire as denumire_elem,
	i.tip, i.fisa, i.data, i.km, i.explicatii--, i.um
from #interventii i order by i.ordonare

IF OBJECT_ID('tempdb..#ema') IS NOT NULL
		drop table #ema
IF OBJECT_ID('tempdb..#interventii') IS NOT NULL
		drop table #interventii
IF OBJECT_ID('tempdb..#c_masini') IS NOT NULL
		drop table #c_masini
