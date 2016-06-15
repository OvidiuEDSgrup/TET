--***
CREATE procedure [dbo].[wmAlegClient] @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmAlegClientSP' and type='P')
begin
	exec wmAlegClientSP @sesiune, @parXML 
	return -1
end

set transaction isolation level READ UNCOMMITTED

declare @procApelanta varchar(50)

set @procApelanta=@parXML.value('(/row/@wmAlegClient.procapelanta)[1]', 'varchar(50)') 

if @parXML.value('(/row/@faradetalii)[1]', 'int') is not null                  
	set @parXML.modify('replace value of (/row/@faradetalii)[1] with 1')                     
else           
	set @parXML.modify ('insert attribute faradetalii{1} into (/row)[1]') 

exec wmIaTerti @sesiune,@parXML

select @procApelanta as detalii,1 as areSearch
for xml raw,Root('Mesaje')
