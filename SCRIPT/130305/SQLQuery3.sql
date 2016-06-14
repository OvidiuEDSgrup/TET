select ' alter	 table '+rtrim(o.name)+' enable trigger '+RTRIM(t.name)+CHAR(10)--+CHAR(13)
	from sys.triggers t inner join sys.objects o on o.object_id=t.parent_id
	where t.is_disabled=1
	
select *, -- update p set numar_document=
c.Cod_nou 
from pozincon p inner join yso_CodInl c on c.Tip=-5 and c.Cod_vechi=p.Numar_document
where c.Cod_vechi like '5311.%' 