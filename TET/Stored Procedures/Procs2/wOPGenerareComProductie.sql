create procedure wOPGenerareComProductie @sesiune varchar(50), @parXML XML  
as
    --Pe macheta de contracte
	declare
		@cod varchar(20), @cantitate float, @termen datetime, @tert varchar(20),@numar varchar(20), @doc XML, @mesaj varchar(200)
		
	select
		@numar= @parXML.value('(/parametri/@numar)[1]', 'varchar(20)'),
		@tert= @parXML.value('(/parametri/@tert)[1]', 'varchar(20)')	
	
	select 
		pc.Cod as cod, ISNULL(t.termen,pc.Termen) as termen,pc.cantitate as cantitate
		into #ptComenzi	
	from con c
	inner join pozcon pc on c.Subunitate=1 and c.Tip='BF' and c.Contract=@numar and pc.Tip=c.Tip and c.Contract=pc.Contract 
	left outer join Termene t on t.subunitate=1 and  t.Contract=pc.Contract and t.cod=pc.cod 
	
	
	declare ptC cursor for select cod, termen,cantitate from #ptComenzi
	open ptC
	fetch next from ptC into @cod, @termen,@cantitate
	while @@FETCH_STATUS=0
	begin
		set @doc=
		(select 
			@tert as tert, @numar as contract, @termen as termen, @cantitate as cantitate,@cod as cod
		for xml raw
		)
		
		begin try
				exec wScriuPozLansari @sesiune=@sesiune, @parXML=@doc
		end try
		begin catch
			set @mesaj = ERROR_MESSAGE()
			raiserror(@mesaj, 11, 1)	
		end catch
		
		fetch next from ptC into @cod, @termen,@cantitate
	end
	
	close ptC
	deallocate ptC
			
			