--***
create procedure ConturiRapTVA (@Populare int, @ConturiCapital char(1000), @ConturiRevanzare char(1000))
as begin
	if not exists (select 1 from sysobjects where type='U' and name='ContRapTVA')
		CREATE TABLE [dbo].[ContRapTVA](
		[HostID] [nchar](8) NOT NULL,
		[Tip] [nchar](1) NOT NULL,
		[Cont] [nchar](40) NOT NULL,
		CONSTRAINT [PK_ContRapTVA] PRIMARY KEY CLUSTERED 
		(
			[HostID] ASC,
			[Tip] ASC,
			[Cont] ASC
		) /*WITH (IGNORE_DUP_KEY = OFF)*/ ON [PRIMARY]
		) ON [PRIMARY]
 
	delete ContRapTVA where HostID=host_id()

	if @Populare=1
	begin
		insert ContRapTVA
		select host_id(), 'C', Item
		from dbo.Split(@ConturiCapital, ',')
		group by Item
  
		insert ContRapTVA
		select host_id(), 'R', Item
		from dbo.Split(@ConturiRevanzare, ',')
		group by Item
	end
end
