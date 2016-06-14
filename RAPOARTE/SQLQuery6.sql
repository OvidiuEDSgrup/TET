select  ltrim(rtrim( p.tert)) as tert,ltrim(rtrim(t.denumire)) as denumire, p.factura,p.numar,sum(p.cantitate*p.pret_vanzare) as suma,max(p.data) as data,
(select sum(suma) from pozincon where tip_document in('AP','AS') and numar_document=p.numar and cont_creditor='4427') as S4427,
(select sum(suma) from pozincon where tip_document in('AP','AS') and numar_document=p.numar and cont_creditor='472') as S472,
(select sum(suma) from pozincon where tip_document in('AP','AS') and numar_document=p.numar and cont_creditor='704') as S4704,
(select sum(suma) from pozincon where tip_document in('AP','AS') and numar_document=p.numar and cont_creditor='706') as S706,
(select sum(suma) from pozincon where tip_document in('AP','AS') and numar_document=p.numar and cont_creditor='707.1') as S7071,
(select sum(suma) from pozincon where tip_document in('AP','AS') and numar_document=p.numar and cont_creditor='707.0') as S7070,
(select sum(suma) from pozincon where tip_document in('AP','AS') and numar_document=p.numar and cont_creditor='709') as S709,
(select sum(suma) from pozincon where tip_document in('AP','AS') and numar_document=p.numar and cont_creditor='7588') as S7588,
(select sum(suma) from pozincon where tip_document in('AP','AS') and numar_document=p.numar and cont_creditor='7581') as S7581
  from pozdoc p, terti t where p.tip in('AP','AS')  and p.tert=t.tert
and p.numar in (select numar_document from pozincon where tip  in('AP','AS')and cont_debitor like ltrim(rtrim(@cont))+'%')
and p.data>=@data1 and p.data<=@data2
 and (isnull(@tert, '') = '' OR  p.tert= rtrim(rtrim(@tert)))
group by p.Factura,p.numar,p.tert, t.denumire