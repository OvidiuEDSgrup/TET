--***
create procedure [dbo].[wmScriuCantitate] @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmScriuCantitateSP' and type='P')
begin
	exec wmScriuCantitateSP @sesiune, @parXML 
	return 0
end

set transaction isolation level READ UNCOMMITTED
declare @utilizator varchar(100),@subunitate varchar(9),@tert varchar(20),@data datetime,
		@gestpv varchar(20),@contract varchar(20),@cod varchar(20), @comanda varchar(30), @idPunctLivrare varchar(20)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  
if @utilizator is null 
	return -1

-- identificare tert din par xml
select @tert=f.tert, @idPunctLivrare=f.idPunctLivrare
from dbo.wmfIaDateTertDinXml(@parXML) f

select	@subunitate=rtrim(Val_alfanumerica)
from par where Tip_parametru='GE' and Parametru ='SUBPRO'

set @data=convert(char(10),GETDATE(),101)

select  @contract=isnull(@parXML.value('(/row/@wmIaComenzi.cod)[1]','varchar(20)'),@comanda),
		@cod=isnull(@parXML.value('(/row/@wmDetComenzi.cod)[1]','varchar(20)'),@parXML.value('(/row/@wmDateTerti.cod)[1]','varchar(20)'))

select top 1 @tert=tert,@data=data
from con where Subunitate=@subunitate and tip='BK' and Contract=@contract and Responsabil=@utilizator	

--set @cod=@parXML.value('(/row/@wmDetComenzi.cod)[1]','varchar(20)')
if @cod='<NOU>'
begin
	--Daca se adauga o linie noua trimitem la alegere cod
	if @parXML.value('(/row/@faramesaje)[1]', 'varchar(200)') is not null                  
		set @parXML.modify('replace value of (/row/@faramesaje)[1] with "1"')
	else           
		set @parXML.modify ('insert attribute detalii{"1"} into (/row)[1]') 

	exec wmAlegCod @sesiune,@parXML
	return
end

if @cod='<INC>'
begin
    
	--Se inchide comanda prin schimbarea starii
	update con set Stare='1'
		where Subunitate=@subunitate and tip='BK 'and contract=@contract and Stare='0'

	select 'back(1)' as actiune
	for xml raw,root('Mesaje')
	return
end

select @GESTPV = ISNULL(@GESTPV, dbo.wfProprietateUtilizator('GESTPV',@utilizator))
declare @explicatii varchar(80), @cantitate decimal(12,3),@pret decimal(12,3), @discount decimal(12,2)
set @explicatii=ISNULL(rtrim((select top 1 denumire from terti where tert=@tert)),'')

select	@cantitate=@parXML.value('(/row/@cantitate)[1]','decimal(12,3)'),
		@pret=@parXML.value('(/row/@pret)[1]','decimal(12,3)'),
		@discount=@parXML.value('(/row/@discount)[1]','decimal(12,2)')

update pozcon set Cantitate=(case when @cantitate is null then Cantitate else @cantitate end),
	pret=(case when @pret is null then pret else @pret end), discount=(case when @discount is null then discount else @discount end)
where Subunitate=@subunitate and tip='BK' and tert=@tert and contract=@contract and cod=@cod and data=@data

select 'back' as actiune
for xml raw,Root('Mesaje')
