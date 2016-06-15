/* procedura pentru scrierea in doc.detalii a datelor din declaratia Intrastat */
create procedure wOPScriuDateIntrastat @sesiune varchar(50), @parXML xml
as     
declare @tip char(2), @numar varchar(20), @data datetime, 
	@sub char(9),@userASiS varchar(20), @stare int,	@eroare xml, @mesaj varchar(254), 
	@sql_doc nvarchar(max), @sql_update_doc nvarchar(max), @sql_where_doc nvarchar(max), @detalii XML
             
begin try
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
	exec luare_date_par 'GE','SUBPRO',0,0,@sub output

	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
		
	select 
		@sub=subunitate,
		@tip= tip, 
		@numar=numar, 
		@data =data, 
		@detalii=detalii
	from OPENXML(@iDoc, '/parametri')
	WITH 
	(
		subunitate varchar(9) '@subunitate', 
		tip varchar(2) '@tip', 
		numar varchar(20) '@numar',
		data datetime '@data',
		detalii xml 'detalii/row'
	)
	exec sp_xml_removedocument @iDoc 

--	salvare date intrastat in detalii xml din doc
	set @sql_update_doc='detalii=@detalii'
	set @sql_where_doc='WHERE Subunitate=@sub and tip=@tip and numar=@numar and data=@data'
	set @sql_doc=case when @sql_update_doc<>'' then 'UPDATE doc SET '+@sql_update_doc+' '+@sql_where_doc else '' end		
	--print @sql_doc

	if isnull(@sql_doc,'')<>''
		exec sp_executesql @statement=@sql_doc, @params=N'@sub as varchar(9), @tip as varchar(2), @numar as varchar(20), @data datetime, @detalii xml', 
			@sub=@sub, @tip=@tip, @numar=@numar, @data=@data, @detalii=@detalii

--	salvare date intrastat in detalii xml din pozdoc
	exec sp_xml_preparedocument @iDoc output, @parXML
	if object_id('tempdb..#xmlPozIntrastat') is not null drop table #xmlPozIntrastat

	select subunitate, tip, data, numar, numar_pozitie, idpozdoc, convert(decimal(12,2),ISNULL(masaneta,0)) as masaneta
	into #xmlPozIntrastat
	from openxml(@iDoc, '/parametri/DateGrid/row')
	with
	(
		subunitate varchar(9) '@subunitate'
		,tip varchar(2) '@tip'
		,data datetime'@data'
		,numar varchar(20) '@numar'
		,numar_pozitie int '@numar_pozitie'
		,idpozdoc int '@idpozdoc'
		,masaneta float '@masaneta'
	)
	EXEC sp_xml_removedocument @iDoc 	

	update p set detalii='<row/>'
	from pozdoc p
		inner join #xmlPozIntrastat x on x.idpozdoc=p.idpozdoc
	where p.detalii is null

	/*	Modificare valori. */
	update p set detalii.modify ('replace value of (/row/@masaneta)[1] with sql:column("x.masaneta")')
	from pozdoc p
		inner join #xmlPozIntrastat x on x.idpozdoc=p.idpozdoc
	where detalii.value('(/row/@masaneta)[1]','float') is not null

	/*	Inserare valori. */
	update p set detalii.modify ('insert (attribute masaneta {sql:column("x.masaneta")}) into (/row)[1]')
	from pozdoc p
		inner join #xmlPozIntrastat x on x.idpozdoc=p.idpozdoc
	where p.detalii.value('(/row/@masaneta)[1]','float') is null

	select 'Datele pentru intrastat au fost salvate.' as textMesaj, 'Finalizare operatie' as titluMesaj 
		for xml raw, root('Mesaje')
end try
	
begin catch
	set @mesaj = ERROR_MESSAGE()
end catch
	
if LEN(@mesaj)>0
begin		
	exec sp_xml_removedocument @iDoc 
	raiserror(@mesaj, 11, 1)
end		
