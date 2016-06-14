execute as login='tet\magazin.ag'
declare @datajos datetime,@datasus datetime,@locm nvarchar(6),@cont nvarchar(4000),@datafjos nvarchar(4000),@datafsus nvarchar(4000),@ordonare nvarchar(1),@avize_facturate bit,@tipfacturi nvarchar(1),@gestiune nvarchar(4000),@tipDoc nvarchar(2)
select @datajos='2013-07-01 00:00:00',@datasus='2013-07-31 00:00:00',@locm=null,@cont=NULL,@datafjos=NULL,@datafsus=NULL,@ordonare=N'1',@avize_facturate=0,@tipfacturi=N'0',@gestiune=null,@tipDoc=null

exec yso_rapBorderouFacturi @datajos=@datajos, @datasus=@datasus,
		@datafjos=@datafjos,	@datafsus=@datafsus ,
		@ordonare=@ordonare,
		@avize_facturate=@avize_facturate,
		@tipfacturi=@tipfacturi,
		@gestiune=@gestiune,
		@loc_de_munca=@locm, @cont=@cont,
		@tipDoc=@tipDoc 
		/*,@jurnal=@jurnal,
		@delegat=@delegat,
		@facturiAnulate=@facturiAnulate*/
GO