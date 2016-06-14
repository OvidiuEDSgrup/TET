insert into pozcon
(Subunitate, Tip, Contract, Tert, Punct_livrare, Data, Cod, Cantitate, Pret, Pret_promotional, Discount, Termen, Factura, Cant_disponibila, Cant_aprobata, Cant_realizata, Valuta, Cota_TVA, Suma_TVA, Mod_de_plata, UM, Zi_scadenta_din_luna, Explicatii, Numar_pozitie, Utilizator, Data_operarii, Ora_operarii)
select
'1        '     as subunitate,
'FC'     as tip,
'33                  '     as contract,
a.furnizor    as tert,
''      as punct_livrare,
'02/17/2015'     as data,
a.cod     as cod,
a.de_aprovizionat  as cantitate,
a.pret       as pret,
0      as pret_promotional,
0      as discount,
a.termen    as termen,
'211.CJ   '     as factura,
round(convert(decimal(17,5), a.de_aprovizionat/(case when n.UM_1<>'' and n.coeficient_conversie_1<>0 then n.coeficient_conversie_1 else 1 end)), 3) as cant_disponibila,
a.de_aprovizionat  as cant_aprobata,
0      as cant_realizata,
'   '     as valuta,
n.cota_TVA    as cota_tva,
n.Cota_TVA*(a.de_aprovizionat*a.pret)/100 as suma_tva,
''      as mod_de_plata,
''      as um,
0      as zi_scadenta_din_luna,
(case when 1=1 then isnull((select top 1 p.codfurn from ppreturi p where p.tip_resursa='C' and p.cod_resursa = a.cod and p.tert = a.furnizor and p.data_pretului<='02/17/2015' order by p.data_pretului desc), '')
 else '' end)  as explicatii,
0      as numar_pozitie,
'CAPSUC'     as utilizator,
'02/17/2015'     as data_operarii,
'153057'     as ora_operarii
from comaprovtmp a
inner join nomencl n on n.cod = a.cod
--left outer join ppreturi p on 1=1 and p.tip_resursa='C' and p.cod_resursa = a.cod and p.tert = a.furnizor
where a.utilizator='CAPSUC    ' and a.de_aprovizionat>0
and not exists (select * from pozcon b where b.subunitate='1        ' and b.tip='FC' and b.contract='33                  ' and b.tert=a.furnizor and b.cod=a.cod and b.data='02/17/2015' and b.numar_pozitie=0)
