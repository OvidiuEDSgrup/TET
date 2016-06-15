--***
create procedure rapComparativaCombustibili(@DataJos datetime,@DataSus datetime,@locm varchar(20)=null, @masina varchar(20)=null,
		@tip_masina varchar(20)=null, @GrupaMasina varchar(20)=null, @combustibil varchar(1)='X', @marca varchar(20)=null)
as
declare @eroare varchar(1000)
set @eroare=''
if object_id('tempdb.dbo.#elemt') is not null drop table #elemt
if object_id('tempdb.dbo.#combustibili') is not null drop table #combustibili
begin try
	set transaction isolation level read uncommitted
	set @combustibil=isnull(@combustibil,'X')
	select element,max(rtrim(left(et.element,len(et.element)-(case when et.tip_masina='Auto' then 0 else 1 end)))) as element_tip 
			, tip_masina into #elemt from elemtipm et 
	where (tip_masina=@tip_masina or @tip_masina is null)
			group by element,tip_masina
	declare @luna_prec datetime, @ultimaZiLuna datetime
	select @luna_prec=dateadd(M,-1,dateadd(d,1-day(@datajos),@DataJos)), 
			@ultimaZiLuna=dateadd(d,1-day(dateadd(M,1,@DataSus)),dateadd(M,1,@DataSus))

	create table #combustibili(cod_masina varchar(100), nume_masina varchar(200), nr_inmatriculare varchar(50), element varchar(100), valoare decimal(20,3),
					numar_document varchar(20), numar_pozitie varchar(20), tip varchar(5), denumire_element varchar(100),
					loc_de_munca varchar(20), numelm varchar(100), data datetime, n int)
	
	insert into #combustibili(cod_masina, nume_masina, nr_inmatriculare, element, valoare,
					numar_document, numar_pozitie, tip, denumire_element, loc_de_munca, numelm, data, n)
	select max(m.cod_masina) cod_masina, max(m.denumire) as nume_masina, 
		m.nr_inmatriculare as nr_inmatriculare, lower(et.element_tip) as element, sum(ea.Valoare) Valoare,
		a.Fisa as Numar_document, max(ea.Numar_pozitie) Numar_pozitie,max(a.Tip) Tip,
		(case et.element_tip when 'AlimComb' then 'Alimentare '
			  else 'Consum ' end)+max(a.tip)
		--e.Denumire
		as denumire_element, a.loc_de_munca,max(lm.denumire) as numelm,a.data,count(1) as nr
		--e.*
	-->	elemente propriu-zise
	from masini m inner join #elemt et on m.tip_masina=et.tip_masina
	inner join elemente e on et.element=e.cod 
	left outer join activitati a on a.masina=m.cod_masina
	left outer join elemactivitati ea on ea.tip=a.tip and ea.fisa=a.fisa and ea.data=a.data and ea.element=et.element 
	left join lm on lm.cod=a.loc_de_munca
	where et.element_tip in ('AlimComb', 'ConsComb', 'ConsEf'/*, 'TotalAlim', 'KmEf','RestEst'*/
				, 'RestEst', 'KmEf'
				) and 
		(ea.data between @luna_prec and @ultimaZiLuna)
		and (@locm is null or m.loc_de_munca like @locm+'%')
		and (@masina is null or m.cod_masina=@masina)
		and (@combustibil='X' or m.benzina_sau_motorina=@combustibil)
		and (@GrupaMasina is null or m.grupa=@GrupaMasina)
		and ea.valoare<>0
		and (@marca is null or a.marca=@marca)
	group by a.fisa, a.data, m.nr_inmatriculare, a.Loc_de_munca, et.element_tip
	union all
	select max(substring(p.Comanda,2,40)), max(m.denumire) as nume_masina, m.nr_inmatriculare as nr_inmatriculare, 
			'conspozdoc' as element, 
			sum(p.cantitate) Valoare,
		p.Numar,max(p.Numar_pozitie) Numar_pozitie, max(p.Tip) Tip, 'Document consum' as denumire_element,
		p.Loc_de_munca,max(lm.denumire) as numelm,p.data, count(1)
	--> element "fabricat" din consumurile inregistrate in pozdoc
	from masini m inner join pozdoc p on m.cod_masina=substring(p.Comanda,2,40)
		inner join nomencl n on p.cod=n.cod
		inner join grupe g on g.Grupa=n.Grupa
		left join lm on lm.cod=p.Loc_de_munca
	where left(p.comanda,1) in ('A','U')
		and p.Cont_de_stoc like '3022%'
		and (p.data between @luna_prec and @ultimaZiLuna)
		and (@locm is null or p.loc_de_munca like @locm+'%')
		and (@masina is null or substring(p.Comanda,2,40)=@masina)
		and (@combustibil='X' or m.benzina_sau_motorina=@combustibil)
		and (@GrupaMasina is null or m.grupa=@GrupaMasina)
		and p.Cantitate<>0
		and g.Denumire in ('motorina','benzina','petrol')
		and exists( select 1 from activitati a where a.masina=m.cod_masina and (@marca is null or a.marca=@marca))
		--*/
	group by p.numar, p.Data, m.nr_inmatriculare, p.Loc_de_munca
	
	select cod_masina, nume_masina, nr_inmatriculare, element, valoare,
					numar_document, numar_pozitie, tip, denumire_element, loc_de_munca, numelm, data
		from #combustibili c
		where c.data between @DataJos and @DataSus
	union all	--> rest estimat precedent pe luni
	select cod_masina, nume_masina, nr_inmatriculare, 'restestprecluna' element, valoare,
					numar_document, numar_pozitie, tip, denumire_element, loc_de_munca, numelm,
					dateadd(M,1,data) as data
		from #combustibili c
		where --dateadd(M,1,data) 
		data between @luna_prec and @DataSus and element='RestEst' and dateadd(d,-day(data),data)<dateadd(d,-day(@DataSus),@DataSus)
			and not exists (
				select 1 from #combustibili cc where year(cc.data)=year(c.data) 
						and month(cc.data)=month(c.data) and c.nr_inmatriculare=cc.nr_inmatriculare
						and cc.element=c.element and cc.data>c.data
			)
	union all	--> rest estimat precedent pe masini
		select cod_masina, nume_masina, nr_inmatriculare, 'restestprecmasina' element, valoare,
					numar_document, numar_pozitie, tip, denumire_element, loc_de_munca, numelm,
					dateadd(M,1,data) as data
		from #combustibili c
		where --dateadd(M,1,data) 
		data between @luna_prec and @DataSus and element='RestEst' and dateadd(d,-day(data),data)<dateadd(d,-day(@DataSus),@DataSus)
			and not exists (
				select 1 from #combustibili cc where 
					--year(cc.data)=year(c.data) and month(cc.data)=month(c.data) and 
						c.nr_inmatriculare=cc.nr_inmatriculare
						and dateadd(d,-day(cc.data),cc.data)<dateadd(d,-day(@DataSus),@DataSus)
						and cc.element=c.element and cc.data>c.data
			)
	union all	--> rest estimat pe luni
	select cod_masina, nume_masina, nr_inmatriculare, 'restestluna' element, valoare,
					numar_document, numar_pozitie, tip, denumire_element, loc_de_munca, numelm,
					data as data
		from #combustibili c
		where --dateadd(M,1,data) 
		data between dateadd(M,1,@luna_prec) and @ultimaZiLuna and element='RestEst' 
			and dateadd(d,1-day(data),data)<@ultimaZiLuna
			--and dateadd(d,-day(data),data)<dateadd(d,-day(@DataSus),@DataSus)
			and not exists (
				select 1 from #combustibili cc where year(cc.data)=year(c.data) 
						and month(cc.data)=month(c.data) and c.nr_inmatriculare=cc.nr_inmatriculare
						and cc.element=c.element and cc.data>c.data
			)
	union all	--> rest estimat pe masini
		select cod_masina, nume_masina, nr_inmatriculare, 'restestmasina' element, valoare,
					numar_document, numar_pozitie, tip, denumire_element, loc_de_munca, numelm,
					data as data
		from #combustibili c
		where --dateadd(M,1,data) 
		 data between dateadd(M,1,@luna_prec) and @ultimaZiLuna and element='RestEst' and --c.valoare<>0 and
			dateadd(d,1-day(data),data)<@ultimaZiLuna
			--c.data<@DataSus
			and not exists (
				select 1 from #combustibili cc where 
					--year(cc.data)=year(c.data) and month(cc.data)=month(c.data) and 
						c.nr_inmatriculare=cc.nr_inmatriculare
						and dateadd(d,-day(cc.data),cc.data)=dateadd(d,-day(@DataSus),@DataSus)
							--cc.data<@DataSus --and cc.valoare<>0
						and cc.element=c.element and cc.data>c.data
			)
	order by loc_de_munca, cod_masina, data, numar_document--, ea.numar_pozitie
	drop table #elemt
end try
begin catch
	set @eroare='rapComparativaCombustibili: '+char(10)+ERROR_MESSAGE()
end catch

if object_id('tempdb.dbo.#elemt') is not null drop table #elemt
if object_id('tempdb.dbo.#combustibili') is not null drop table #combustibili
if len(@eroare)>0 raiserror(@eroare,16,1)
