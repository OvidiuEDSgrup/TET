CREATE VIEW yso.pozconexp AS   
with pozcon0 as  
(SELECT pozcon.Subunitate,pozcon.Tip,pozcon.Contract,pozcon.Tert,pozcon.Punct_livrare,pozcon.Data,pozcon.Cod  
 ,Cantitate=convert(decimal(15,3),pozcon.Cantitate)  
 ,Pret=convert(decimal(12,2),pozcon.Pret)  
 ,pozcon.Pret_promotional  
 ,Discount=convert(decimal(12,2),pozcon.Discount),pozcon.Termen,pozcon.Factura,pozcon.Cant_disponibila  
 ,Cant_aprobata=convert(decimal(15,3),pozcon.Cant_aprobata)  
 ,pozcon.Cant_realizata,pozcon.Valuta  
 ,Cota_TVA=convert(decimal(12,2),pozcon.Cota_TVA)  
 ,pozcon.Suma_TVA,pozcon.Mod_de_plata,pozcon.UM,pozcon.Zi_scadenta_din_luna,pozcon.Explicatii,pozcon.Numar_pozitie,pozcon.Utilizator,pozcon.Data_operarii,pozcon.Ora_operarii  
 ,convert(decimal(12,2),ISNULL(pozconexp.Pret,0)) as DiscDoi  
 ,convert(decimal(12,2),ISNULL(pozconexp.Cantitate,0)) as DiscTrei  
   
 ,convert(decimal(17,5),(CASE pozcon.valuta WHEN '' THEN 1 ELSE   
  CASE con.curs WHEN 0 THEN (SELECT TOP 1 curs FROM curs WHERE Valuta=pozcon.valuta and data<=pozcon.data ORDER BY Data DESC)   
  ELSE con.curs END END)) AS CursValuta  
   
 ,ISNULL(pozconexp2.Explicatii,'') AS Listare  
   
 ,ISNULL((SELECT SUM(Stoc) AS Cant_rezervata  
  FROM dbo.stocuri s LEFT JOIN par ON par.Tip_parametru='GE' AND par.Parametru='REZSTOCBK'  
  WHERE s.Subunitate=pozcon.subunitate and s.Tip_gestiune NOT IN ('F','T') and s.Contract=pozcon.Contract and s.Cod=pozcon.Cod  
  AND par.Val_logica=1 AND CHARINDEX(';'+RTRIM(s.cod_gestiune)+';',';'+RTRIM(par.Val_alfanumerica)+';')>0   
  AND s.Stoc>0.001) ,0) AS Cant_rezervata  
   
 ,isnull((select sum(pa.cant_comandata-pa.cant_realizata) from pozaprov pa where pa.tip='BK' and pa.comanda_livrare=pozcon.contract   
 and pa.data_comenzii=pozcon.data and pa.beneficiar=pozcon.tert and pa.cod=pozcon.cod /*and abs(pa.cant_realizata)<0.001*/),0) Cant_comandata  
   
 ,ISNULL((SELECT SUM(Stoc)  
  FROM dbo.stocuri s   
  WHERE s.Subunitate=pozcon.Subunitate AND s.Tip_gestiune NOT IN ('F','T') AND s.Stoc>0.001 AND pozcon.Cod=s.Cod  
   AND (s.Cod_gestiune=ISNULL(NULLIF(pozcon.Punct_livrare,''), pozcon.Factura) AND s.Contract=pozcon.Contract  
    OR s.Cod_gestiune=ISNULL(NULLIF(pozcon.Punct_livrare,''), pozcon.Factura) AND s.Contract=''  
    OR CHARINDEX(';'+RTRIM(s.cod_gestiune)+';',';'+RTRIM(par.Val_alfanumerica)+';')>0 AND s.Contract=''  
    OR s.Contract=pozcon.Contract)),0) AS Cant_stoc_gest  
   
 ,ISNULL((select SUM(p.cantitate)  
 from pozdoc p   
 WHERE p.Subunitate=pozcon.Subunitate and p.Tip='TE' and p.Factura=pozcon.Contract   
  and p.Gestiune=ISNULL(NULLIF(pozcon.Punct_livrare,''), pozcon.Factura) AND p.Cod=pozcon.Cod   
  AND par.Val_logica=1 AND CHARINDEX(';'+RTRIM(p.Gestiune_primitoare)+';',';'+RTRIM(par.Val_alfanumerica)+';')>0   
  AND p.cantitate>0 and p.stare not in ('4', '6')),0) AS Transferuri  
   
 ,ISNULL((select SUM(p.cantitate)  
  from pozdoc p where p.Subunitate=pozcon.Subunitate and p.Tip='AP' and p.Contract=pozcon.Contract   
   --and p.Gestiune=ISNULL(NULLIF(pozcon.Punct_livrare,''), pozcon.Factura)  
   and p.Cod=pozcon.cod and p.cantitate>0),0) AS Avize  
 ,ISNULL((select SUM(p.cantitate)  
 from pozdoc p where p.Subunitate=pozcon.Subunitate and p.Tip='AE' and p.grupa=pozcon.Contract   
  --and p.Gestiune=ISNULL(NULLIF(pozcon.Punct_livrare,''), pozcon.Factura)  
  and p.Cod=pozcon.cod and p.cantitate>0),0) AS AlteIesiri  
 ,convert(decimal(12,2),CASE when gprim.tip_gestiune IN ('A') then pozcon.Cota_TVA else 0 end) as tva  
 --,tip_tva=isnull(t.tip_tva,'N')  
FROM pozcon   
LEFT JOIN pozcon pozconexp ON pozconexp.Subunitate='EXPAND' and pozconexp.Tip=pozcon.Tip and pozconexp.Data=pozcon.Data   
 and pozconexp.Tert=pozcon.Tert and pozconexp.Contract=pozcon.Contract and pozconexp.Cod=pozcon.Cod and pozconexp.Numar_pozitie=pozcon.Numar_pozitie   
LEFT JOIN pozcon pozconexp2 ON pozconexp2.Subunitate='EXPAND2' and pozconexp2.Tip=pozcon.Tip and pozconexp2.Data=pozcon.Data   
 and pozconexp2.Tert=pozcon.Tert and pozconexp2.Contract=pozcon.Contract and pozconexp2.Cod=pozcon.Cod and pozconexp2.Numar_pozitie=pozcon.Numar_pozitie   
LEFT JOIN con ON con.Subunitate=pozcon.Subunitate and con.Tip=pozcon.Tip and con.Data=pozcon.Data and con.Tert=pozcon.Tert and con.Contract=pozcon.Contract  
LEFT JOIN nomencl on nomencl.Cod=pozcon.Cod  
LEFT JOIN par ON par.Tip_parametru='GE' AND par.Parametru='REZSTOCBK'  
left join gestiuni gprim on gprim.Subunitate=pozcon.Subunitate and gprim.Cod_gestiune=pozcon.Punct_livrare  
/*LEFT join (select t.Subunitate,t.Tert,tip_tva=isnull(ttva.tip_tva,(case when isnull(TipTVA.tip_tva,'P')='I' then 'I' else 'P' end)) from terti t   
  left join (select top 1 tip_tva from TvaPeTerti where TipF='B' and Tert is null and dela<=GETDATE() order by dela desc) tipTva on 1=1  
  outer apply (select top 1 t.tert,tv.tip_tva as tip_tva  
     from TvaPeTerti tv   
     where tv.tipf='F' and t.tert=tv.tert  
     order by dela desc  
     ) ttva) t on t.Subunitate=pozcon.Subunitate and t.Tert=pozcon.Tert */  
WHERE pozcon.Subunitate NOT LIKE 'EXPAND%' AND pozcon.Tip='BK')  
  
,pozcon1 as  
(select *   
,pretfrtva=round(p.pret/(1+p.tva/100.00),5)  
,disctot=(1-p.Discount/100.00)*(1-p.DiscDoi/100.00)*(1-p.DiscTrei/100.00)  
from pozcon0 p)  
  
,pozcon2 as  
(select *   
,valfrdisc=round(p.pret*p.cantitate,2)  
,pretdisc=round(p.pret*p.disctot,5)  
,pretcutva=round(p.pretfrtva*(1+p.Cota_TVA/100.00),5)  
,tvapret=round(p.pretfrtva*(p.Cota_TVA/100.00),5)  
from pozcon1 p)  
  
,pozcon3 as  
(select *   
,valcudisc=round(p.pretdisc*p.cantitate,5)  
,pretdiscfrtva=round(p.pretdisc/(1+p.tva/100.00),5)  
,tvapretdisc=round(p.tvapret*p.disctot,5)  
,pretcutvadisc=round(p.pretcutva*p.disctot,5)  
from pozcon2 p)  
  
,pozcon4 as  
(select *   
,valdisc=round(p.valfrdisc-p.valcudisc,2)  
,valfrtva=round(p.pretdiscfrtva*p.CursValuta*p.cantitate,2)  
,valtva=round(p.tvapretdisc*p.CursValuta*p.cantitate,2)  
,valcutva=round(p.pretcutvadisc*p.CursValuta*p.cantitate,2)  
from pozcon3 p)  
  
select * from pozcon4  