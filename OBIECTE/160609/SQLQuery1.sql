with fact_vanzare AS (
select 
 tot_val_vanzare=SUM(round(convert(decimal(18,5),p.cantitate*p.pret_vanzare),2))
  OVER(partition by l.idpozdoc),
 tot_val_contract = SUM(round(convert(decimal(18,5),P.cantitate*P.Pret_valuta*(1-isnull(bf.Discount,dx.disc_max_grupa)/100.00)),2))
  OVER(partition by l.idpozdoc),
 val_vanzare=SUM(round(convert(decimal(18,5),p.cantitate*p.pret_vanzare),2))
  OVER(partition by p.subunitate, p.tip, p.data, p.numar),
 val_contract = SUM(round(convert(decimal(18,5),P.cantitate*P.Pret_valuta*(1-isnull(bf.Discount,dx.disc_max_grupa)/100.00)),2))
  OVER(partition by p.subunitate, p.tip, p.data, p.numar),
 l.*
 ,p.Numar,p.Factura, c.Denumire
from pozdoc p join terti c on c.Subunitate=p.Subunitate and c.Tert=p.Tert
 join yso_LegComisionVanzari l on l.subDoc=p.Subunitate and p.Tip=l.tipDoc and p.Data=l.dataDoc and p.Numar=l.nrDoc
 join nomencl n on n.Cod=p.Cod and n.Tip not in ('R','S') 
 OUTER APPLY (SELECT TOP (1) bk.Subunitate, bk.Tip, bk.Data, bk.Contract, bk.Cod, bk.Tert, cn.Contract_coresp
   --nrCrtBk = ROW_NUMBER() OVER(PARTITION BY bk.Tert, bk.Contract, bk.cod ORDER BY abs(DATEDIFF(D,bk.Data,p.Data)),ABS(bk.Pret-p.Pret_valuta))
  FROM pozcon bk left join con cn on cn.Subunitate=bk.Subunitate and cn.Tip=bk.Tip and cn.Tert=bk.Tert and cn.Contract=bk.Contract and cn.Data=bk.Data
  WHERE bk.Subunitate=p.Subunitate and bk.Tip='BK' and bk.Tert=P.Tert and bk.Contract=P.Contract and bk.cod=p.Cod 
  ORDER BY abs(DATEDIFF(D,bk.Data,p.Data)),ABS(bk.Pret-p.Pret_valuta)) bk 
 OUTER APPLY (select TOP (1) bf.Tert, bf.Data, bf.Contract, bf.Mod_de_plata, bf.Cod, bf.Discount
   --nrCrtBf = ROW_NUMBER() OVER(PARTITION BY bf.Subunitate, bf.tip, bf.Tert, bf.Contract, bf.cod ORDER BY (case bf.Contract when bk.Contract_coresp then 0 else 1 end),bf.Data desc,bf.Contract desc,bf.Cod desc,bf.Discount desc)
  from pozcon bf --left join con cn on cn.Subunitate=bf.Subunitate and cn.Tip=bf.Tip and cn.Tert=bf.Tert and cn.Contract=bf.Contract and cn.Data=bf.Data 
  where bf.Subunitate=p.Subunitate and bf.Tip='BF' and bf.Tert=P.Tert and bf.Data<=P.Data and bf.Mod_de_plata='G' and n.Grupa like RTRIM(bf.Cod)+'%' 
  ORDER BY (case bf.Contract when bk.Contract_coresp then 0 else 1 end),bf.Data desc,bf.Contract desc,bf.Cod desc,bf.Discount desc) bf 
 OUTER APPLY (select TOP (1) disc_max_grupa=(CASE ISNUMERIC(valoare) when 1 then CONVERT(float,replace(Valoare,',','')) else null end)
    from proprietati Pr
    where Pr.Valoare<>'' and Pr.Cod<>'' and Pr.tip='GRUPA' and cod_proprietate='DISCMAX' and n.Grupa like RTRIM(Pr.Cod)+'%' 
    order by cod desc, Valoare desc) dx
--group by l.idPozDoc
)
select  l.*,rs.Factura,rs.Numar,i.denumire,
val_comision_efectiv_platit=(case when rs.valuta='' then round(convert(decimal(18,5),rs.cantitate*round(rs.pret_valuta*(1+
   (case when abs(rs.discount+rs.cota_TVA*100.00/(rs.cota_TVA+100.00))<0.01 then convert(decimal(12,4),-rs.cota_TVA*100.00/(rs.cota_TVA+100.00)) 
   else convert(decimal(12,4),rs.discount) end)/100),5)),2) when rs.tip='RP' then rs.cantitate*rs.pret_valuta else 
   round(convert(decimal(18,5),rs.cantitate*round(convert(decimal(18,5),rs.pret_valuta*rs.curs*(case when rs.numar_dvi='' or rs.tip='RS' then 
   (1+convert(decimal(18,5),rs.discount/100)) else 1 end)),5)),2) end)
  --+(case when not ((rs.numar_DVI<>'' and rs.tip='RM') or ((rs.numar_DVI='' and rs.tip='RM' or rs.tip in ('RP','RS')) and rs.procent_vama = 1)) then rs.tva_deductibil else 0 end)
,dif_tot_vanzare_contract=v.tot_val_vanzare-v.tot_val_contract
,dif_poz_vanzare_contract=v.val_vanzare-v.val_contract
from fact_vanzare v join pozdoc rs on rs.idPozDoc=v.idPozDoc join terti i on i.Subunitate=rs.Subunitate and i.Tert=rs.Tert
 join yso_LegComisionVanzari l on l.idPozDoc=v.idPozDoc and l.subDoc=v.subDoc and l.tipDoc=v.tipDoc and l.dataDoc=v.dataDoc and l.nrDoc=v.nrDoc
--where rs.Factura like  '%2040%'