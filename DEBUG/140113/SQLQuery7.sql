select * from sysscon c where c.Contract like 'is980043'
order by c.Data_stergerii desc
select * from sysspv p where p.Cod_produs like '4200005000521' 
order by p.Data_stergerii desc

select * from sysspcon c where c.Contract like 'is980043' and c.Numar_pozitie=3--and c.Cod like '4200005000521'
order by c.Data_stergerii desc
select * from webJurnalOperatii j where --j.utilizator like 'FILIALA_IS' and 
j.obiectSql like '%pozcon%' 
and convert(nvarchar(max),j.parametruXML) like '%is980043%' and convert(nvarchar(max),j.parametruXML) like '%4200005000521%'
order by j.data desc

