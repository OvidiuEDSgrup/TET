--***
create procedure wIaPozActivitati @sesiune varchar(50),@parXML XML, @rezultatXML xml = '' output
as      

if exists(select * from sysobjects where name='wIaPozActivitatiSP' and type='P')      
	exec wIaPozActivitatiSP @sesiune,@parXML      
else
begin
	declare	@cSub varchar(13), @tip varchar(2), @fisa varchar(10), @data datetime --, @returneazaSelect bit

	select 
		@cSub=ISNULL(@parXML.value('(/row/@cSub)[1]', 'varchar(13)'), ''), 
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'),''),
		@fisa=ISNULL(@parXML.value('(/row/@fisa)[1]', 'varchar(10)'), ''), 
		@data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '01/01/1901')
		--,@returneazaSelect=ISNULL(@parXML.value('(/row/@returneazaSelect)[1]', 'bit'), 0)
		
	if @cSub='' exec luare_date_par 'GE', 'SUBPRO', 0, 0, @cSub output set @cSub=RTRIM(@cSub)
	
	/* formez lista coloane */
	DECLARE @coloane VARCHAR(max), @cTextSelect NVARCHAR(max)
	SELECT @coloane = COALESCE(@coloane,'') 
		+ '	SUM(CASE WHEN element = ' + QUOTENAME(rtrim(element),'''')
		+ ' THEN convert(decimal(10,2),ea.Valoare) ELSE 0 END) AS ' + QUOTENAME(replace(rtrim(element),' ','_')) + ',' + CHAR(10)
		FROM elemactivitati ea where ea.Tip=@tip and ea.Fisa=@fisa and ea.Data=@data group by element
	/* adaug ',' la inceput si daca nu exista nicio linie in elemente si pregatesc @coloane pt select */
	set @coloane = ',' + COALESCE(@coloane, CHAR(10) )
	/*elimin <enter> si ,*/
	set @coloane = substring(@coloane,1,LEN(@coloane)-2) 

	select @cTextSelect = N'select paextins.idPozActivitati, paextins.idActivitati, 
	paextins.tip, (case when paextins.subtip='''' then paextins.tip else paextins.subtip end) subtip, 
	paextins.fisa, paextins.data, paextins.numar_pozitie, max(paextins.traseu) as traseu, 
	max(paextins.den_traseu) as den_traseu, max(paextins.plecare) as plecare, 
	max(rtrim(e.denumire)) as den_element, rtrim(max(paextins.interventie)) as interventie, 
	max(paextins.valoare) as valoare,
	max(paextins.data_plecarii) as data_plecarii, max(paextins.ora_plecarii) as ora_plecarii, 
	max(paextins.date_plecare) as date_plecare, max(paextins.sosire) as sosire, 
	max(paextins.data_sosirii) as data_sosirii, max(paextins.ora_sosirii) as ora_sosirii, max(paextins.date_sosire) as date_sosire, 
	max(paextins.explicatii) as explicatii, max(paextins.comanda_benef) as comanda_benef, max(paextins.den_comanda_benef) as den_comanda_benef, 
	max(paextins.lm_benef) as lm_benef, max(paextins.den_lm_benef) as den_lm_benef, max(paextins.tert) as tert,  
	max(paextins.den_tert) as den_tert, max(paextins.marca) as marca, max(paextins.den_marca) as den_marca'
	+ @coloane
	+ N' from		
	(select pa.idPozActivitati, pa.idActivitati,
	RTRIM(pa.Tip) as tip, rtrim(pa.alfa1) as subtip, RTRIM(pa.Fisa) as fisa, convert(char(10),pa.data,101) as data, 
	pa.Numar_pozitie as numar_pozitie, RTRIM(pa.Traseu) as traseu, rtrim(alfa2) as interventie, 
	convert(decimal(12,2),pa.val1) as valoare,
	isnull(RTRIM(tr.Plecare)+case rtrim(tr.Via) when '''' then '''' else ''-''+RTRIM(tr.via) end+''-''+RTRIM(tr.Sosire),'''') as den_traseu,
	--rtrim(e.denumire) as den_element,
	RTRIM(pa.Plecare) as plecare, CONVERT(char(10),pa.Data_plecarii,101) as data_plecarii,
	substring(pa.Ora_plecarii,1,2)+'':''+substring(pa.Ora_plecarii,3,2) as ora_plecarii,
	RTRIM(pa.Plecare)+'' '' + CONVERT(char(10),pa.Data_plecarii,103)+'' ''+substring(pa.Ora_plecarii,1,2)+'':''+substring(pa.Ora_plecarii,3,2) as date_plecare,
	RTRIM(pa.Sosire) as sosire, CONVERT(char(10),pa.Data_sosirii,101) as data_sosirii,
	substring(pa.Ora_sosirii,1,2)+'':''+substring(pa.Ora_sosirii,3,2) as ora_sosirii, 
	RTRIM(pa.Sosire)+'' ''+ CONVERT(char(10),pa.Data_sosirii,103)+'' '' + substring(pa.Ora_sosirii,1,2)+'':''+substring(pa.Ora_sosirii,3,2) as date_sosire, 
	RTRIM(pa.Explicatii) as explicatii, 
	rtrim(pa.comanda_benef) as comanda_benef, RTRIM(isnull(c.Descriere,'''')) as den_comanda_benef, 
	RTRIM(pa.Lm_beneficiar) as lm_benef, RTRIM(isnull(lm.Denumire,'''')) as den_lm_benef, 
	rtrim(pa.Tert) as tert, RTRIM(isnull(t.Denumire,'''')) as den_tert,
	RTRIM(pa.Marca) as marca, RTRIM(isnull(p.Nume,'''')) as den_marca
	from pozactivitati pa
	left outer join trasee tr on tr.Cod=pa.Traseu
	left outer join comenzi c on c.Subunitate='''+@cSub+''' and pa.Comanda_benef=c.Comanda
	left outer join lm on lm.Cod=pa.Lm_beneficiar
	left outer join terti t on t.Subunitate='''+@cSub+''' and t.Tert=pa.Tert
	left outer join personal p on p.Marca=pa.Marca	
	where pa.Tip ='''+@tip+''' and pa.Fisa='''+@fisa+''' and pa.Data='''+CONVERT(varchar,@data,101)+''' 
	) as paextins
	left outer join elemactivitati ea on ea.Fisa=paextins.Fisa and ea.Tip=paextins.Tip and ea.Data=paextins.Data and ea.Numar_pozitie=paextins.Numar_pozitie
	left outer join elemente e on e.cod=paextins.interventie
	group by paextins.idPozActivitati, paextins.idActivitati,
		paextins.tip, paextins.fisa, paextins.data, paextins.data, paextins.numar_pozitie, paextins.subtip
	
	for xml raw'	
	
begin try
	-- select @cTextSelect for xml path('')
/*	if @returneazaSelect=1
		set @rezultatXML = @cTextSelect
	else*/
		exec (@cTextSelect)
end try
begin catch
	declare @msgEroare varchar(max)
	set @msgEroare = ERROR_MESSAGE()
	select @msgEroare as msgEroare 
	for xml raw

	select 'Select rulat:'+char(10)+char(10)+@cTextSelect
	for xml path('')
end catch
end

