select p.Tert,* from pozdoc p where p.Factura like '%943074[7,8]'
select p.Tert,* from sysspd p where p.Factura like '%943074[7,8]' order by p.Data_stergerii desc

select * from webJurnalOperatii j where j.obiectSql like '%pozplin%'
--j.data<='2013-07-08 08:10:47.153' 
--and j.parametruXML.value( '(/*/@numar)[1]','varchar(20)') like '%943074[7,8]'
order by j.data desc