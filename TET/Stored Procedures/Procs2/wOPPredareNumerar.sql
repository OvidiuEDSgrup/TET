--***
create procedure wOPPredareNumerar @sesiune varchar(50), @parXML xml        
as
declare @eroare varchar(500)
begin try
	declare @cont varchar(40),
			@data datetime,
			@suma decimal(20,2),
			@contprim varchar(40),
			@explicatii varchar(50),
			@subunitate varchar(20),
			@numar varchar(20),
			@cont_intermediar varchar(40)

	select	@cont=@parXML.value('(/parametri/@cont)[1]','varchar(40)'),
			@data=@parXML.value('(/parametri/@data)[1]','datetime'),
			@suma=@parXML.value('(/parametri/@suma)[1]','decimal(20,2)'),
			@contprim=@parXML.value('(/parametri/@contprim)[1]','varchar(40)'),
			@explicatii=@parXML.value('(/parametri/@explicatii)[1]','varchar(50)'),
			@numar=@parXML.value('(/parametri/@numar)[1]','varchar(20)')
			
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output
	if exists (select 1 from pozplin p where p.subunitate=@subunitate and p.cont=@cont and p.data=@data and p.Numar=@numar) 
		raiserror ('Exista deja un document cu acest numar!',16,1)
	declare @dataoperarii datetime
	select @dataoperarii=getdate(),@cont_intermediar='581'
	insert into pozplin(Subunitate, Cont, Data, Numar, Plata_incasare, Tert, Factura, Cont_corespondent, Suma, Valuta, Curs, Suma_valuta, Curs_la_valuta_facturii, TVA11, TVA22, Explicatii, Loc_de_munca, Comanda, Utilizator, Data_operarii, Ora_operarii, Numar_pozitie, Cont_dif, Suma_dif, Achit_fact, Jurnal)
	select 
	@subunitate Subunitate, @cont Cont, @data Data, @numar Numar, 'PD' Plata_incasare, 
			'' Tert, '' Factura,  @cont_intermediar Cont_corespondent, @suma Suma, '' Valuta, 0 Curs, 0 Suma_valuta, 0 Curs_la_valuta_facturii, 
			0 TVA11, 0 TVA22, @explicatii Explicatii, '' Loc_de_munca, '' Comanda, dbo.fIaUtilizator(@sesiune) Utilizator, 
			convert(datetime,convert(varchar(10),@dataoperarii,120)) Data_operarii, replace(convert(varchar(10),@dataoperarii,108),':','') Ora_operarii, 
			1 Numar_pozitie, '' Cont_dif, 0 Suma_dif, 0 Achit_fact, ''Jurnal
	--from pozplin
	
	insert into pozplin(Subunitate, Cont, Data, Numar, Plata_incasare, Tert, Factura, Cont_corespondent, Suma, Valuta, Curs, Suma_valuta, Curs_la_valuta_facturii, TVA11, TVA22, Explicatii, Loc_de_munca, Comanda, Utilizator, Data_operarii, Ora_operarii, Numar_pozitie, Cont_dif, Suma_dif, Achit_fact, Jurnal)
	select 
	@subunitate Subunitate, @cont_intermediar Cont, @data Data, @numar Numar, 'ID' Plata_incasare, 
			'' Tert, '' Factura, @contprim Cont_corespondent, @suma Suma, '' Valuta, 0 Curs, 0 Suma_valuta, 0 Curs_la_valuta_facturii, 
			0 TVA11, 0 TVA22, @explicatii Explicatii, '' Loc_de_munca, '' Comanda, dbo.wfIaUtilizator(@sesiune) Utilizator, 
			convert(datetime,convert(varchar(10),@dataoperarii,120)) Data_operarii, replace(convert(varchar(10),@dataoperarii,108),':','') Ora_operarii, 
			1 Numar_pozitie, '' Cont_dif, 0 Suma_dif, 0 Achit_fact, ''Jurnal
			
end try
begin catch
	set @eroare='wOPPredareNumerar (linia'+convert(varchar(20),ERROR_LINE())+'):'+char(10)+ERROR_MESSAGE()
end catch
