
CREATE PROCEDURE wOPSchimbareStareComandaProductie @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	declare 
		@comanda varchar(20), @stare varchar(10), @explicatii varchar(100), @idLansare int, @doc_jurnal xml

	/* 
		Un SP care nu inlocuieste, permitand diverse actiuni: 
			Exemplu: notificari in baza anumitor stari, alte actualizari, etc
	*/
	IF EXISTS (select 1 from sysobjects where name='wOPSchimbareStareComandaProductieSP')
		exec wOPSchimbareStareComandaProductieSP @sesiune=@sesiune, @parXML=@parXML

	select 
		@comanda=@parXML.value('(/*/@comanda)[1]','varchar(20)'),
		@stare=@parXML.value('(/*/@stare)[1]','varchar(1)'),
		@idLansare=@parXML.value('(/*/@idLansare)[1]','int'),
		@explicatii=@parXML.value('(/*/@explicatii)[1]','varchar(200)')

	IF ISNULL(@explicatii,'')=''
		raiserror('Operatia este jurnalizata, este necesara completarea campului de explicatii!',15,1)
	
	set @doc_jurnal= (select @idLansare idComanda, @stare stare, GETDATE() data, @explicatii explicatii for xml raw, type)
	exec wScriuJurnalComenzi @sesiune=@sesiune, @parXML=@doc_jurnal
	
	update top(1) Comenzi set Starea_comenzii=@stare where comanda=@comanda

END TRY
BEGIN CATCH
	declare @eroare varchar(1000)
	set @eroare=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@eroare, 15, 1)
end catch
