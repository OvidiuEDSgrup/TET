select * from webJurnalOperatii j where j.data>='2014-11-17'
and j.utilizator='FILIALA_AG' order by j.data desc
--and j.parametruCHAR like '%AG940451%'
--and j.obiectSql like '%storn%'


select * from pozdoc p where p.Numar='AG940451'