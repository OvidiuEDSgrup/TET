--***
create procedure wOPCursBNR @sesiune varchar(50), @parXML xml 
as    
	declare @valuta_bnr varchar(7), @data_bnr datetime, @curs_bnr float
	 
begin try 
	select
		@valuta_bnr=isnull(@parXML.value('(/row/@valuta)[1]','varchar(7)'),''),
		@data_bnr=isnull(@parXML.value('(/row/@data_bnr)[1]','datetime'),GETDATE())

	set @data_bnr=@data_bnr-1

	declare @dataStr varchar(50)
	set @dataStr=CONVERT(varchar(50), @data_bnr,126)

	declare @xmlInput xml, @xmlOutput xml,@iDoc int
	
	set @xmlInput= (select @dataStr as data,  case when @valuta_bnr='<Toate>' then 'ALL' else @valuta_bnr end as valuta for xml raw)
	
	exec wPreluareCursBNR @sesiune,@xmlInput,@xmlOutput output
	
	--citire date din xml-ul rezultat
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @xmlOutput
	IF OBJECT_ID('tempdb..#xmlCursValute') IS NOT NULL
		drop table #xmlCursValute
	
	select data, isnull(valuta,'') as valuta, isnull(case when valuta='HUF' then curs/100 else curs end,0) as curs
	into #xmlCursValute
	from OPENXML(@iDoc, '/Cursuri/row')
	WITH
	(
		data datetime '@data',
		curs float '@curs',
		valuta varchar(13) '@valuta'
	)
	exec sp_xml_removedocument @iDoc 
		
	update #xmlCursValute set data=data+1
	
	if OBJECT_ID('wOPCursBNRSP1') is not null
		exec wOPCursBNRSP1 @sesiune, @parXML 

	insert into curs(Valuta,Data,Tip,Curs)
	select x.valuta,data,'',curs	
	from #xmlCursValute x
		inner join valuta v on x.valuta=v.Valuta	
	where curs<>0	
		and not exists (select 1 from curs where curs=x.curs and data=x.data)
		
	if not exists(select 1 from #xmlCursValute where curs!=0) and @valuta_bnr<>'<Toate>'
		select 'Actualizare curs valutar nu a reusit! Verificati daca valuta pentru care doriti actualizarea are o codificare standard BNR.' as textMesaj for xml raw, root('Mesaje')	
	else
		select 'Operatia de actualizare curs valutar s-a incheiat cu succes!' as textMesaj for xml raw, root('Mesaje')				
	
	IF OBJECT_ID('tempdb..#xmlCursValute') IS NOT NULL
		drop table #xmlCursValute
	
end try
begin catch
declare @eroare varchar(200) 
	set @eroare='(wOPCursBNR) '+ERROR_MESSAGE()
	raiserror(@eroare, 11, 1) 
end catch
/*
select * from curs
*/
