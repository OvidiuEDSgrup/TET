
create procedure wIaTipuriDocumentePersonal @sesiune varchar(30), @parXML XML
as

declare
	@f_tipdoc varchar(100), @f_valabil_inf int, @f_valabil_sup int, @f_functie varchar(30)

select
	@f_tipdoc = @parXML.value('(/row/@f_tipdoc)[1]','varchar(100)'),
	@f_valabil_inf = isnull(@parXML.value('(/row/@f_valabil_inf)[1]','int'),-99999),
	@f_valabil_sup = isnull(@parXML.value('(/row/@f_valabil_sup)[1]','int'),999999),
	@f_functie = @parXML.value('(/row/@f_functie)[1]','varchar(30)')

select top 100
	t.idTipDocument,
	t.cod_functie,
	rtrim(t.tip) as tipdoc,
	t.valabilitate_standard,
	rtrim(t.descriere) as descriere,
	rtrim(f.Denumire) as functie
from TipuriDocumentePersonal t
left join Functii f on f.Cod_functie=t.cod_functie
where (@f_tipdoc is null or t.tip like '%' + @f_tipdoc + '%')
	and (t.valabilitate_standard between @f_valabil_inf and @f_valabil_sup)
	and (@f_functie is null or f.Denumire like '%' + @f_functie + '%')
order by t.tip,f.Denumire
for xml raw
