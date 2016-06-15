-- creaza tabela #bonTemp cu structura corecta
create procedure creazaBonTemp @sesiune varchar(50), @parXML xml
as

declare @msgEroare varchar(500), @idAntetBon int, @tert varchar(50), @CasaDoc int, @vanzDoc varchar(50),@DataDoc datetime, 
		@numarDoc int, @tipDoc varchar(2), @GESTPV varchar(20), @oraDoc varchar(6), @comandaASiS varchar(50), @codiinden int
set nocount on

begin try
	
	if OBJECT_ID('tempdb..#bonTemp') is null
		create table #bonTemp(fakecolumn bit)
		
	alter table #bonTemp 
		add Casa_de_marcat smallint NOT NULL,
			Factura_chitanta bit, 
			Numar_bon int,
			Numar_linie smallint NOT NULL primary key, -- nu dam nume la PK pt. ca uneori apare eroare pt. ca exista
			Data datetime NOT NULL,
			Ora char(6) NOT NULL,
			Tip char(2) NOT NULL,
			Vinzator char(10) NOT NULL,
			Client char(13) NOT NULL,
			Cod_citit_de_la_tastatura char(20) NOT NULL,
			CodPLU char(20) NOT NULL,
			Cod_produs char(20) NOT NULL,
			Categorie smallint NULL,
			UM smallint NOT NULL,
			Cantitate float NOT NULL,
			Cota_TVA real NOT NULL,
			Tva float NOT NULL,
			Pret float NOT NULL,
			Total float NOT NULL,
			Retur bit NOT NULL,
			Inregistrare_valida bit NOT NULL,
			Operat bit NOT NULL,
			Numar_document_incasare char(20) NOT NULL,
			Data_documentului datetime NOT NULL,
			Loc_de_munca char(9) NOT NULL,
			Discount float NOT NULL, 
			lm_real varchar(9) null, 
			Comanda_asis varchar(20) null, 
			[Contract] varchar(20) null, 
			o_pretcatalog float, 
			tipNomencl char(1), 
			cont_de_stoc varchar(50),
			idPozContract int null,
			idCt int null, 
			detalii xml
			
	--alter table #bonTemp add constraint PK_numar_linie primary key(numar_linie)
	
end try
begin catch
	set @msgEroare = ERROR_MESSAGE()+' (creazaBonTemp)'
	raiserror(@msgeroare,11,1)
end catch
