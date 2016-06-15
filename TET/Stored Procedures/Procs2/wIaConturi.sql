
create procedure wIaConturi @sesiune varchar(50), @parXML XML
	as
	declare 
		@subunitate varchar(9), @filtruCont varchar(40), @filtruDenumire varchar(80), @filtruTipCont char(1),
		@txtFiltruAtribuire varchar(100),@filtruAtribuire int, @filtruAnRulaje varchar(20), @an int, @areDetalii bit,
		@filtruindicator varchar(20), @areanalitice varchar(2),@filtrusursaf varchar(20)
	
	select @subunitate=val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO'

	select 
		@filtruCont = isnull(@parXML.value('(/row/@cont)[1]', 'varchar(40)'), ''),
		@filtruDenumire = isnull(@parXML.value('(/row/@dencont)[1]', 'varchar(80)'), ''),
		@filtruTipCont = isnull(@parXML.value('(/row/@tipcont)[1]', 'varchar(1)'), ''),
		@filtruAnRulaje = isnull(@parXML.value('(/row/@anrulaje)[1]', 'varchar(20)'), ''),
		@txtfiltruAtribuire = isnull(@parXML.value('(/row/@atribuire)[1]', 'varchar(20)'), ''),
		@filtruindicator = @parXML.value('(/row/@indicator)[1]', 'varchar(20)'),
		@filtrusursaf = isnull(@parXML.value('(/row/@sursaf)[1]', 'varchar(20)'), ''),  
		@areanalitice = isnull(@parXML.value('(/row/@areanalitice)[1]', 'varchar(2)'), '')  

	select
		@filtruAtribuire=(case when ISNUMERIC(@txtFiltruAtribuire)>0 and CONVERT(float,@txtFiltruAtribuire) between 0 and 100 then round(CONVERT(float,@txtFiltruAtribuire),0) else -1 end),
		@an=(case when ISNUMERIC(@filtruAnRulaje)>0 then round(CONVERT(float,@filtruAnRulaje),0) else null end),
		@filtruDenumire = replace(@filtruDenumire,' ','%')


	select top 100 
		rtrim(Cont) as cont, rtrim(Denumire_cont) as dencont,tip_cont as tipcont, rtrim(case tip_cont when 'A' then 'Activ' when 'P' then 'Pasiv' else 'Bifunctional' end) as dentipcont,
		rtrim(cont_parinte) as parinte,(case when Are_analitice=1 then 'Da' else 'Nu' end) as denareanalitice,Apare_in_balanta_sintetica as apareinbalsint	,c.Are_analitice areanalitice,
		(case when c.Sold_debit=1 then 1 else 0 end) as apareinbalrap,@an as anrulaje,(case when sold_credit between 0 and 100 then convert(int,round(sold_credit,0)) else 0 end) as atribuire, 
		dbo.denAtribuireConturi(sold_credit) as denatribuire,nivel,rtrim(c.articol_de_calculatie) as artcalc, rtrim(isnull(artcalc.denumire, '')) as denartcalc,
		(case when rtrim(pr.Valoare)='D' then 1 else 0 end) invaluta,(case when isnull(rtrim(pr.Valoare),'')='D' then 'Da' else '' end) deninvaluta,
		rtrim(pr.valoare) valuta, c.detalii detalii, rtrim(ib.denumire) denindicator,
		(CASE WHEN GETDATE() BETWEEN c.detalii.value('(/row/@data_invalid_jos)[1]', 'datetime')
			AND c.detalii.value('(/row/@data_invalid_sus)[1]', 'datetime') THEN '#808080' END) AS culoare
	from conturi c
	left join indbug ib on ib.indbug=c.detalii.value('(/*/@indicator)[1]','varchar(20)')
	left join artcalc on artcalc.articol_de_calculatie=c.articol_de_calculatie
	left outer join proprietati pr on pr.tip='CONT' AND Cod_proprietate='INVALUTA' and cod=c.Cont
	where 
		subunitate=@subunitate 
		and cont like rtrim(@filtruCont)+'%' 
		and denumire_cont like '%'+rtrim(@filtruDenumire)+'%' 
		and (@filtruTipCont='' or tip_cont=@filtruTipCont) 
		and (@filtruAtribuire<0 or sold_credit=@filtruAtribuire) 
		and (dbo.denAtribuireConturi(sold_credit) like @txtfiltruAtribuire+'%' or isnull(@txtfiltruAtribuire,'')='' or @filtruAtribuire>=0)
		and (@areanalitice='' or are_analitice=@areanalitice)
		and (@filtrusursaf='' or c.detalii.value('(/*/@sursaf)[1]','varchar(1)')=@filtrusursaf)
		and (@filtruindicator is null --	fara filtrare
			or @filtruindicator=' ' and nullif(c.detalii.value('(/*/@indicator)[1]','varchar(20)'),'') is null -- conturi cu indicator necompletat
			or @filtruindicator<>' ' and c.detalii.value('(/*/@indicator)[1]','varchar(20)') like '%'+rtrim(@filtruindicator)+'%') -- conturi cu indicator completat

	order by cont
	for xml raw, root('Date')

	select 1 as areDetaliiXml
	for xml raw,root('Mesaje')
