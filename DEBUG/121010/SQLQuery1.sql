declare @cont varchar(9)=';707;709;607;609;'
select distinct p.Cont_corespondent,p.Cont_de_stoc,p.Cont_factura
,p.Cont_intermediar,p.Cont_venituri, p.Tip
--,*
 from pozdoc p 
where charindex(';'+left(p.Cont_corespondent,3)+';',@cont)>0
or charindex(';'+left(p.Cont_de_stoc,3)+';',@cont)>0
or charindex(';'+left(p.Cont_factura,3)+';',@cont)>0
or charindex(';'+left(p.Cont_intermediar,3)+';',@cont)>0
or charindex(';'+left(p.Cont_venituri,3)+';',@cont)>0