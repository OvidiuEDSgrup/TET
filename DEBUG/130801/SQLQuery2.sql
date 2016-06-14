select * from pozdoc p where p.Factura='9430792' and p.Cod='9-3690-680-00-24-01'
select * from sysspd p where p.Factura='9430792' and p.Cod='9-3690-680-00-24-01'
select * from yso_sysspd_antet p where p.Data_operatiei='2013-07-31 13:00:49.687'
select * from webJurnalOperatii j where j.data<='2013-07-31 13:00:49.687' and j.obiectSql like '%yso_wOPGenTEsauAPdinBK%'