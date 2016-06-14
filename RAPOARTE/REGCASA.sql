exec sp_executesql N'/*	CG\Financiar\Registru de casa.rdl
	declare @cont nvarchar(13),@datajos datetime,@datasus datetime,@utilizator nvarchar(4000),@jurnal nvarchar(4000),@valuta nvarchar(4000),@tipC nvarchar(200),
		@locm varchar(9)
	select @cont=N''5311.01'',@datajos=''2010-12-01 00:00:00'',@datasus=''2010-12-10 00:00:00'',@utilizator=NULL,@jurnal=NULL,@valuta=NULL
	,	@tipC=N''A'', @locm=''2''
	--*/

exec rapRegistruDeCasa @cont=@cont, @datajos=@datajos, @datasus=@datasus, @utilizator=@utilizator, @jurnal=@jurnal, 
			@valuta=@valuta, @tipC=@tipC, @locm=@locm',N'@cont nvarchar(4),@datajos datetime,@datasus datetime,@utilizator nvarchar(4000),@jurnal nvarchar(4000),@valuta nvarchar(4000),@tipC nvarchar(1),@locm nvarchar(4000)',@cont=N'5311',@datajos='2012-02-01 00:00:00',@datasus='2012-02-29 00:00:00',@utilizator=NULL,@jurnal=NULL,@valuta=NULL,@tipC=N'A',@locm=NULL