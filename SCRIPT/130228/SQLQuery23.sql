select i.*--top 1 @idindex=i.index_id, @idobject=i.object_id
				from sys.index_columns ic 
					inner join sys.columns c on c.object_id=ic.object_id and c.column_id=ic.column_id
					inner join sys.indexes i on i.object_id=ic.object_id and i.index_id=ic.index_id 
					inner join sys.objects o on o.object_id=c.object_id
				where i.is_unique=1 and o.name='antetbonuri' and c.name='loc_De_munca' order by i.index_id 
				
select ' alter table '+rtrim(o.name)+' enable trigger '+RTRIM(t.name)+CHAR(10)--+CHAR(13)
	from sys.triggers t inner join sys.objects o on o.object_id=t.parent_id
	where t.is_disabled=1
	
	select ' alter	 table '+rtrim(o.name)+' disable trigger '+RTRIM(t.name)+CHAR(10)--+CHAR(13)
	from sys.triggers t inner join sys.objects o on o.object_id=t.parent_id
	where t.is_disabled=0