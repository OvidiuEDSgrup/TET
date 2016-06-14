SELECT pozcon.cod
,convert(char(15),convert(money,round(sum(pozcon.pret*(1-pozcon.Discount/100)*(1-pozcon.DiscDoi/100)*(1-pozcon.DiscTrei/100)*pozcon.cantitate),2)),1)
,convert(char(15),convert(money,round(sum(sum(round(convert(decimal(17,5),pozcon.cantitate*pozcon.pret*(1-pozcon.Discount/100)*(1-pozcon.DiscDoi/100)*(1-pozcon.DiscTrei/100)),2 ))) OVER(partition by pozcon.contract),2)),1)
,max(pozcon.pret*(1-pozcon.Discount/100)*(1-pozcon.DiscDoi/100)*(1-pozcon.DiscTrei/100)*pozcon.CursValuta)
,convert(char(15),convert(money,round(sum(convert(decimal(17,5),pozcon.pret*(1-pozcon.Discount/100)*(1-pozcon.DiscDoi/100)*(1-pozcon.DiscTrei/100)*pozcon.CursValuta)*pozcon.cantitate),2)),1)
,convert(char(15),convert(money,round(sum(sum(round(convert(decimal(17,5),pozcon.cantitate*pozcon.pret*(1-pozcon.Discount/100)*(1-pozcon.DiscDoi/100)*(1-pozcon.DiscTrei/100)*pozcon.cursValuta),2 ))) OVER (partition by pozcon.contract) ,2)),1)
FROM avnefac JOIN con ON avnefac.subunitate=con.subunitate and avnefac.tip=con.tip and avnefac.contractul=con.contract and avnefac.cod_tert=con.tert and avnefac.data=con.data JOIN yso.pozconexp pozcon ON pozcon.subunitate=con.subunitate and pozcon.tip=con.tip and pozcon.contract=con.contract and pozcon.data=con.data and pozcon.tert=con.tert LEFT JOIN terti ON terti.subunitate=con.subunitate and terti.tert=con.tert LEFT JOIN nomencl ON nomencl.cod=pozcon.cod and nomencl.cod=pozcon.cod 
WHERE pozcon.Listare='' AND AVNEFAC.TERMINAL='5960'
GROUP BY avnefac.tip, avnefac.numar, avnefac.data, pozcon.cod,con.loc_de_munca, POZCON.TERT, POZCON.CONTRACT
--HAVING pozcon.Cod='200-R160212'

SELECT pozdoc.cod
,convert(char(20),convert(money,round(sum(pozdoc.cantitate*pozdoc.Pret_valuta),2)),1)
,convert(char(15),convert(money,round((select sum(round(convert(decimal(17,5),p.cantitate*p.Pret_valuta),2 )) from pozdoc p where p.subunitate= max(pozdoc.subunitate) and p.tip= max(pozdoc.tip) and p.numar= max(pozdoc.numar) and p.data= max(pozdoc.data) /*and av.cod_gestiune=p.gestiune*/),2)),1)
,convert(char(20),convert(money,round(sum(pozdoc.cantitate*pozdoc.pret_vanzare),2)),1)
,convert(char(15),convert(money,round((select sum(round(convert(decimal(17,5),p.cantitate*p.pret_vanzare),2 )) from pozdoc p where p.subunitate= max(pozdoc.subunitate) and p.tip= max(pozdoc.tip) and p.numar= max(pozdoc.numar) and p.data= max(pozdoc.data) /*and av.cod_gestiune=p.gestiune*/),2)),1)
FROM pozdoc left join avnefac on pozdoc.subunitate=avnefac.subunitate and pozdoc.tip=avnefac.tip and pozdoc.numar=avnefac.numar and avnefac.data=pozdoc.data left join doc on pozdoc.subunitate=doc.subunitate and pozdoc.tip=doc.tip and pozdoc.numar=doc.numar and pozdoc.data=doc.data left join terti on pozdoc.subunitate=terti.subunitate and pozdoc.tert=terti.tert left join infotert on pozdoc.subunitate=infotert.subunitate and pozdoc.tert=infotert.tert and doc.Gestiune_primitoare=infotert.identificator left join nomencl on pozdoc.cod=nomencl.cod left join anexafac on anexafac.subunitate=pozdoc.subunitate and anexafac.numar_factura=pozdoc.factura 
WHERE 1=1 AND AVNEFAC.TERMINAL='5960' and pozdoc.Cod='200-R160212'
GROUP BY  pozdoc.cod, pozdoc.pret_vanzare, pozdoc.pret_valuta, avnefac.cod_gestiune, pozdoc.tert, pozdoc.numar, pozdoc.data

select * from pozcon p where p.contract='1032441             ' and p.Cod='200-R160212'
select * from pozdoc p where p.Tip='AP' 
--and p.contract='1032441'
and p.Numar='116639              ' and p.Cod='200-R160212' 
select ROUND(2.11000495,5)
select ROW_NUMBER() over(partition by formular order by formular)
 ,* from formular
 where formular in ('FACTXML','proforma')
 --order by formular, rand, pozitie
-- insert avnefactmp
select *
--into avnefactmp
from avnefac where AVNEFAC.TERMINAL='932' 
-- delete avnefac where AVNEFAC.TERMINAL='5960'  insert avnefac select * from avnefactmp
-- update avnefactmp set terminal='5960'

select * 
--into tet..formular_proforma
from formular f --inner join test..formular ft on ft.formular=f.formular and ft.rand=f.rand and ft.pozitie=f.pozitie
 where f.formular like 'proforma%' and f.expresie like '%pozcon.pret%'

select f.* 
from formular f inner join test..formular ft on ft.formular=f.formular and ft.rand=f.rand and ft.pozitie=f.pozitie
 where f.formular like 'proforma%' and f.expresie like '%pozcon.pret%'
 
 --update f
-- set expresie=ft.expresie
--from formular f inner join test..formular ft on ft.formular=f.formular and ft.rand=f.rand and ft.pozitie=f.pozitie
-- where f.formular like 'proforma%' and f.expresie like '%convert(decimal(17,2)%'

-- update f
-- set expresie=ft.expresie
-- -- select f.*
--from formular f inner join test..formular ft on ft.formular=f.formular and ft.rand=f.rand and ft.pozitie=f.pozitie
-- where f.formular like 'proforma%' and f.expresie like '%pozcon.pret%'
 
SELECT pozdoc.subunitate ,max(gestiuni.tip_gestiune),max(pozdoc.gestiune),max(pozdoc.cod),max(pozdoc.cod_intrare) 
,(select MAX(s.locatie) from stocuri s where s.subunitate=pozdoc.subunitate and s.tip_gestiune=max(gestiuni.tip_gestiune) and s.cod_gestiune=max(pozdoc.gestiune) and s.cod=max(pozdoc.cod) and s.cod_intrare=max(pozdoc.cod_intrare)) as C007
FROM pozdoc INNER JOIN yso.predariPacheteTmp pp ON pp.Subunitate=pozdoc.Subunitate AND pp.tip=pozdoc.tip AND pp.Numar=pozdoc.Numar AND pp.Data=pozdoc.Data and pp.numar_pozitie=pozdoc.numar_pozitie INNER JOIN avnefac ON avnefac.Terminal=pp.Terminal AND avnefac.Subunitate=pozdoc.Subunitate AND avnefac.Tip='AP' AND avnefac.Data=pp.DataAviz AND avnefac.Numar=pp.NumarAviz /*AND avnefac.Cod_gestiune='' AND avnefac.Contractul=''*/ INNER JOIN nomencl ON nomencl.Cod=pozdoc.Cod LEFT JOIN con on con.Subunitate=pozdoc.Subunitate and con.Tip='BK' and con.Contract=pp.Contract and con.tert=pp.tert LEFT JOIN pozcon on pozcon.Subunitate=con.Subunitate and pozcon.Tip=con.Tip and pozcon.Contract=con.Contract and pozcon.Tert=pp.Tert and pozcon.Cod=pp.CodPachet LEFT JOIN lm on pozdoc.Loc_de_munca=lm.cod LEFT JOIN gestiuni on gestiuni.subunitate=pozdoc.subunitate and gestiuni.cod_gestiune=pozdoc.gestiune WHERE 1=1 AND AVNEFAC.TERMINAL='5960' GROUP BY pozdoc.subunitate, pozdoc.barcod, pozdoc.cod, pozdoc.pret_vanzare, pozdoc.pret_valuta, avnefac.cod_gestiune

select * from stocuri s where s.Cod_intrare='5307001             '
select * from pozdoc p where p.Cod='1510CUI50           ' and p.Cod_intrare='5307001      '
