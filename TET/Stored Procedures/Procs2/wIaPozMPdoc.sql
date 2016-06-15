--***
create procedure [dbo].[wIaPozMPdoc] @sesiune varchar(50), @parXML xml
as  

declare @iDoc int
exec sp_xml_preparedocument @iDoc output, @parXML

select rtrim(p.subunitate) as subunitate, rtrim(p.tip) as tip,rtrim(p.tip) as subtip, rtrim(p.numar) as numar, 
p.data as data, rtrim(p.gestiune) as gestprod, isnull(rtrim(left( g.denumire_gestiune, 30)), '') as dengestprod, rtrim(p.cod) as cod, rtrim( n.denumire) as denumire, rtrim(p.loc_munca) as lm, rtrim( l.denumire) as denlm, rtrim(p.comanda) as com, rtrim( c.descriere) as dencom, rtrim(p.utilaj) as utilaj, rtrim( m.denumire) as denutilaj, convert(decimal(10, 3), p.de_fabricat) as defabr, 
convert(decimal(10, 3), isnull((select top 1 c.stoc from MPdocpoz c where c.loc_munca=p.loc_munca and c.cod=p.cod and c.utilaj=p.utilaj and c.ordonare<p.ordonare order by c.ordonare desc),0)) as stoci, convert(decimal(10, 3), p.fabricat) as fabr, 
convert(decimal(10, 3), isnull((select top 1 c.stoc from MPdocpoz c where c.loc_munca=p.loc_munca and c.cod=p.cod and c.utilaj=p.utilaj and c.ordonare<p.ordonare order by c.ordonare desc),0)+p.fabricat) as total, convert(decimal(10, 3), p.stoc) as stoc, convert(decimal(10, 3), p.predat) as predat, convert(decimal(10, 3), p.rebut) as rebut, convert(decimal(14, 5), p.pret) as pret, rtrim(p.lot) as lot,
convert(varchar(10),p.data_expirarii,101) as dataexp, p.nr_pozitie as pozitie
FROM MPdocpoz p
cross join OPENXML (@iDoc, '/row')
	WITH
	(
		subunitate char(9) '@subunitate', 
		tip char(2) '@tip', 
		numar char(8) '@numar', 
		data datetime '@data'
	) as dx
inner join nomencl n on ltrim(rtrim(n.cod)) = p.cod 
left outer join gestiuni g on g.cod_gestiune = p.gestiune
left outer join comenzi c on c.comanda= p.comanda
left outer join lm l on l.cod= p.loc_munca
left outer join masini m on m.cod_masina=p.utilaj
WHERE p.subunitate=dx.subunitate and p.tip=dx.tip and p.numar=dx.numar and p.data=dx.data
order by p.nr_pozitie
for xml raw

exec sp_xml_removedocument @iDoc
