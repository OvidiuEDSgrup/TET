create procedure  [dbo].[transformaArbore] @doc xml,@out xml OUT
as
declare 
	@count int, @c int,@child xml, @val xml

set @count= @doc.value('count (/row/row)','INT')
set @c=1	
while @c <= @count
begin
	select @child = @doc.query('/row/row[position()=sql:variable("@c")]')
	if isnull(@child.value('(/row/@tip)[1]','varchar(1)'),'') <> 'A'	
	begin
		set @val =
		(
			select 
				@child.value('(/row/@cod)[1]','varchar(20)') as cod,
				@child.value('(/row/@id)[1]','int') as id ,
				@child.value('(/row/@idParinte)[1]','int') as idp,
				@child.value('(/row/@idReal)[1]','int') as idReal,
				@child.value('(/row/@tip)[1]','varchar(20)') as tip,				
				@child.value('(/row/@denumire)[1]','varchar(100)') as denumire, 
				--convert(decimal(10,2),@child.value('(/row/@cantitate)[1]','float')) as cantitate  ,
				--convert(decimal(10,2),@child.value('(/row/@pret)[1]','float')) as pret,
					@child.value('(/row/@cantitate)[1]','varchar(10)') as cantitate  ,
					@child.value('(/row/@pret)[1]','varchar(10)') as pret,
				convert(decimal(10,2),@child.value('(/row/@cant_i)[1]','float')) as cant_i,
				convert(decimal(10,2),@child.value('(/row/@ordine)[1]','float')) as ordine,
				@child.value('(/row/@_grupare)[1]','varchar(20)') as _grupare,
				@child.value('(/row/@um)[1]','varchar(10)') as um,
				@child.value('(/row/@denumireCod)[1]','varchar(200)') as denumireCod				
			for xml raw
		)		

		set @out.modify('insert sql:variable("@val") as last into (/)[1]')
		--Apel recursiv
		exec transformaArbore @child,@out out
	end	
	set @c = @c + 1
end
