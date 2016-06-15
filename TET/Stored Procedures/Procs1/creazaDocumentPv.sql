-- creaza tabela #bonTemp cu structura corecta
create procedure creazaDocumentPv @sesiune varchar(50), @parXML xml output, @tipDoc varchar(2)='AC', @numarDoc int=null, @dataDoc datetime=null, 
	@tert varchar(50)=null, @vanzDoc varchar(50)=null
	
as

declare @msgEroare varchar(500), @idAntetBon int, @CasaDoc int, @uid varchar(50), @cDataStr char(10),
		@GESTPV varchar(20), @oraDoc varchar(6), @comandaASiS varchar(50), @codiinden int, @xml xml, @observatii varchar(500)
set nocount on

begin try
	if @vanzDoc is null 
		exec wIaUtilizator @sesiune=@sesiune, @utilizator=@vanzDoc output
	
	if @vanzDoc is null
		raiserror('Nu am putut identifica utilizatorul de pe document. Fara acesta nu se poate determina gestiunea de vanzare', 16, 1)

	select	@CasaDoc = 7777,
			@uid = newid(),
			@cDataStr = isnull(convert(char(10),@dataDoc,126), convert(char(10),getdate(),126)),
			@oraDoc = '0000',
			@observatii = 'TESTE AUTOMATE'
			
	if @tipDoc='AC'
	begin
		set @numarDoc = isnull((select MAX(a.Numar_bon) 
							from antetbonuri a
							where a.Chitanta=1
							and a.casa_de_marcat=@casaDoc
							and a.Data_bon= @cDataStr),0)+1
	end

	set @parXML='<date><document aplicatie="PV" tip="PV" pentruValidare="1" /></date>'

	set @parXML.modify('insert (
							attribute casamarcat {sql:variable("@CasaDoc")},
							attribute tipdoc {sql:variable("@tipdoc")},
							attribute numarDoc {sql:variable("@numarDoc")},
							attribute data {sql:variable("@cDataStr")},
							attribute vanzator {sql:variable("@vanzDoc")},
							attribute ora {sql:variable("@oraDoc")},
							attribute observatii {sql:variable("@observatii")},
							attribute UID {sql:variable("@uid")}
						) into (/date/document)[1]')
	
	if @tert is not null 
		set @parXML.modify('insert attribute tert {sql:variable("@tert")} into (/date/document)[1]')
	
	if @tipDoc='AP'
	begin
		set @xml = (select '1' nou, 'nume_aici' nume, 'SS' serieCI, 'NNNNNNNNN' numarCI,'ELIB' eliberatCI for xml raw('delegat'))
		set @parXML.modify('insert sql:variable("@xml") as last into (/date/document)[1]')

		set @xml = (select '1' nou, 'descriereloc' descriere, 'adresa' adresa, 'CJ' judet,'CLUJ-NAPOCA' localitate,
						'BANCA' banca, 'contbancalocatie' cont for xml raw('locatie'))
		set @parXML.modify('insert sql:variable("@xml") as last into (/date/document)[1]')

		set @xml = (select 'Masina' idMasina for xml raw('masina'))
		set @parXML.modify('insert sql:variable("@xml") as last into (/date/document)[1]')
	end

end try
begin catch
	set @msgEroare = ERROR_MESSAGE()+' (creazaDocumentPv)'
	raiserror(@msgeroare,11,1)
end catch
