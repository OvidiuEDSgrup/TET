select p.Contract,p.Data_facturii,* from sysspd p where p.Factura like 'AG940092'
order by p.Data_stergerii desc

select * from webJurnalOperatii j where j.obiectSql like 'wOPGenerareUnAPdinBKSP'
and j.data<='2014-05-02 11:03:48.533'
--convert(varchar(max),j.parametruXML) like '%AG940092%'
order by j.data desc