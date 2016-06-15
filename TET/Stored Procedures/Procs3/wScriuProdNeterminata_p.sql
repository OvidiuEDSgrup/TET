
create procedure wScriuProdNeterminata_p @sesiune varchar(50), @parXML xml
as
declare @subtip varchar(2)

set @subtip = @parXML.value('(/*/@subtip)[1]','varchar(20)')

if @subtip='AD'--daca suntem pe adaugare
	select	--convert(varchar(10),getdate(),101) as data,
		'' as lm, '' as denlm, 	'' as comanda, '' dencomanda,
		0 as procent, 0 as cantitate,
		'adaugare' operatiune
	for xml raw
else
	select	'modificare' operatiune
	for xml raw

	
