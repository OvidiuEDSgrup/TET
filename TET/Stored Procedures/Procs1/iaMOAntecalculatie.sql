create procedure [dbo].[iaMOAntecalculatie] @id int,@tip varchar(1),@rez xml OUTPUT
as
begin
	declare 
		@doc xml,@count int, @c int, @child xml,@val float,@valuta float, @curs float
	exec iaArborePlan @id,1, @doc out	
	
	set @count= @doc.value('count (/row)','INT')	
	set @c=1
	set @rez=''
	
	set @curs=(select curs from antecalculatii where cod=(select cod from pozTehnologii where id=@id))
	--Pregatire XML
	while @c<=@count
	begin	
		set @child=@doc.query('/row[position()=sql:variable("@c")]')
		
		if @child.value('(row/@tip)[1]','varchar(1)') in ('M','O')
		begin
			set @val = @child.value('(row/@cantitate)[1]','float')*@child.value('(row/@pret)[1]','float')
			set @valuta=convert(decimal(10,2),@val/@curs)
			set @child.modify('insert attribute valoare {sql:variable("@val")} into (/row)[1]')
			set @child.modify('insert attribute valuta {sql:variable("@valuta")} into (/row)[1]')
			set @child.modify('insert attribute subtip {"M"} into (/row)[1]')
			set @child.modify('replace value of (/row/@_grupare)[1] with (/row/@cod)[1]')
			
			if  @child.value('(row/@tip)[1]','varchar(1)') = @tip		
				set @rez.modify('insert sql:variable("@child") into (/)[1]')
		end
		set @c = @c+1
	end	
end
