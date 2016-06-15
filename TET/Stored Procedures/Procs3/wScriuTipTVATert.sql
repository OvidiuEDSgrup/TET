create procedure wScriuTipTVATert @sesiune varchar(50), @parXML xml
as
begin try
	declare 
		@tert varchar(20), @tip_tva varchar(1), @data_inceput datetime, @mesaj varchar(max), @update bit, @id_tva_pe_tert int

	set @tert=@parXML.value('(/*/@tert)[1]','varchar(20)')
	set @data_inceput=@parXML.value('(/*/*/@data_inceput)[1]','datetime')
	set @tip_tva=@parXML.value('(/*/*/@cod_tip_tva)[1]','varchar(1)')
	set @update=isnull(@parXML.value('(/*/*/@update)[1]','bit'),0)
	set @id_tva_pe_tert=@parXML.value('(/*/*/@id_tva_pe_tert)[1]','int')

	if @tert is null	
		raiserror('Tertul nu s-a receptionat corespunzator',11,1)
	if @data_inceput is null
		raiserror('Data completata nu este corepunzatoare',11,1)
	if @tip_tva is null
		raiserror('Tipul de TVA completat trebuie sa aiba una din valorile: Neplatitor, Platitor , Incasare',11,1)

	if @update=0
		insert into TvaPeTerti (Tert,tipf,dela,tip_tva,factura)
			select  @tert, 'F',@data_inceput, @tip_tva, null
	else
		if @update=1
			update TvaPeTerti set dela=@data_inceput, tip_tva= @tip_tva
			where idTvaPeTert=@id_tva_pe_tert and tipf='F'
end try
begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (wScriuTipTVATert)'
	raiserror(@mesaj, 11, 1)
end catch
