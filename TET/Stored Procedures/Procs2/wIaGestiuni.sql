
create procedure wIaGestiuni @sesiune varchar(50), @parXML xml
as
begin try
	declare @subunitate varchar(9), @filtruGestiune varchar(9), @filtruDenumire varchar(30), @filtruTipGestiune char(1),
		@filtruTert varchar(13), @filtruDenTert varchar(80), @filtruCont varchar(40), @filtruDenCont varchar(80), @areDetalii bit

	select @subunitate = rtrim(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'

	select 
		@filtruGestiune = isnull(@parXML.value('(/row/@gestiune)[1]', 'varchar(9)'), ''),
		@filtruDenumire = isnull(@parXML.value('(/row/@denumire)[1]', 'varchar(30)'), ''),
		@filtruTipGestiune = isnull(@parXML.value('(/row/@tipgestiune)[1]', 'varchar(1)'), ''),
		@filtruTert = isnull(@parXML.value('(/row/@tert)[1]', 'varchar(13)'), ''),
		@filtruDenTert = isnull(@parXML.value('(/row/@dentert)[1]', 'varchar(80)'), ''),
		@filtruCont = isnull(@parXML.value('(/row/@cont)[1]', 'varchar(40)'), ''),
		@filtruDenCont = isnull(@parXML.value('(/row/@dencont)[1]', 'varchar(80)'), '')

	if OBJECT_ID('tempdb..#wGest') is not null
		drop table #wGest
		
	select @filtruDenumire = replace(@filtruDenumire,' ','%'),
		@filtruDenTert = replace(@filtruDenTert, ' ', '%'),
		@filtruDenCont = replace(@filtruDenCont, ' ', '%')

	select 
		rtrim(g.Cod_gestiune) as gestiune, rtrim(left(g.Denumire_gestiune,30)) as dengestiune, 
		rtrim(g.Tip_gestiune) as tipgestiune, dbo.denTipGestiune(g.tip_gestiune) as dentipgestiune, 
		rtrim(g.Cont_contabil_specific) as cont, rtrim(isnull(c.denumire_cont, '')) as dencont,
		isnull(g.detalii.value('(/row/@lm)[1]', 'varchar(20)') + ' - ' + g.detalii.value('(row/@denlm)[1]', 'varchar(150)'), '') as denlm,
		(CASE WHEN GETDATE() BETWEEN g.detalii.value('(/row/@data_invalid_jos)[1]', 'datetime')
			AND g.detalii.value('(/row/@data_invalid_sus)[1]', 'datetime') THEN '#808080' END) AS culoare,
		g.detalii as detalii, RTRIM(cp.Categorie) AS categpret, RTRIM(cp.Denumire) AS dencategpret
	from gestiuni g
		left join conturi c on c.subunitate=g.subunitate and c.cont=g.cont_contabil_specific
		left join proprietati pr on pr.Tip = 'GESTIUNE' and pr.Cod = g.Cod_gestiune and pr.Cod_proprietate = 'CATEGPRET'
		left join categpret cp on cp.Categorie = pr.Valoare
	where g.subunitate=@subunitate
		and g.cod_gestiune like rtrim(@filtruGestiune) + '%'
		and g.denumire_gestiune like '%' + rtrim(@filtruDenumire) + '%'
		and (@filtruTipGestiune='' or g.tip_gestiune=@filtruTipGestiune)
		and isnull(g.detalii.value('(/row/@tert)[1]', 'varchar(13)'), '') like '%' + @filtruTert + '%'
		and isnull(g.detalii.value('(/row/@dentert)[1]', 'varchar(80)'), '') like '%' + @filtruDenTert + '%'
		and g.cont_contabil_specific like rtrim(@filtruCont)+'%'
		and isnull(c.denumire_cont, '') like '%' + @filtruDenCont + '%'
	order by 1
	for XML raw, root('Date')
	
	select '1' as areDetaliiXml for xml raw, root('Mesaje')

end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16,1)
end catch	
