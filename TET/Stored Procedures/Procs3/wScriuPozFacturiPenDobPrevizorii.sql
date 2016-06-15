--***
/****** Object:  StoredProcedure [dbo].[wStergPozFacturiPenDobPrevizorii]    Script Date: 01/05/2011 23:08:45 ******/
create procedure  wScriuPozFacturiPenDobPrevizorii  @sesiune varchar(50), @parXML xml
as
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozFacturiPenDobPrevizoriiSP')
begin 
	declare @returnValue int 
	exec @returnValue = wScriuPozFacturiPenDobPrevizoriiSP @sesiune, @parXML output
	return @returnValue
end
DECLARE @tip varchar(2),@subtip varchar(2),@mesajeroare varchar(100),@factura varchar(20),@tert varchar(13),@data_penalizarii datetime,@factura_penalizata varchar(20),
	@datajos datetime,@datasus datetime,@validare int,@suma_penalizare float,@tip_doc_pen varchar(2),@tip_doc_incasare varchar(2),@nr_doc_incasare varchar(20),
	@data_doc_incasare datetime,@utilizator varchar(20)
begin try      
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	select
		@tip=isnull(@parXML.value('(/row/@tip)[1]','varchar(2)'),''),
		@tip_doc_pen=isnull(@parXML.value('(/row/row/@tip_doc_pen)[1]','varchar(2)'),''),
		@tip_doc_incasare=isnull(@parXML.value('(/row/row/@tip_doc_incasare)[1]','varchar(2)'),''),
		@subtip=isnull(@parXML.value('(/row/row/@subtip)[1]','varchar(2)'),''),
		@tert=isnull(@parXML.value('(/row/@tert)[1]','varchar(13)'),''),
		@factura=isnull(@parXML.value('(/row/row/@factura)[1]','varchar(20)'),''),
		@nr_doc_incasare=isnull(@parXML.value('(/row/row/@nr_doc_incasare)[1]','varchar(20)'),''),
		@validare=isnull(@parXML.value('(/row/row/@validare)[1]','int'),''),
		@factura_penalizata=isnull(@parXML.value('(/row/row/@factura_penalizata)[1]','varchar(20)'),''),
		@data_penalizarii=isnull(@parXML.value('(/row/row/@data_penalizare)[1]','datetime'),''),
		@data_doc_incasare=isnull(@parXML.value('(/row/row/@data_doc_incasare)[1]','datetime'),''),
		@datajos = isnull(@parXML.value('(/row/@datajos)[1]','datetime'),'1901-01-01'),
		@datasus = isnull(@parXML.value('(/row/@datasus)[1]','datetime'),'2099-01-01')
         
	update penalizarifact set valid=@validare--1-valida->se factureaza, 0-anulata->nu se va factura
	where tip=@tip_doc_pen
		and tert=@tert
		and Factura=@factura 
		and Factura_penalizata=@factura_penalizata
		and Tip_doc_incasare=@tip_doc_incasare
		and Nr_doc_incasare=@nr_doc_incasare
		and Data_doc_incasare=@data_doc_incasare
		and Data_penalizare=@data_penalizarii
	
	declare @docXML xml
	set @docXML='<row tert="'+rtrim(@tert)+'" tip="'+@tip+'" datajos="'+convert(char(10),@datajos,101)+'" datasus="'+convert(char(10),@datasus,101)+'"/>'
	exec wIaPozFacturiPenDobProvizorii @sesiune=@sesiune, @parXML=@docXML
end try
begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)	
end catch
--select * from penalizarifact
--sp_help penalizarifact
