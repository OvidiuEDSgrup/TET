
create procedure wIaStructLM (@sesiune varchar(50), @parXML xml)
as

declare @f_nivel int, @f_denumire varchar(30), @f_lungime int

set	@f_nivel = @parXML.value('(/row/@f_nivel)[1]','int')
set	@f_denumire = @parXML.value('(/row/@f_denumire)[1]','varchar(30)')
set @f_lungime = @parXML.value('(/row/@f_lungime)[1]','int')

select	Nivel as nivel,
		rtrim(Denumire) as denumire,
		Lungime as lungime,
		(case Documente when '1' then 'Da' else 'Nu' end) as documente,
		(case Mijloace_fixe when '1' then 'Da' else 'Nu' end) as mijloacefixe,
		(case Salarii when '1' then 'Da' else 'Nu' end) as salarii,
		(case Costuri when '1' then 'Da' else 'Nu' end) as costuri,
		(case Produse when '1' then 'Da' else 'Nu' end) as produse,
		(case Devize when '1' then 'Da' else 'Nu' end) as devize,
		Documente as doc,
		Mijloace_fixe as mf,
		Salarii as sal,
		Costuri as cost,
		Produse as prod,
		Devize as dev
from strlm
where	(@f_nivel is null or Nivel=@f_nivel)
		and (@f_denumire is null or Denumire like '%' + @f_denumire + '%')
		and (@f_lungime is null or Lungime=@f_lungime)
for xml raw
