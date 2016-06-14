select 
p.Loc_de_munca,p.Data,left(p.Cont_venituri,3) Cont
--,P.Cont_venituri,CASE P.Tip WHEN 'AC' then case when ab.Factura is null then P.Tip else 'BC' end else p.Tip end
--,CASE when n.Tip not in ('S','R') then '' else p.Cod end as cod --,p.Cod,p.subunitate, p.gestiune, data, p.tert, p.factura, p.Data_facturii, (case when 1 =4 then p.loc_de_munca else ' ' end) as lm
, sum(round(convert(decimal(17,5),p.cantitate*p.pret_vanzare),          2.00000000 )) as valoare
--, TVA_deductibil as TVA, round(convert(decimal(18,5), p.cantitate * isnull(n.greutate_specifica, 0)), 3) as greutate, 
--(case when 1 =4 then p.Loc_de_munca+convert(char(10),p.data_facturii,102)+p.factura when 1 =3 then convert(char(10),p.data_facturii,102)+p.factura when 1 =2 then convert(char(10),data,102)+p.factura else p.factura+convert(char(10),p.data_facturii,102) end) as ordonare
--drop table ##bord7636    
into ##chitante
from pozdoc p
left outer join nomencl n on p.cod=n.cod
left outer join anexaFac a on a.subunitate=p.subunitate and a.numar_factura=p.factura 
  left outer join antetBonuri b on isnull(nullif(b.bon.value('(/date/document/@numar_in_pozdoc)[1]','varchar(50)'),'')
	,left(rtrim(convert(varchar(4),b.Casa_de_marcat))+right(replace(str(b.Numar_bon),' ','0'),4),8))=p.numar
	and b.Data_bon=p.Data and b.Chitanta=1 
  left outer join antetBonuri ab on ab.Chitanta=0 and ab.Factura=b.Factura and ab.Data_facturii=b.Data_facturii
where p.subunitate='1        ' and (0=0 or p.gestiune in ('#')) and ((0=0 or p.tip='AS') and p.tip in ('AC','AC','AC')) and data between '09/01/2012' and '09/30/2012' and (0=0 or p.Loc_de_munca like rtrim ('         ')+'%') and (0=0 or p.gestiune like rtrim ('         ')+'%') and (0=0 or p.factura<>'') and (0=0 or p.Data_facturii between '09/01/2012' and '09/30/2012') and (0=0 or cont_factura like rtrim ('             ')+'%') and (0=0 or jurnal='   ') and (0=0 or isnull(a.numele_delegatului,'')='                              ') 
--and (p.tip<>'AC' or ab.Factura is not null)
--and p.Cod like '%SERV%'
and left(p.Cont_venituri,3) in ('707','472')
and (0=0 
	or 0 =1 and not exists (select 1 from doc where doc.subunitate=p.subunitate and doc.tip=p.tip and doc.numar=p.numar and doc.data=p.data and (doc.tip_miscare='8' or left(doc.cont_factura,3)='418')) 
	or 0 =2 and exists (select 1 from pozadoc where pozadoc.subunitate=p.subunitate and pozadoc.tip='IF' and pozadoc.tert=p.tert and pozadoc.factura_dreapta=p.factura) 
	or 0 =3 and exists (select 1 from doc where doc.subunitate=p.subunitate and doc.tip=p.tip and doc.numar=p.numar and doc.data=p.data and (doc.tip_miscare='8' or left(doc.cont_factura,3)='418')) 
		and not exists (select 1 from pozadoc where pozadoc.subunitate=p.subunitate and pozadoc.tip='IF' and pozadoc.tert=p.tert and pozadoc.factura_dreapta=p.factura)) and 0 = 0
group by p.Loc_de_munca,p.Data,p.Cont_venituri
order by p.Loc_de_munca,p.Data,p.Cont_venituri
--p.Cont_venituri,CASE P.Tip WHEN 'AC' then case when ab.Factura is null then P.Tip else 'BC' end else p.Tip end
--,CASE when n.Tip not in ('S','R') then '' else p.Cod end 
--with rollup
--having p.Cont_venituri is null or CASE when n.Tip not in ('S','R') then '' else p.Cod end  is not null
--order by p.Loc_de_munca,
--p.Cont_venituri,CASE P.Tip WHEN 'AC' then case when ab.Factura is null then P.Tip else 'BC' end else p.Tip end
--,CASE when n.Tip not in ('S','R') then '' else p.Cod end 
/*union all 
select '','',subunitate, cod_gestiune, data, cod_tert, factura, Data_facturii, (case when 1 =4 then loc_munca else ' ' end), valoare, TVA_22, 0, 
(case when 1 =4 then Loc_munca+convert(char(10),data_facturii,102)+factura when 1 =3 then convert(char(10),data_facturii,102)+factura when 1 =2 then convert(char(10),data,102)+factura else factura+convert(char(10),data_facturii,102) end)
from doc 
where subunitate='1        ' 
and (1=0 and numar_pozitii=0 or not exists (select 1 from pozdoc p where p.subunitate=doc.subunitate and p.tip=doc.tip and p.numar=doc.numar and p.data=doc.data))
and (0=0 or cod_gestiune in ('#')) and ((0=0 or tip='AP') and tip in ('AC','AP','AS')) and data between '09/01/2012' and '09/30/2012' and (0=0 or Loc_munca like rtrim ('         ')+'%') and (0=0 or cod_gestiune like rtrim ('         ')+'%') and (0=0 or factura<>'') and (0=0 or Data_facturii between '09/01/2012' and '09/30/2012') and (0=0 or cont_factura like rtrim ('             ')+'%') and (0=0 or jurnal='   ') 
and (1=0 
	or 1 =1 and doc.tip_miscare<>'8' and left(doc.cont_factura,3)<>'418'  and (0=0 or doc.stare = 1)
	or 1 =3 and (doc.tip_miscare='8' or left(doc.cont_factura,3)='418')) 
*/



--select * from lm where lm.Cod like '1mkt%'