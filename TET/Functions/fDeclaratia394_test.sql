create function [dbo].[fDeclaratia394_test] (@sesiune varchar(20)='', @datajos datetime, @datasus datetime)
	returns @raport table(codtert varchar(50), codfisc varchar(50), dentert varchar(200), tipop varchar(1), baza decimal(15,3), tva decimal(15,3), cod varchar(20), denumirecod varchar(80))
--select @datajos='2012-1-1', @datasus='2012-1-31'
as
begin

	declare @proprietateNomenclatorCoduriCereale varchar(100), @coduriCereale varchar(3000),	-->	coduri de nomenclatura combinata pt cereale si plante tehnice
			@parXML xml
	select	@proprietateNomenclatorCoduriCereale='CODNOMENCLATURA',
			@coduriCereale='10011000,10019010,10019091,10019099,10020000,100300,1005,120100,1205,120600,121291',
			@parXML=(select @datajos datajos, @datasus datasus, 1 as pecoduri for xml raw)
				
	declare @tCoduriCereale table(cod varchar(20), codNomenclatura varchar(20))
	insert into @tCoduriCereale (cod, codNomenclatura)
	select cod, valoare as codNomenclatura from proprietati where
		tip='NOMENCL'
		and charindex(','+rtrim(valoare)+',',','+@coduriCereale+',')>0
		and cod_proprietate=@proprietateNomenclatorCoduriCereale
    
	--select * into #raport from dbo.rapTVApecoduri(@datajos, @datasus, 1)
	insert into @raport(codtert, codfisc, dentert, tipop, baza, tva, cod, denumirecod)
	select max(rtrim(codtert)) codtert, rtrim(d.codfisc) codfisc, max(rtrim(d.dentert)) dentert,
			(case	when d.invers=1 and d.tipop='L' then 'V'
					when d.invers=1 and d.tipop='A' then 'C' else d.tipop end) tipop
		,convert(decimal(15,3),sum(d.baza)) baza, convert(decimal(15,3),sum(d.tva)) tva
		,''--,rtrim(isnull(c.codNomenclatura,'')) as cod		--> pentru acest cod de nomenclator s-a separat rapTVAInform in rapTVApecoduri si rapTVAInform
		,max(rtrim(n.Denumire)) as denumirecod
	 from dbo.frapTVApecoduri(@parXML) d
		left join @tCoduriCereale c on d.codNomenclator=c.cod
		left join nomencl n on n.Cod=d.codNomenclator
		group by codfisc, (case	when d.invers=1 and tipop='L' then 'V'
							when d.invers=1 and tipop='A' then 'C' else tipop end),
					rtrim(isnull(c.codNomenclatura,''))
	order by 4,3,7

	delete @raport where abs(baza)<0.01 and abs(tva)<0.01

	return
	/*	-- stil vechi:
	select *  from dbo.rapTVAInform(':1', ':2')

	update ##rtva:3
	set baza=round(convert(decimal(15,3), baza), 0),
	 tva=round(convert(decimal(15,3), tva), 0)

	delete ##rtva:3 where abs(baza)<0.01 and abs(tva)<0.01

	*/
	--not(ix)
end