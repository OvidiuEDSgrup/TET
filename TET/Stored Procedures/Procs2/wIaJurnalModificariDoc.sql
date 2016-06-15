
create procedure wIaJurnalModificariDoc @sesiune varchar(50), @parXML XML
as

declare
	@tip varchar(2), @numar varchar(20), @data datetime, @doc xml

select
	@tip = @parXML.value('(/row/@tip)[1]','varchar(2)'),
	@numar = @parXML.value('(/row/@numar)[1]','varchar(20)'),
	@data = @parXML.value('(/row/@data)[1]','datetime')

if object_id('tempdb..#sysdoc') is not null
	drop table #sysdoc

select
	cod, aplicatia, utilizator, data_mod, ora_mod, data_ant, ora_ant, utilizator_ant, sursa, culoare, nr_poz
into #sysdoc
from (
	select
		rtrim(cod) as cod,
		convert(varchar(100),null) as aplicatia,
		rtrim(isnull(nullif(utilizator,''),'sa')) as utilizator,
		convert(varchar(10),data_operarii,103) as data_mod,
		substring(ora_operarii,1,2) + ':' + substring(ora_operarii,3,2) + ':' +substring(ora_operarii,5,2) as ora_mod,
		convert(varchar(10), '') as data_ant,
		convert(varchar(10), null) as ora_ant,
		convert(varchar(100), null) as utilizator_ant,
		1 as sursa,
		'#000000' as culoare,
		numar_pozitie as nr_poz
	from pozdoc
	where subunitate='1' and tip=@tip and numar=@numar and data=@data
	union all
	select
		rtrim(s.cod) as cod,
		rtrim(s.aplicatia) as aplicatia,
		rtrim(isnull(nullif(s.stergator,''),'sa')) as utilizator,
		convert(varchar(10),s.data_stergerii,103) as data_mod,
		replicate('0',2-len(convert(varchar(2),datepart(hh,s.data_stergerii)))) + convert(varchar(2),datepart(hh,s.data_stergerii)) + ':' + 
		replicate('0',2-len(convert(varchar(2),datepart(mi,s.data_stergerii)))) + convert(varchar(2),datepart(mi,s.data_stergerii)) + ':' + 
		replicate('0',2-len(convert(varchar(2),datepart(ss,s.data_stergerii)))) + convert(varchar(2),datepart(ss,s.data_stergerii)) as ora_mod,
		convert(varchar(10),s.data_operarii,103) as data_ant,
		substring(s.ora_operarii,1,2) + ':' + substring(s.ora_operarii,3,2) + ':' +substring(s.ora_operarii,5,2) as ora_ant,
		rtrim(isnull(nullif(s.utilizator,''),'sa')) as utilizator_ant,
		2 as sursa,
		'#808080' as culoare,
		s.numar_pozitie as nr_poz
	from sysspd s
	inner join pozdoc p on p.subunitate=s.subunitate and p.tip=s.tip and p.data=s.data and p.numar_pozitie=s.numar_pozitie
	where s.subunitate='1' and s.tip=@tip and s.numar=@numar and s.data=@data
	union all
	select
		rtrim(s.cod) as cod,
		rtrim(s.aplicatia) as aplicatia,
		rtrim(isnull(nullif(s.stergator,''),'sa')) as utilizator,
		convert(varchar(10),s.data_stergerii,103) as data_mod,
		replicate('0',2-len(convert(varchar(2),datepart(hh,s.data_stergerii)))) + convert(varchar(2),datepart(hh,s.data_stergerii)) + ':' + 
		replicate('0',2-len(convert(varchar(2),datepart(mi,s.data_stergerii)))) + convert(varchar(2),datepart(mi,s.data_stergerii)) + ':' + 
		replicate('0',2-len(convert(varchar(2),datepart(ss,s.data_stergerii)))) + convert(varchar(2),datepart(ss,s.data_stergerii)) as ora_mod,
		convert(varchar(10),s.data_operarii,103) as data_ant,
		substring(s.ora_operarii,1,2) + ':' + substring(s.ora_operarii,3,2) + ':' +substring(s.ora_operarii,5,2) as ora_ant,
		rtrim(isnull(nullif(s.utilizator,''),'sa')) as utilizator_ant,
		3 as sursa,
		'#FF0000' as culoare,
		s.numar_pozitie as nr_poz
	from sysspd s
	where s.subunitate='1' and tip=@tip and numar=@numar and data=@data 
		and not exists(select 1 from pozdoc p where p.subunitate=s.subunitate and p.numar=s.numar and p.data=s.data and p.numar_pozitie=s.numar_pozitie)
) x

select @doc = 
(
	select
		max(cod) as cod, max(aplicatia) as aplicatia, max(utilizator) as utilizator, max(data_mod) as data_modificarii, max(ora_mod) as ora_modificarii,
		max(data_ant) as data_mod_ant, max(ora_ant) as ora_mod_ant, max(utilizator_ant) as utilizator_ant, max(culoare) as culoare,
		(select
			cod, aplicatia, utilizator, data_mod data_modificarii, ora_mod ora_modificarii, data_ant data_mod_ant, ora_ant ora_mod_ant, utilizator_ant, culoare
		from #sysdoc sd
		where sd.nr_poz=s.nr_poz and sd.sursa=2
		order by data_modificarii desc, ora_modificarii desc
		for xml raw, type)
	from #sysdoc s
	where sursa in (1,3)
	group by nr_poz, sursa
	order by sursa, cod
	for xml raw, root('Ierarhie')
)

select @doc for xml path('Date')
