--***
create procedure wStergBon @sesiune varchar(50), @parXML xml
as 
declare @nr_casa int, @data datetime, @nr_bon int
set nocount on

select	@nr_casa = @parXML.value('(/row/@casaM)[1]', 'int'),
		@data = @parXML.value('(/row/@data)[1]', 'datetime'),
		@nr_bon = @parXML.value('(/row/@nrBon)[1]', 'int')

if not exists (SELECT * FROM sys.objects WHERE name='bonuriSterse' AND type = 'U')
select top 0 * into bonuriSterse from bt

	insert into bonuriSterse(Casa_de_marcat,Factura_chitanta,Numar_bon,Numar_linie,Data,Ora,Tip,Vinzator,Client,Cod_citit_de_la_tastatura,
	CodPLU,Cod_produs,Categorie,UM,Cantitate,Cota_TVA,Tva,Pret,Total,Retur,Inregistrare_valida,Operat,Numar_document_incasare,Data_documentului,Loc_de_munca,Discount)
	select Casa_de_marcat,Factura_chitanta,Numar_bon,Numar_linie,Data,Ora,Tip,Vinzator,Client,Cod_citit_de_la_tastatura,
	CodPLU,Cod_produs,Categorie,UM,Cantitate,Cota_TVA,Tva,Pret,Total,Retur,Inregistrare_valida,Operat,Numar_document_incasare,Data_documentului,Loc_de_munca,Discount from bt where Casa_de_marcat=@nr_casa and data=@data and Numar_bon=@nr_bon

delete from bt where bt.Casa_de_marcat=@nr_casa and bt.data=@data and bt.Numar_bon=@nr_bon
