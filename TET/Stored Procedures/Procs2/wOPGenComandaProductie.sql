create procedure [dbo].[wOPGenComandaProductie]  @sesiune varchar(50), @parXML XML  
as
	declare 
		@codP varchar(20), @cantitate float,@par xml,@id int,@codSemifabricat varchar(20),@poz bit	,@dataLans datetime,@termen varchar(10),
		@comandaLaComanda bit,@numarDoc int

		set @dataLans=ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'),GETDATE())	
		set @numarDoc= isnull(@parXML.value('(/parametri/@numarDoc)[1]', 'int'),0)
		if @numarDoc=0
			set @numarDoc=1
		
		--isnull((select max(detalii.value('(/row/@numarDoc)[1]', 'int'))+1 from poztehnologii where tip='L'),1)
		
		declare @min datetime,@minL datetime,@dataJ datetime,@dataS datetime
		set @dataj=@parXML.value('(/parametri/@dataJos)[1]', 'datetime')
		set @dataS=@parXML.value('(/parametri/@dataSus)[1]', 'datetime')		
		select @min=MIN(Termen) from con where Termen between @dataJ and @dataS and stare='1' and tip='BK'
		
		select @minL=MIN(CONVERT(datetime,numar_de_inventar)) 
			from comenzi inner join poztehnologii p on p.cod=comenzi.comanda and p.tip='L' 
			where CONVERT(datetime,numar_de_inventar) between @dataJ and @dataS

		if @minL<@min
			set @min=@minL
			
		set @termen=CONVERT(varchar(10),@minL,101)			
		set @codP=ISNULL(@parXML.value('(/parametri/@cod)[1]', 'varchar(20)'),'')
		
		set @cantitate=ISNULL(@parXML.value('(/parametri/@cantitate)[1]', 'float'),'')
		set @par= (select @codP as codP, @cantitate as cantitate, 'CP' as tipL,
						@parXML.value('(/parametri/@dataJos)[1]', 'datetime') as dataJos, @parXML.value('(/parametri/@dataSus)[1]', 'datetime') as dataSus,
						@dataLans as dataLans,@termen as termen,@numarDoc as numarDoc,
						@parXML.value('(/parametri/@multipla)[1]', 'varchar(1)') as multipla
					for xml raw)
		exec wScriuPozLansari @sesiune, @par
		
		/* ARthema
		procedure [dbo].[wOPGenComandaProductie]  @sesiune varchar(50), @parXML XML  
as
	declare 
		@codP varchar(20), @cantitate float,@par xml,@id int,@codSemifabricat varchar(20),@poz bit	,@dataLans datetime,@termen varchar(10),
		@comandaLaComanda bit,@numarDoc int, @comLivr varchar(20), @tert varchar(20)

		set @dataLans=ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'),GETDATE())
		set @comLivr =	ISNULL(@parXML.value('(/parametri/@comLivr)[1]', 'varchar(20)'),'')
		set @tert=	ISNULL(@parXML.value('(/parametri/@tertul)[1]', 'varchar(20)'),'')
		set @numarDoc= isnull(@parXML.value('(/parametri/@numarDoc)[1]', 'int'),isnull((select max(detalii.value('(/row/@numarDoc)[1]', 'int'))+1 from poztehnologii where tip='L'),1))
		declare @min datetime,@minL datetime
		
		select @min=MIN(Termen) from con where Termen between @parXML.value('(/parametri/@dataJos)[1]', 'datetime') and @parXML.value('(/parametri/@dataSus)[1]', 'datetime') and stare='1' and tip='BK'
		set @minL=(select MIN(CONVERT(datetime,numar_de_inventar)) from comenzi inner join poztehnologii p on p.cod=comenzi.comanda and p.tip='L' where CONVERT(datetime,numar_de_inventar) between @parXML.value('(/parametri/@dataJos)[1]', 'datetime') and @parXML.value('(/parametri/@dataSus)[1]', 'datetime') and ISDATE(numar_de_inventar)=1)
		if @minL<@min
			set @min=@minL
			
		set @termen=CONVERT(varchar(10),@minL,101)			
		set @codP=ISNULL(@parXML.value('(/parametri/@cod)[1]', 'varchar(20)'),'')
		
		set @cantitate=ISNULL(@parXML.value('(/parametri/@cantitate)[1]', 'float'),'')
		
		
		--Multipla=1 adica e apelata din operatia de Lansare multipla
		if ISNULL(@parXML.value('(/parametri/@multipla)[1]', 'varchar(1)'),'' ) ='1' 
		begin
		set @par= (select @codP as codP, @cantitate as cantitate, 'CP' as tipL,
						@parXML.value('(/parametri/@dataJos)[1]', 'datetime') as dataJos, @parXML.value('(/parametri/@dataSus)[1]', 'datetime') as dataSus,
						@dataLans as dataLans,@termen as termen,@numarDoc as numarDoc, @comLivr as comLivr, '1' as dinFundamentare, @tert as tert
					for xml raw)
		exec wScriuPozLansari @sesiune, @par
		end
		else
		--Generare simpla (direct din operatia de generare comanda productie)
		begin
			declare con cursor for 
				select 
					RTRIM(c.Contract) as comanda,pc.cantitate as cantitate,c.tert
				from pozcon pc
				inner join con c on pc.Subunitate=c.Subunitate and pc.Tip=c.Tip and pc.Tert=c.Tert and pc.Contract=c.Contract
				where c.Tip='BK' and c.Stare=1 and c.termen between @parXML.value('(/parametri/@dataJos)[1]', 'datetime') and @parXML.value('(/parametri/@dataSus)[1]', 'datetime') 
				and pc.Cod=@codP and (select COUNT(1) from dependenteLans where contract=pc.Contract and cod=pc.Cod)=0
				
			open con
			declare @cantM float, @conM varchar(20)
			fetch next from con into @conM, @cantM, @tert
			
			while @@FETCH_STATUS= 0 
			begin
				set @par=(select @codP as codP, @cantM as cantitate, 'CP' as tipL,
						@parXML.value('(/parametri/@dataJos)[1]', 'datetime') as dataJos, @parXML.value('(/parametri/@dataSus)[1]', 'datetime') as dataSus,
						@dataLans as dataLans,@termen as termen,@numarDoc as numarDoc, @conM as comLivr, '1' as dinFundamentare, @tert as tert
					for xml raw)
				exec wScriuPozLansari @sesiune, @par					
				set @cantitate= @cantitate-@cantM
				fetch next from con into @conM, @cantM, @tert
			end
			
			close con
			deallocate con
			
			--Daca mai ramane cantitate din com sau con semifrab etc generez o comanda de productie
			if @cantitate > 0
			begin
				set @par=(select @codP as codP, @cantitate as cantitate, 'CP' as tipL,
							@parXML.value('(/parametri/@dataJos)[1]', 'datetime') as dataJos, @parXML.value('(/parametri/@dataSus)[1]', 'datetime') as dataSus,
							@dataLans as dataLans,@termen as termen,@numarDoc as numarDoc, '' as comLivr, '1' as dinFundamentare, '' as tert
						for xml raw)
				exec wScriuPozLansari @sesiune, @par	
			end	
		end
		
		*/