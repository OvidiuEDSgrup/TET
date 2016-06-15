--***

create procedure [dbo].[wmTiparesteChitanta] @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmTiparesteChitantaSP' and type='P')
begin
	exec wmTiparesteChitantaSP @sesiune, @parXML 
	return 0
end

set transaction isolation level READ UNCOMMITTED  
begin try
	declare @utilizator varchar(100),@subunitate varchar(9), @tert varchar(30), @stareBkFacturabil varchar(20),
			@cont varchar(100), @comanda varchar(100), @eroare varchar(4000), @data datetime,
			@xml xml, @numar varchar(10), @stare varchar(20), @gestiune varchar(20), @lm varchar(20), @numedelegat varchar(80),
			@codFormular varchar(100), @formularIncasare varchar(20)

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  

	select	@cont=@parXML.value('(/row/@cont)[1]','varchar(20)'),
			@data=isnull(@parXML.value('(/row/@data)[1]','datetime'),GETDATE()),
			@numar=@parXML.value('(/row/@numar)[1]','varchar(20)'),
			@tert=@parXML.value('(/row/@tert)[1]','varchar(20)')
			
	select @formularIncasare = rtrim(dbo.wfProprietateUtilizator('FORMPLIN', @utilizator))
	
	-- daca formularul nu contine '/', generez fisier cu wTipFormular; alfel consider ca e formular-raport 
	if charindex('/',@formularIncasare)=0
	begin
		set @xml=
			(select '1' subunitate, 'IB' tip, CONVERT(varchar(30),@numar) numar, convert(varchar(10), @data,120) data, 
				@tert tert, @formularIncasare nrform for xml raw)
		exec wTipFormular @sesiune=@sesiune,@parXML=@xml
	end
	else -- incerc generare din Raport.
	begin	
		set @xml = (select @numar+'.pdf' numeFisier, @formularIncasare caleRaport, DB_NAME() BD, @cont cont,
			'IB' tip, @numar numar, convert(varchar(10), @data,120) data, '2' nrExemplare for xml raw)
		exec wExportaRaport @sesiune=@sesiune, @parXML=@xml
	end
end try
begin catch
	set @eroare='(wmTiparesteChitanta)'+ERROR_MESSAGE() 
	raiserror(@eroare, 16, 1) 
end catch	


