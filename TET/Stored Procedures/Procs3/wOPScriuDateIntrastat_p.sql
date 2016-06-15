--***
create procedure wOPScriuDateIntrastat_p @sesiune varchar(50), @parXML xml 
as  
begin try
	declare  @sub char(9),@tip char(2), @numar varchar(20), @data datetime, @detalii xml, 
		@valfacturata decimal(12,2), @valprestari decimal(12,2), @totalmasaneta decimal(12,2), @nattranza varchar(20), @nattranzb varchar(20), @dennattranzb varchar(300), 
		@taraexp varchar(20), @dentaraexp varchar(100), @userASiS varchar(20), @eroare xml, @mesaj varchar(254), @parXMLNatTranzB xml

--	apel procedura specifica de populare pt. a putea initialiaza anumite elemente
	if exists (select 1 from sys.objects where name='wOPScriuDateIntrastat_pSP' and type='P')  
		exec wOPScriuDateIntrastat_pSP @sesiune, @parXML output

	declare @iDoc int
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

	if object_id('tempdb..#pozitiiDoc') is not null drop table #pozitiiDoc

	select 
		@taraexp=detalii.value('(/detalii/row/@taraexp)[1]','varchar(20)'), 
		@nattranza=detalii.value('(/detalii/row/@nattranza)[1]','varchar(20)'), 
		@nattranzb=detalii.value('(/detalii/row/@nattranzb)[1]','varchar(20)'), 
		@valprestari=isnull(detalii.value('(/detalii/row/@valprestari)[1]','decimal(12,2)'),0),
		@detalii=detalii,
		@numar = ISNULL(numar,''),
		@data = ISNULL(data,''),
		@tip = ISNULL(tip,''),
		@sub = ISNULL(sub,'')
	from OPENXML(@iDoc, '/row') 
	WITH 
	(		
		numar varchar(20) '@numar',
		data datetime '@data',
		tip varchar(2) '@tip',
		sub varchar(9) '@subunitate',
		detalii xml 'detalii'
	)
	exec sp_xml_removedocument @iDoc

	if @numar=''
	begin
		select 'Selectati mai intai documentul pentru care inregistrati datele pt. Intrastat!' AS textMesaj FOR XML RAW, ROOT('Mesaje')
		return -1
	end
	
	--	populare date antet
	set @parXMLNatTranzB=(select 'B' as tip, @nattranza as nattranza  for xml raw)
	select @dennattranzb=denumire from fNaturaTranzactiiIntrastat (@parXMLNatTranzB) where cod=@nattranzb
	select @dentaraexp=denumire from tari where cod_tara=@taraexp

	select @valfacturata=sum(p.cantitate*(case when p.tip='RM' then p.pret_valuta*(case when p.Valuta<>'' then p.curs else 1 end)*(1+p.Discount/100) else p.pret_vanzare end)) 
	from pozdoc p
		left outer join nomencl n on n.Cod=p.Cod
	where p.subunitate=@sub and p.tip=@tip and p.numar=@numar and p.data=@data and n.Tip not in ('S','R')

	if @valprestari=0 and @tip='RM'
		select @valprestari=sum(pret_valuta) 
		from pozdoc
		where subunitate=@sub and tip='RP' and numar=@numar and data=@data and Gestiune_primitoare='' and Cont_factura not like '446%'

	--	populare date pozitii
	select rtrim(p.subunitate) as subunitate, p.tip as tip, convert(char(10),p.data,101) as data, rtrim(p.numar) as numar
		,p.Numar_pozitie as numar_pozitie, p.idpozdoc
		,rtrim(p.cod) as cod
		,rtrim(p.gestiune) as gestiune
		,rtrim(p.Cod_intrare) AS cod_intrare
		,convert(decimal(17,5),p.Cantitate) as cantitate
		,convert(decimal(17,5), p.pret_vanzare) AS pvanzare
	into #pozitiiDoc
	from pozdoc p 
	where p.Subunitate=@sub AND p.tip=@tip AND p.data=@data AND p.Numar=@numar

	alter table #pozitiiDoc add tara varchar(50)

	if exists (select 1 from syscolumns sc, sysobjects so where so.id = sc.id and so.name = 'pozdoc' and sc.name = 'detalii')
	begin
		alter table #pozitiiDoc add detalii xml;
			
		update #pozitiiDoc
		set detalii = pd.detalii, tara=pd.detalii.value('/row[1]/@taraorigine', 'varchar(50)')
		from pozdoc pd
		where #pozitiiDoc.idpozdoc = pd.idpozdoc
	end

	select @totalmasaneta=sum(round(convert(decimal(12,3),(case when isnull(p.detalii.value('/row[1]/@masaneta', 'float'),0)<>0 
				then isnull(p.detalii.value('/row[1]/@masaneta', 'float'),0) else p.cantitate*n.greutate_specifica end)),2))
	from #pozitiiDoc p
		left join nomencl n on n.Cod=p.Cod

	select convert(decimal(12,2),@valfacturata) as valbunuri, convert(decimal(12,2),@valprestari) as detalii_valprestari, convert(decimal(12,2),@valfacturata+@valprestari) as valstatistica, 
		@totalmasaneta as totalmasaneta, 
		(case when @nattranza is null then 1 end) as detalii_nattranza, 
		(case when @nattranzb is null then 1 end) as detalii_nattranzb, @dennattranzb as dennattranzb, @dentaraexp as dentaraexp
	for xml raw, ROOT('Date')

	select 
		(select p.subunitate, p.tip, p.data, p.numar, p.numar_pozitie, p.idpozdoc, p.gestiune, p.cod_intrare, p.pvanzare
			,p.cod, rtrim(n.Denumire) as dencod, cantitate
			,round(convert(decimal(12,2),(case when isnull(p.detalii.value('/row[1]/@masaneta', 'float'),0)<>0 
				then isnull(p.detalii.value('/row[1]/@masaneta', 'float'),0) else p.cantitate*n.greutate_specifica end)),2) as masaneta
			,isnull(nullif(p.detalii.value('/row[1]/@codvama','varchar(20)'),''),isnull(nullif(n.detalii.value('/row[1]/@codvama','varchar(20)'),''),substring(n.tip_echipament,2,20))) as codvama
			,rtrim(cv.denumire) as dencodvama
			,rtrim(tari.denumire) as dentaraorigine
			FROM #pozitiiDoc p
				left join nomencl n on n.Cod=p.Cod
				left join codvama cv on cv.Cod=isnull(nullif(p.detalii.value('/row[1]/@codvama','varchar(20)'),''),isnull(nullif(n.detalii.value('/row[1]/@codvama','varchar(20)'),''),substring(n.tip_echipament,2,20)))
				left join tari on tari.cod_tara=isnull(nullif(p.tara,''),isnull(n.detalii.value('/row[1]/@tara', 'varchar(50)'),''))
		FOR XML	RAW, TYPE)  
	FOR XML PATH('DateGrid'), ROOT('Mesaje')
end try	

begin catch
	set @mesaj = ERROR_MESSAGE()+' (wOPScriuDateIntrastat_p)'
	raiserror(@mesaj, 11, 1)	
end catch
