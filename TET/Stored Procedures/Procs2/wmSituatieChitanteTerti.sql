--***

create procedure [dbo].[wmSituatieChitanteTerti] @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmSituatieChitanteTertiSP' and type='P')
begin
	exec wmSituatieChitanteTertiSP @sesiune, @parXML 
	return 0
end

set transaction isolation level READ UNCOMMITTED  
begin try
	declare @utilizator varchar(100),@subunitate varchar(9), @tert varchar(30), @stareBkFacturabil varchar(20),
			@cont varchar(100), @comanda varchar(100), @eroare varchar(4000), @data datetime,
			@xml xml, @numar varchar(10), @stare varchar(20), @gestiune varchar(20), @lm varchar(20), @numedelegat varchar(80),
			@codFormular varchar(100), @formularIncasare varchar(20),@contPlata varchar(20)

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  

	select top 1 @subunitate=Val_alfanumerica
		from par where tip_parametru='GE' and Parametru='SUBPRO'
	if @subunitate is null
		set @subunitate='1'

	select	@tert=@parXML.value('(/row/@tert)[1]','varchar(20)')
	select @contPlata = rtrim(dbo.wfProprietateUtilizator('CONTPLIN', @utilizator))

	if isnull(@contPlata,'')=''
	begin
		raiserror('Cont casa nu este configurat pentru utilizatorul curent!',11,1)
	end
			
	/* mitz: aici doar un select copiat - de modificat ... */
	select top 100 RTRIM(p.Cont) cont, CONVERT(varchar(10), p.Data, 120) data, RTRIM(p.Numar) numar,
		'Retiparire ch:'+RTRIM(p.numar)+'/'+CONVERT(varchar(10), p.data, 103)+':'+ltrim(str(sum(p.suma),10,2))+' lei' as denumire
	from pozplin p
	where Subunitate=@subunitate and cont=@contPlata
	/*and utilizator=@utilizator */
	and (@tert is null or p.Tert=@tert)
	group by p.cont,p.numar,p.data
	order by data desc
	for xml raw

	select 1 toateAtr, 'refresh' actiune, 'wmTiparesteChitanta' procdetalii
	for xml raw, root('Mesaje')
end try
begin catch
	set @eroare='(wmSituatieChitanteTerti)'+ERROR_MESSAGE() 
	raiserror(@eroare, 16, 1) 
end catch	
