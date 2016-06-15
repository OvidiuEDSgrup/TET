
CREATE PROCEDURE wmAdaugTert @sesiune varchar(50), @parXML xml
as
begin try
	declare
		@cui varchar(20), @xmltert xml, @searchText varchar(200), @ws xml


	select
		@cui = NULLIF(@parXML.value('(/row/@codfiscal_i)[1]','varchar(20)'),'')

	IF @cui IS NULL
		raiserror('Nu s-a introdus codul fiscal pentru tert!',15,1)
		
	select @ws = convert(xml,SUBSTRING(dbo.httpget('http://openapi.ro/api/companies/'+RTRIM(@cui)+'.xml'),39, 999999))
	
	select 
		t.d.value('(//cif/text())[1]','varchar(200)') codfiscal,
		t.d.value('(//cif/text())[1]','varchar(200)') tert,
		t.d.value('(//city/text())[1]','varchar(200)') localitate,
		t.d.value('(//phone/text())[1]','varchar(200)') telefonfax,
		t.d.value('(//address/text())[1]','varchar(200)') adresa,	
		t.d.value('(//name/text())[1]','varchar(200)') dentert,
		t.d.value('(//registration-id/text())[1]','varchar(200)') nr_ord_reg,
		t.d.value('(//zip/text())[1]','varchar(200)') codpostal,
		t.d.value('(//state/text())[1]','varchar(200)') judet,
		(case ISNULL(t.d.value('(//vat/text())[1]','int'),0) when 1 then 'P' else 'N' end) tiptva,
		'RO' tara	
	INTO #mtert
	from @ws.nodes('/hash') t(d)	
	
	set @xmltert = (select * from #mtert for xml raw, type)
	exec wScriuTerti @sesiune=@sesiune, @parXML=@xmltert	
	
	select top 1 @searchText = RTRIM(DENUMIRE) from terti where cod_fiscal=@cui
	select @cui tertExact for xml raw('atribute'), root('Mesaje')
	select 'back(1)' actiune for xml raw, root('Mesaje')

end try
begin catch
	declare @mesaj varchar(400)
	set @mesaj = error_message() + ' ('+object_name(@@procid)+')'
	raiserror (@mesaj, 11, 1)
end catch
