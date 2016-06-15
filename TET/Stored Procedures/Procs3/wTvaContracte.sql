
CREATE PROCEDURE wTvaContracte @sesiune VARCHAR(50)=null, @parXML XML=null
/**
	Procedura care trateaza formula de calcul pentru tva pe contracte
	- pentru a avea toate intr-un loc iau restul datelor de pozitii (cantitatea si valoarea) tot de aici;
	- campurile care au legatura cu TVA sunt valoarePV si totalcutva
*/
as

if object_id('tempdb..#diezpozcontracte') is null
begin
	create table #diezpozcontracte (idpozcontract int)
	exec wTvaContracte_tabela
end

update d set cantitate=p.cantitate, valoare=p.cantitate * (pret*(1.00-ISNULL(p.discount,0)/100.00)),
		valoarePV=round(p.cantitate*round(pret*(1.00-ISNULL(p.discount,0)/100.00)*(1+convert(float,n.cota_tva)/100),2)/(1+convert(float,n.cota_tva)/100),2),
		totalcutva=p.cantitate * (pret*(1.00-ISNULL(p.discount,0)/100.00))*(1+convert(float,
			isnull(p.detalii.value('(row/@cota_tva)[1]','float'),
			--coalesce(nullif(p.detalii.value('(row/@cota_tva)[1]','float'),0),
				(case when c.data<'2016-1-1' and n.cota_tva=20 then 24 else n.cota_tva end)
			)	--> ?: @cotatva_ante_2016 - metoda de a altera tva-ul in functie de an
		)/100)--*/
		,idcontract=p.idcontract
		,cota_tva=isnull(p.detalii.value('(row/@cota_tva)[1]','float'),
				(case when c.data<'2016-1-1' and n.cota_tva=20 then 24 else n.cota_tva end))
from #diezpozcontracte d inner join pozcontracte p on d.idpozcontract=p.idpozcontract
	inner join contracte c on p.idcontract=c.idcontract
	left join nomencl n on p.cod=n.cod
	
--insert into #diezpozcontracte(idcontract, cantitate, pret, discount, cota_tva, detalii_cota_tva, valoare)