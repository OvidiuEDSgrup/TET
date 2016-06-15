
Create procedure wOPGenerareCompensariFacturi_p @sesiune varchar(50), @parXML xml
as

select
	'1' as gencomp, '1' as stergcomp
for xml raw, root('Date')
