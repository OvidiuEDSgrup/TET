
create procedure wOPVerif_D394 @sesiune varchar(50), @parXML xml
as

declare
	@an int, @luna int, @tipdecl varchar(1), @init xml

select
	@an = @parXML.value('(/parametri/@an)[1]','int'),
	@luna = @parXML.value('(/parametri/@luna)[1]','int'),
	@tipdecl = @parXML.value('(/parametri/@tipdecl)[1]','varchar(1)')

select
	@init = (select @an as an, @luna as luna, @tipdecl as tipdecl for xml raw)

select 'Verificare D394 - Jurnal TVA' nume, 'DCONT' codmeniu, 'YM' as tip, 'VD' as subtip, 'O' tipmacheta, 
	 (select @init) dateInitializare
for xml raw('deschideMacheta'), root('Mesaje')
