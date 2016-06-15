	
create procedure wmScriuAntetDocument @sesiune varchar(50), @parXML xml 
as
if exists(select * from sysobjects where name='wmScriuAntetDocumentSP' and type='P')
begin
	exec wmScriuAntetDocumentSP @sesiune=@sesiune, @parXML=@parXML
	return 0
end
begin try
	declare 
		@gestiune varchar(20), @numar varchar(20),@lm varchar(20), @data datetime, @utilizator varchar(100), @fXML xml, @tip varchar(2),
		@gestiune_primitoare varchar(20), @tert varchar(20), @aviznefacturat bit, @eroare varchar(4000), @cont_coresp varchar(20), 
		@data_facturii datetime, @factura varchar(20), @contract varchar(20), @incurs bit, @cont_factura varchar(20)
	
	
	SELECT 
		@tip=@parXML.value('(/*/@tip)[1]','varchar(2)'),
		@numar=@parXML.value('(/*/@numar)[1]','varchar(20)'),	
		@data=convert(datetime,isnull(@parXML.value('(/*/@data)[1]','varchar(10)'),CONVERT(char(10),getdate(),101))),

		@contract=@parXML.value('(/*/@contract)[1]','varchar(20)'),	
		@gestiune =@parXML.value('(/*/@gestiune)[1]','varchar(20)'),
		@lm=@parXML.value('(/*/@lm)[1]','varchar(20)'),
		@tert=@parXML.value('(/*/@tert)[1]','varchar(20)'),
		@aviznefacturat=@parXML.value('(/*/@tip_aviz)[1]','bit'),
		@gestiune_primitoare=@parXML.value('(/*/@gestiune_primitoare)[1]','varchar(20)'),
		@cont_coresp=@parXML.value('(/*/@contcoresp)[1]','varchar(20)')		,
		@factura=UPPER(@parXML.value('(/*/@factura)[1]','varchar(20)'))	,
		@data_facturii=convert(datetime,isnull(@parXML.value('(/*/@data_factura)[1]','varchar(10)'),CONVERT(char(10),getdate(),101))),
		@cont_factura=isnull(@parXML.value('(/*/@cont_factura)[1]','varchar(20)'),'401')

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

	select @incurs=0
	if exists(select 1 from StariDocumente where inCurs=1)
		select @incurs=1

	if @numar is null
	begin
		set @fXML=(select @tip as tip, @utilizator utilizator, @lm lm  for xml RAW)

		exec wIauNrDocFiscale @parXML=@fXML, @Numar=@numar OUTPUT

		if exists(select 1 from doc where Subunitate='1' and tip=@tip and numar=@numar and data=@data)
			select 'Atentie' titluMesaj, 'Exista deja o receptie cu numarul ' + rtrim(@numar) + '.' textMesaj for xml raw, root('Mesaje')

		INSERT INTO doc(
			Subunitate, Tip, Numar, Cod_gestiune, Data, Cod_tert, Factura, Contractul, Loc_munca, Comanda, Gestiune_primitoare, Valuta, Curs, Valoare,
			Tva_11, Tva_22, Valoare_valuta, Cota_TVA, Discount_p, Discount_suma, Pro_forma, Tip_miscare, Numar_DVI, Cont_factura, Data_facturii,
			Data_scadentei, Jurnal, Numar_pozitii, Stare, detalii )

		select 
			'1', @tip,@numar, isnull(@gestiune,''),@data,isnull(@tert,''),ISNULL(@factura,''),ISNULL(@contract,''),isnull(@lm,''),'',ISNULL(@gestiune_primitoare,''),'',0,0,0,0,0,0,0,0,0,(CASE when @tip in ('PP','RM','AI') then 'I' when @tip in ('AP','AS','TE','CM','AE') then 'E' end),
			'',@cont_factura,@data_facturii,@data_facturii,'',0,0,(select @cont_coresp contcoresp for xml raw)
	end	
	else
	begin
		/* De tratat update si pe pozdoc daca se doreste - de discutat ?
		  momentan nu las modificare antet daca sunt pozitii operate */
		if exists (select * from pozdoc p where Subunitate='1' and tip=@tip and Numar=@numar and data=@data)
			raiserror('Nu se poate modifica antetul daca exista pozitii pe document!', 16, 1)
			
		update doc
			set Cod_gestiune= ISNULL(@gestiune,Cod_gestiune), 
				Cod_tert = ISNULL(@tert, Cod_tert),
				Loc_munca = ISNULL(@lm, Loc_munca),
				Gestiune_primitoare = ISNULL(@gestiune_primitoare, Gestiune_primitoare)
		where Subunitate='1' and tip=@tip and Numar=@numar and data=@data
		and (Cod_gestiune<>@gestiune or Cod_tert<>@tert or Loc_munca<>@lm or Gestiune_primitoare<>@gestiune_primitoare)
	end
	
	if @incurs=1
	begin
		declare @jd_xml xml
		select @jd_xml = (select top 1 @tip as tip, @numar as numar, @data as data, 'Document in curs' as explicatii_stare_jurnal, stare as stare_jurnal from StariDocumente where tipDocument=@tip and isnull(incurs,0)=1 for xml raw('parametri'))
		exec wOPSchimbareStareDocument @sesiune=@sesiune, @parXML=@jd_xml
	end

	select 
		@numar numar, @data data 
	for xml raw('atribute'),root('Mesaje')

	select 'back(1)' as actiune
	for xml raw, ROOT('Mesaje')

end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@mesaj, 16,1)
end catch
