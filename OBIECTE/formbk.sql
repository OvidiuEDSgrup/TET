insert formular
select 'Proforma'
,Numar_pozitie
,tip
,rand
,pozitie
,expresie
,obiect 
from formular f where f.formular='com_liv' and f.rand=10 and f.pozitie between 81 and 83

delete formular
where formular<>'com_liv'
and rand=10 and pozitie between 81 and 83

UPDATE f1 
SET 
--select
expresie=f.expresie
FROM formular f1
JOIN formular f on f1.formular=rtrim(f.formular)+'2' and f1.obiect=f.obiect
WHERE f.formular='proforma' and f.obiect IN ('TOTAL','TOTALRON','CURS','VALEUR','AVANS','TVALTOTAL','TOTALEURO','TOTALSUMA','TOTALPLATA','TDISC')

p.pret*(1-p.Discount/100)*(1-isnull(x.Pret,0)/100)*(1-isnull(x.Cantitate,0)/100)

FROM avnefac 
JOIN con ON avnefac.subunitate=con.subunitate and avnefac.tip=con.tip and avnefac.contractul=con.contract and avnefac.cod_tert=con.tert and avnefac.data=con.data 
JOIN pozcon ON pozcon.subunitate=con.subunitate and pozcon.tip=con.tip and pozcon.contract=con.contract and pozcon.data=con.data and pozcon.tert=con.tert 
LEFT JOIN pozcon AS pozexp ON pozexp.Subunitate='EXPAND' and pozexp.Tip=pozcon.Tip and pozexp.Data=pozcon.Data and pozexp.Tert=pozcon.Tert and pozexp.Contract=pozcon.Contract and pozexp.Cod=pozcon.Cod and pozexp.Numar_pozitie=pozcon.Numar_pozitie 
LEFT JOIN terti ON terti.subunitate=con.subunitate and terti.tert=con.tert 
LEFT JOIN nomencl ON nomencl.cod=pozcon.cod and nomencl.cod=pozcon.cod 


Select * from avnefac where terminal ='5916'

convert(char(15),convert(money,round(sum(pozcon.pret*(1-pozcon.Discount/100)*(1-isnull(pozexp.Pret,0)/100)*(1-isnull(pozexp.Cantitate,0)/100)*pozcon.cantitate),2)),1)

convert(char(15),convert(money,round((select sum(round(convert(decimal(17,5),p.cantitate*p.pret*(1-p.Discount/100)*(1-isnull(x.Pret,0)/100)*(1-isnull(x.Cantitate,0)/100)),2 )) from pozcon p left join pozcon x on x.Subunitate='EXPAND' and x.Tip=p.Tip and x.Data=p.Data and x.Tert=p.Tert and x.Contract=p.Contract and x.Cod=p.Cod and x.Numar_pozitie=p.Numar_pozitie where p.subunitate=max(pozcon.subunitate) and p.tip=max(pozcon.tip) and p.contract=max(con.contract) and p.data=max(pozcon.data)),2)),1)

x.Subunitate='EXPAND' and x.Tip=p.Tip and x.Data=p.Data and x.Tert=p.Tert and x.Contract=p.Contract and x.Cod=p.Cod and x.Numar_pozitie=p.Numar_pozitie 

convert(char(15),convert(money,round(sum(pozcon.pret*(1-pozcon.Discount/100)*(1-isnull(pozexp.Pret,0)/100)*(1-isnull(pozexp.Cantitate,0)/100)*pozcon.cantitate)*(CASE max(pozcon.valuta) WHEN '' THEN 1 ELSE CASE max(con.curs) WHEN 0 THEN (SELECT TOP 1 curs FROM curs WHERE Valuta=max(pozcon.valuta) and data<=max(pozcon.data) ORDER BY Data DESC) END END),2)),1)
convert(char(15),convert(money,round((select sum(round(convert(decimal(17,5),p.cantitate*p.pret*C.CURS*0.3),2 )) from pozcon p join con c on p.subunitate=c.subunitate and p.tip=c.tip and p.tert=c.tert and p.data=c.data and p.contract=c.contract where p.subunitate= max(pozcon.subunitate) and p.tip= max(pozcon.tip) and p.contract= max(pozcon.contract) and p.data= max(pozcon.data) and p.tert=max(pozcon.tert)/*and av.cod_gestiune=p.gestiune*/),2)),1)

FROM avnefac JOIN con ON avnefac.subunitate=con.subunitate and avnefac.tip=con.tip and avnefac.contractul=con.contract and avnefac.cod_tert=con.tert and avnefac.data=con.data JOIN pozcon ON pozcon.subunitate=con.subunitate and pozcon.tip=con.tip and pozcon.contract=con.contract and pozcon.data=con.data and pozcon.tert=con.tert LEFT JOIN pozcon AS pozexp ON pozexp.Subunitate='EXPAND' and pozexp.Tip=pozcon.Tip and pozexp.Data=pozcon.Data and pozexp.Tert=pozcon.Tert and pozexp.Contract=pozcon.Contract and pozexp.Cod=pozcon.Cod and pozexp.Numar_pozitie=pozcon.Numar_pozitie LEFT JOIN terti ON terti.subunitate=con.subunitate and terti.tert=con.tert LEFT JOIN nomencl ON nomencl.cod=pozcon.cod and nomencl.cod=pozcon.cod

FROM avnefac 
JOIN con ON avnefac.subunitate=con.subunitate and avnefac.tip=con.tip and avnefac.contractul=con.contract and avnefac.cod_tert=con.tert and avnefac.data=con.data 
JOIN yso.pozconexp ON pozcon.subunitate=con.subunitate and pozcon.tip=con.tip and pozcon.contract=con.contract and pozcon.data=con.data and pozcon.tert=con.tert 
LEFT JOIN terti ON terti.subunitate=con.subunitate and terti.tert=con.tert 
LEFT JOIN nomencl ON nomencl.cod=pozcon.cod and nomencl.cod=pozcon.cod 

convert(char(15),convert(money,round((select sum(round(convert(decimal(17,5),p.cantitate*p.pret*(1-p.Discount/100)*(1-p.DiscDoi/100)*(1-p.DiscTrei/100)),2 )) from yso.pozconexp p where p.subunitate=max(pozcon.subunitate) and p.tip=max(pozcon.tip) and p.contract=max(con.contract) and p.data=max(pozcon.data)),2)),1)

CASE max(pozcon.valuta) WHEN '' THEN '' ELSE convert(char(15),convert(money,round(sum(pozcon.pret*(1-pozcon.Discount/100)*(1-pozcon.DiscDoi/100)*(1-pozcon.DiscTrei/100)*pozcon.cantitate),2)),1) END

convert(char(15),convert(money,round(sum(pozcon.pret*(1-pozcon.Discount/100)*(1-pozcon.DiscDoi/100)*(1-pozcon.DiscTrei/100)*pozcon.cantitate)*(CASE max(pozcon.valuta) WHEN '' THEN 1 ELSE CASE max(con.curs) WHEN 0 THEN (SELECT TOP 1 curs FROM curs WHERE Valuta=max(pozcon.valuta) and data<=max(pozcon.data) ORDER BY Data DESC) END END),2)),1)

convert(char(15),convert(money,round((select sum(round(convert(decimal(17,5),p.cantitate*p.pret*C.CURS*0.3),2 )) from pozcon p join con c on p.subunitate=c.subunitate and p.tip=c.tip and p.tert=c.tert and p.data=c.data and p.contract=c.contract where p.subunitate= max(pozcon.subunitate) and p.tip= max(pozcon.tip) and p.contract= max(pozcon.contract) and p.data= max(pozcon.data) and p.tert=max(pozcon.tert)),2)),1)

CASE max(pozcon.valuta) WHEN '' THEN '' ELSE convert(char(15),convert(money,round(sum(pozcon.pret*(1-pozcon.Discount/100)*(1-pozcon.DiscDoi/100)*(1-pozcon.DiscTrei/100)*pozcon.cantitate),2)),1) END

convert(char(15),convert(money,round(sum(pozcon.pret*(1-pozcon.Discount/100)*(1-pozcon.DiscDoi/100)*(1-pozcon.DiscTrei/100)*pozcon.cantitate*pozcon.CursValuta),2)),1)

convert(char(15),convert(money,round((select sum(round(convert(decimal(17,5),p.cantitate*p.pret*p.CursValuta*0.3),2 )) from yso.pozconexp p where p.subunitate= max(pozcon.subunitate) and p.tip= max(pozcon.tip) and p.contract= max(pozcon.contract) and p.data= max(pozcon.data) and p.tert=max(pozcon.tert)),2)),1)

convert(char(15),convert(money,round((select sum(round(convert(decimal(17,5),p.cantitate*p.pret*p.CursValuta*0.24),2 )) from yso.pozconexp p where p.subunitate= max(pozcon.subunitate) and p.tip= max(pozcon.tip) and p.contract= max(pozcon.contract) and p.data= max(pozcon.data) and p.tert=max(pozcon.tert)),2)),1)