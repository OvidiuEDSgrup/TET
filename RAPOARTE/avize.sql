exec sp_executesql N'/*  --test
declare @datajos datetime,@datasus datetime,@tert nvarchar(4000),@cod nvarchar(4000),@gestiune nvarchar(4000),@lm nvarchar(4000),@factura nvarchar(4000),@comanda nvarchar(4000)
		,@Nivel1 varchar(2) ,@Nivel2 varchar(2) ,@Nivel3 varchar(2) ,@Nivel4 varchar(2), @Nivel5 varchar(2), @alfabetic int, @ordonare int
select @datajos=''2011-7-1 00:00:00'',@datasus=''2011-10-31 00:00:00'',@tert=null,@cod=NULL,@gestiune=NULL,@lm=NULL,@factura=NULL,@comanda=NULL
		,@Nivel1=''da''--, @Nivel2=''CO'', @Nivel3=''LU'', @Nivel4=''TE'', @Nivel5=null
		,@alfabetic=1	--*/

exec rapAvize	@datajos=@datajos, @datasus=@datasus, @tert=@tert, @cod=@cod,
					@gestiune=@gestiune, @lm=@lm, @factura=@factura, @comanda=@comanda,
				@Nivel1=@Nivel1, @Nivel2=@Nivel2, @Nivel3=@Nivel3, @Nivel4=@Nivel4, @Nivel5=@Nivel5, @ordonare=@ordonare',N'@datajos datetime,@datasus datetime,@tert nvarchar(4000),@cod nvarchar(4000),@gestiune nvarchar(4000),@lm nvarchar(4000),@factura nvarchar(4000),@comanda nvarchar(4000),@Nivel1 nvarchar(2),@Nivel2 nvarchar(2),@Nivel3 nvarchar(4000),@Nivel4 nvarchar(4000),@Nivel5 nvarchar(4000),@ordonare int',@datajos='2012-01-01 00:00:00',@datasus='2012-02-16 00:00:00',@tert=NULL,@cod=NULL,@gestiune=NULL,@lm=NULL,@factura=NULL,@comanda=NULL,@Nivel1=N'GE',@Nivel2=N'CO',@Nivel3=NULL,@Nivel4=NULL,@Nivel5=NULL,@ordonare=0