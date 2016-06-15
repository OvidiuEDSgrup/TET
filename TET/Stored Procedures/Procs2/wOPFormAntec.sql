create procedure [dbo].[wOPFormAntec] @sesiune varchar(30), @parXML XML
as
	declare @codAntec varchar(20),@idAntec int, @dataAntec datetime,@doc xml,@man xml,@mat xml,@par xml,@prod varchar(20),
		@val float,@total float,@cant float
	
	set @codAntec=isnull(@parXML.value('(/parametri/@codA)[1]','varchar(20)'),'')
	set @idAntec=(select id from pozTehnologii where cod=@codAntec and tip='A' )
	set @dataAntec=(select data from antecalculatii where cod=@codAntec)
	set @prod=(select rtrim(cod) from pozTehnologii where tip='T' and id=(select idp from pozTehnologii where id=@idAntec))
	set @total=(select pret from antecalculatii where cod=@codAntec)
	set @cant=(select cantitate from pozTehnologii where id=@idAntec)

	set @doc=(select dbo.genereazaTreeElemAntec(@idAntec,''))
	
	
	exec iaMOAntecalculatie @idAntec, 'M',@mat OUTPUT
	exec iaMOAntecalculatie @idAntec, 'O',@man OUTPUT	
	
	if @doc is not null
	begin
		--Adaugare MAT si MAN in structura antecalculatiei ( acolo unde sunt copii)
		set @doc.modify('insert sql:variable("@man") into (//row[@cod="MAN"])[1]')
		set @doc.modify('insert sql:variable("@mat") into (//row[@cod="MAT"])[1]')
	end
	set @doc= (select @doc for xml path('row'))
	
	declare @doc2 xml
	set @doc2=''
	exec transformaArbore @doc, @doc2 out
	
	declare @count int, @c int,@child xml	
	set @count= @doc2.value('count (/row)','INT')	
	set @c=1
	
	if exists (select * from sysobjects where name ='#fantec')
		drop table #fantec
	create table #fantec (nr int, coda varchar(20),dataa datetime,cod varchar(20),denumire varchar(100),cantitate varchar(20),
							valoare varchar(20), pret varchar(20),produs varchar(20),total float,cantitate_prod float,tip varchar(1))
							

	while @c<=@count
	begin
		if @child.value('(/row/@tip)[1]','varchar(2)') ='E'
			set @val=(select pret from pozTehnologii where parinteTop=@idAntec and tip='E' and cod=@child.value('(/row/@cod)[1]','varchar(20)'))
		else
			if @child.value('(/row/@tip)[1]','varchar(2)') in ('M','O')
				set @val= @child.value('(/row/@cantitate)[1]','float')*@child.value('(/row/@pret)[1]','float')+isnull(@child.value('(/row/@cant_i)[1]','float'),0)
		set @child = @doc2.query('/row[position()=sql:variable("@c")]')	
		
		insert into #fantec values(@c,@codAntec,@dataAntec,@child.value('(/row/@cod)[1]','varchar(20)'),@child.value('(/row/@denumire)[1]','varchar(100)'),
									@child.value('(/row/@cantitate)[1]','varchar(20)'),@val,@child.value('(/row/@pret)[1]','varchar(10)') 
									,@prod,@total,@cant,@child.value('(/row/@tip)[1]','varchar(1)')
									)
		set @c=@c+1
	end
	
	--select * from #fantec
	set @par=(select 'AT' as nrform, GETDATE() as data,'AT' as tip, 1 as debug for xml raw)
	exec wTipFormular @sesiune='',@parXML=@par
