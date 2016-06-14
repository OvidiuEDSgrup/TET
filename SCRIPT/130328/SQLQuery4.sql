select
convert(char(15),convert(money,sum(sum(round(round(convert(decimal(12,2),p.pret/(1+p.tva/100.00)*(1+p.cota_tva/100.00))*(1-p.Discount/100.00)*(1-p.DiscDoi/100.00)*(1-p.DiscTrei/100.00),2)*p.CursValuta*p.cantitate,2))) over(partition by p.contract)),1),
convert(char(15),convert(money,    sum(round(round(convert(decimal(12,2),p.pret/(1+p.tva/100.00)*(1+p.cota_tva/100.00))*(1-p.Discount/100.00)*(1-p.DiscDoi/100.00)*(1-p.DiscTrei/100.00),2)*p.CursValuta*p.cantitate,2))),1),
convert(char(15),convert(money,sum(sum(round(round(convert(decimal(12,2),p.pret/(1+p.tva/100.00)*(p.cota_tva/100.00)) 
	*(1-p.Discount/100.00)*(1-p.DiscDoi/100.00)*(1-p.DiscTrei/100.00),2)
	*p.CursValuta*p.cantitate,2))) over(partition by p.contract)),1),
convert(char(15),convert(money,sum(round(round(convert(decimal(12,2),p.pret/(1+p.tva/100.00)*(p.cota_tva/100.00)) 
	*(1-p.Discount/100.00)*(1-p.DiscDoi/100.00)*(1-p.DiscTrei/100.00),2)
	*p.CursValuta*p.cantitate,2)) ),1),
convert(char(15),convert(money,sum(sum(round(round(convert(decimal(12,2),p.pret/(1+p.tva/100.00)             ) *(1-p.Discount/100.00)*(1-p.DiscDoi/100.00)*(1-p.DiscTrei/100.00),2)*p.CursValuta*p.cantitate,2))) over(partition by p.contract)),1),
convert(char(15),convert(money,sum(sum(round(round(convert(decimal(12,2),p.pret/(1+p.tva/100.00))-convert(decimal(12,2),p.pret/(1+p.tva/100.00)*(1-p.Discount/100.00)*(1-p.DiscDoi/100.00)*(1-p.DiscTrei/100.00)),2)*p.CursValuta*p.cantitate,2))) over(partition by p.contract)),1),
convert(char(15),convert(money,round(max(convert(decimal(12,2),p.pret*(1-p.Discount/100.00)*(1-p.DiscDoi/100.00)*(1-p.DiscTrei/100.00))),2)),2)

,valdisc=sum(p.valdisc)
,valfrtva=sum(p.valfrtva)
,valtva=sum(p.valtva)
,valcutva=sum(p.valcutva)
,disctot=MAX(p.Disctot)
,convert(char(15),convert(money,max(p.pretdisc)),1)
,convert(char(15),convert(money,max(p.valcudisc)),1)
,convert(char(15),convert(money,max(p.valdisc)),1)
,convert(char(15),convert(money,sum(sum(p.valdisc)) over(partition by p.contract)),1)
,convert(char(15),convert(money,sum(sum(round(p.valcudisc*(con.val_reziduala/100),2))) over(partition by p.contract)),1)
FROM avnefac JOIN con ON avnefac.subunitate=con.subunitate and avnefac.tip=con.tip and avnefac.contractul=con.contract and avnefac.cod_tert=con.tert and avnefac.data=con.data 
JOIN yso.pozconexp p ON p.subunitate=con.subunitate and p.tip=con.tip and p.contract=con.contract and p.data=con.data and p.tert=con.tert LEFT JOIN terti ON terti.subunitate=con.subunitate and terti.tert=con.tert LEFT JOIN nomencl ON nomencl.cod=p.cod
where p.Contract='9840110'
group by p.Contract,p.cod