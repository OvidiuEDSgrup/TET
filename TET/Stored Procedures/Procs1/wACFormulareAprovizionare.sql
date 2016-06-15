
create procedure wACFormulareAprovizionare @sesiune varchar(50), @parXML xml
as

select
	rtrim(Numar_formular) as cod,
	rtrim(Denumire_formular) as denumire
from antform 
where denumire_formular like '%aprovizionare%'
order by numar_formular
for xml raw
