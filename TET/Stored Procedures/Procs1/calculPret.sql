CREATE procedure [dbo].[calculPret] @id int
as
begin
	declare @doc xml,@count int, @c int,@tip varchar(1),@PU float,@pret float,@idtehn int,@cantitate float,@cant float,@idp_c int, @idp int,
			@man float, @mat float,@total float
	--@cantitate reprezinta cantitatea pentru care se face antecalculatia, iar @cant va fi cant curenta a fiecarei resurse

	
	set @tip=(select tip from poztehnologii where id=@id)
	if @tip='A'
	begin
		set @cantitate = (select cantitate from pozTehnologii where id=@id)
		
		exec iaArborePlan @id,1, @doc out
		set @count= @doc.value('count (/row)','INT')	
		set @c=1
		set @PU = 0
		set @pret= 0 
		set @man=0
		set @mat=0
		set @total=0
		while @c<=@count
		begin				
			if @doc.query('/row[position()=sql:variable("@c")]').value('(row/@tip)[1]','varchar(1)') in ('M','O')
			begin
				set @PU = @PU + (@doc.query('/row[position()=sql:variable("@c")]').value('(row/@cantitate)[1]','float')*@doc.query('/row[position()=sql:variable("@c")]').value('(row/@pret)[1]','float'))
				
				if @doc.query('/row[position()=sql:variable("@c")]').value('(row/@tip)[1]','varchar(1)') = 'M'
					set @mat = @mat +@doc.query('/row[position()=sql:variable("@c")]').value('(row/@cant_i)[1]','float')+ @doc.query('/row[position()=sql:variable("@c")]').value('(row/@cantitate)[1]','float')*@doc.query('/row[position()=sql:variable("@c")]').value('(row/@pret)[1]','float')
				else
					if @doc.query('/row[position()=sql:variable("@c")]').value('(row/@tip)[1]','varchar(1)') = 'O'
						set @man = @man + @doc.query('/row[position()=sql:variable("@c")]').value('(row/@cant_i)[1]','float')+@doc.query('/row[position()=sql:variable("@c")]').value('(row/@cantitate)[1]','float')*@doc.query('/row[position()=sql:variable("@c")]').value('(row/@pret)[1]','float')
			end
			set @c = @c+1
		end	
		set @pret = @PU 
		set @PU=@PU/@cantitate		
		update pozTehnologii set pret=@man where idp=@id and tip='E' and cod='MAN'
		update pozTehnologii set pret=@mat where idp=@id and tip='E' and cod='MAT'
		
		--Avand calculate MAN si MAT care sunt standard se pot calcula restul
		exec calculElemAntec @id
		
		set @pret=isnull((select pret from pozTehnologii where idp=@id and tip='E' and cod='TP' ),0)
		
		update pozTehnologii set pret=@pret/@cantitate where id=@id
		update antecalculatii set pret =@pret where cod = (select cod from pozTehnologii where id=@id )
	end	
end
