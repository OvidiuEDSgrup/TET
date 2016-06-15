--***
create procedure [dbo].[wIaCosturiComenzi] @sesiune varchar(30), @parXML XML
as
declare @sub varchar(9), @com varchar(20)

exec luare_date_par 'GE','SUBPRO',1,0,@sub OUTPUT
set @com = @parXML.value('(/row/@comanda)[1]','varchar(20)')

SELECT convert(char(10),c.Data_lunii,101) as data, 
	rtrim(c.loc_de_munca) as lm, 
	rtrim(c.tip_inregistrare) as tipinreg, 
	rtrim(c.Articol_de_calculatie) as artcalc, 
	rtrim(a.denumire) as denartcalc, 
	convert(decimal(12,2),c.valoare) as valoare,
	rtrim(left(c.Comanda_sursa,20)) as sursa
FROM cost c 
Left join artcalc a on a.Articol_de_calculatie=c.Articol_de_calculatie
WHERE c.Subunitate = @sub and c.Comanda = @com 
order by c.Data_lunii desc
for xml raw
