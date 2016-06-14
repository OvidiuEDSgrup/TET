truncate table yso_CodInl 
insert yso_CodInl (Tip,Cod_vechi,Cod_nou)
select Tip,Cod_vechi,Cod_nou from tet..yso_CodInl c --where c.Cod_nou=c.Cod_vechi
order by c.Tip,c.Cod_nou,c.Cod_vechi

select ' alter	 table '+rtrim(o.name)+' disable trigger '+RTRIM(t.name)+CHAR(10)--+CHAR(13)
	from sys.triggers t inner join sys.objects o on o.object_id=t.parent_id
	where t.is_disabled=0