--***
CREATE procedure [dbo].[wmAlegCantitateComenzi] @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmAlegCantitateComenziSP' and type='P')
begin
	exec wmAlegCantitateComenziSP @sesiune, @parXML 
	return -1
end

set transaction isolation level READ UNCOMMITTED

declare @cod varchar(20)
set @cod=@parXML.value('(/row/@wmDetComenzi.cod)[1]','varchar(20)')

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
	declare @utilizator varchar(255),@subunitate varchar(20),@contract varchar(20)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output
	set @subunitate=RTRIM(@subunitate)
	select @contract=@parXML.value('(/row/@wmIaComenzi.cod)[1]','varchar(20)')

	update con set Stare='1'
		where Subunitate=@subunitate and tip='BK 'and contract=@contract and Stare='0'

	select 'back(1)' as actiune
	for xml raw,root('Mesaje')
	return
end

select 'wmScriuCantitate' as detalii,1 as areSearch
,'D' as tipdetalii,1 as imediat, dbo.f_wmIaForm('MD') form
for xml raw,Root('Mesaje')
