create procedure wOPModificareSumaTVA_p @sesiune varchar(50), @parXML xml
as
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPModificareSumaTVA_pSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPModificareSumaTVA_pSP @sesiune, @parXML
	return @returnValue
end

begin try
	declare @tert varchar(30), @numar varchar(30), @data datetime, @tip varchar(2), 
	@sumaTVA float, @cotatva decimal(5,2), @stare int, @cod varchar(40), 
	@dencod varchar(60), @dentert varchar(50),@pamanunt decimal(12,2)
	select @tert=@parXML.value('(/row/@tert)[1]','varchar(30)'),
		@numar=@parXML.value('(/row/@numar)[1]','varchar(30)'),
		@data=@parXML.value('(/row/@data)[1]','datetime'),
		@tip=@parXML.value('(/row/@tip)[1]','varchar(2)'),
		@cotatva=@parXML.value('(/row/@cotatva)[1]','decimal(5,2)'),
		@sumaTVA=@parXML.value('(/row/@sumaTVA)[1]','float'),
		@cod=isnull(@parXML.value('(/row/row/@cod)[1]','varchar(30)'),'')

	if @cod=''
	begin
		select 'wOPModificareSumaTVA_p:Operatia de modificare Suma TVA valabila pentru pozitiile documentului!,selectati un cod pentru modificare Suma TVA!' as textMesaj for xml raw, root('Mesaje')
		return -1
	end  
	select @numar=numar, @tert=Tert, @tip=tip, @sumaTVA=tva_deductibil, @cotatva=Cota_TVA,@pamanunt=pret_cu_amanuntul from pozdoc 
		where tip=@tip and tert=@tert and numar=@numar and data=@data and cod=@cod
	
	set @dencod=(select denumire from nomencl where cod=@cod)
	set @dentert=(select denumire from terti where tert=@tert)
	select @numar numar , @tert tert, @dentert dentert, convert(varchar(30),@data,101) data, 
		@tip tip, convert(decimal(12,2),@sumaTVA) sumaTVA, convert(decimal(5,2),@cotatva) cotatva,
		@cod cod, @dencod dencod,@pamanunt pamanunt
	for xml raw
end try 

begin catch
	declare @error varchar(500)
	set @error=ERROR_MESSAGE()
	raiserror(@error,16,1)
end catch
