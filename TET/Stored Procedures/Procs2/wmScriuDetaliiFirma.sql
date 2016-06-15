/* 
proc. apelata cand se apasa butonul accept in macheta cu detalii firma. 
practic nu permitem modificarea informatiilor, ci doar consultarea lor.
*/
CREATE procedure wmScriuDetaliiFirma @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmScriuDetaliiFirmaSP' and type='P')
begin
	exec wmScriuDetaliiFirmaSP @sesiune, @parXML 
	return -1
end

select 'Informatiile nu pot fi modificate' as textMesaj
for xml raw, root('Mesaje')

select 'back(1)' as actiune
for xml raw, root('Mesaje')
