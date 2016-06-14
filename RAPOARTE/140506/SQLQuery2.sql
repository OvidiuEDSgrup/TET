REVERT
execute As login='TET\magazin.AG'
select SUSER_NAME()
exec sp_executesql N'exec yso_rapBorderouFacturi @datajos=@datajos, @datasus=@datasus,
		@datafjos=@datafjos,	@datafsus=@datafsus ,
		@ordonare=@ordonare,
		@avize_facturate=@avize_facturate,
		@tipfacturi=@tipfacturi,
		@gestiune=@gestiune,
		@loc_de_munca=@locm, @cont=@cont,
		@tipDoc=@tipDoc 
		/*,@jurnal=@jurnal,
		@delegat=@delegat,
		@facturiAnulate=@facturiAnulate*/',N'@datajos datetime,@datasus datetime,@locm nvarchar(4000),@cont nvarchar(4000),@datafjos nvarchar(4000),@datafsus nvarchar(4000),@ordonare nvarchar(1),@avize_facturate bit,@tipfacturi nvarchar(1),@gestiune nvarchar(4000),@tipDoc nvarchar(1)',@datajos='2014-04-01 00:00:00',@datasus='2014-04-30 00:00:00',@locm=NULL,@cont=NULL,@datafjos=NULL,@datafsus=NULL,@ordonare=N'1',@avize_facturate=0,@tipfacturi=N'0',@gestiune=NULL,@tipDoc=N'_'