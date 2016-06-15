--***
create procedure rapVanzariPV (@ordonare int, @datajos datetime, @datasus datetime, @gestiunea varchar(100), @tipvanzari int, @tip_nomenclator varchar(1),
								@tip_document int,	--> 0=toate, 1=Bonuri, 2=Facturi, 3=Consumuri
								@casa_de_marcat varchar(100), @vanzator varchar(100), @orajos varchar(10)=null, @orasus varchar(10)=null,
								@consum varchar(100)=null)
as
set transaction isolation level read uncommitted
declare @userASiS varchar(10), @lista_gestiuni bit, @vinzator varchar(30) 
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_NAME()),'')
set @lista_gestiuni=(case when exists (select 1 from proprietati where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate='GESTIUNE' and valoare<>'') then 1 else 0 end)

--> formatare filtre pentru interval orar:
	select	@orajos=rtrim(isnull(@orajos,'000000')),
			@orasus=rtrim(isnull(@orasus,'240000'))
	select	@orajos=(case when len(@orajos)=1 or charindex(':',@orajos)=2 then '0'+@orajos else @orajos end),
			@orasus=(case when len(@orasus)=1 or charindex(':',@orasus)=2 then '0'+@orasus else @orasus end)

	select	@orajos=rtrim(case when @orajos like '%:%' then replace(@orajos,':','')
						--when @orajos like '%,%' then
						else @orajos end),
			@orasus=rtrim(case when @orasus like '%:%' then replace(@orasus,':','')
						--when @orasus like '%,%' then
						else @orasus end)

	select @orajos=@orajos+replicate('0',6-len(@orajos)), @orasus=@orasus+replicate('0',6-len(@orasus))
	declare @tip_document_tradus int
	select @tip_document_tradus=(case when @tip_document<>0 then @tip_document else 0 end)

select bp.casa_de_marcat,rtrim(bp.vinzator) vinzator,bp.numar_bon, 
--convert(char(12),bp.data,104) 
	bp.data as data, rtrim(bp.cod_produs) cod_produs, rtrim(n.denumire) as denumire, bp.cantitate, round(bp.pret,2) as pret, round(bp.total,2) as total, round(bp.tva,2) as tva, 
	convert(varchar(1000),(case	when @ordonare=0 then convert(varchar(12),bp.data,102)+space(8-len(bp.numar_bon))+ltrim(convert(varchar(8), bp.numar_bon))
			when @ordonare=1 then space(20-len(ltrim(rtrim(bp.cod_produs))))+rtrim(ltrim(bp.cod_produs))
		else n.denumire end)) as ord, rtrim(bp.loc_de_munca) as gestiune, rtrim(g.Denumire_gestiune) as denumireGestiune,
	left(rtrim(bp.Ora)+replicate('0',6-len(bp.ora)),4) ora
from bp 
	left outer join nomencl n on bp.cod_produs=n.cod
	left outer join proprietati gu on gu.valoare=bp.Loc_de_munca and gu.tip='UTILIZATOR' and gu.cod=@userASiS and gu.cod_proprietate='GESTIUNE'
	left join gestiuni g on g.Cod_gestiune=bp.Loc_de_munca
where bp.tip='21' and bp.data between @datajos and @datasus 
	and (@gestiunea is null or bp.loc_de_munca=rtrim(@gestiunea))
	and (@tipvanzari=0 or @tipvanzari=1 and isnull(n.tip, '') not in ('R', 'S') or @tipvanzari=2 and isnull(n.tip, '') in ('R', 'S'))
	and (@tip_nomenclator='T' or isnull(n.tip, '')=@tip_nomenclator)
	and (@tip_document=0 or bp.factura_chitanta=@tip_document_tradus)
	and (@casa_de_marcat is null or bp.casa_de_marcat=@casa_de_marcat)
	and (@vanzator is null or bp.vinzator=@vanzator)
	and (@lista_gestiuni=0 or gu.valoare is not null)
	and (bp.ora between left(@orajos, len(bp.ora)) and left(@orasus, len(bp.ora)))
order by bp.loc_de_munca, ord, bp.data, bp.numar_bon
