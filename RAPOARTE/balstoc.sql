/*exec sp_executesql N'/*	test
	declare @dDataJos datetime, @dDataSus datetime,@cCod varchar(20), @cGestiune varchar(20), @cCodi varchar(20), @cCont varchar(20),
		@TipStocuri varchar(20), @den varchar(20), @gr_cod varchar(20), @tip_pret varchar(1), @tiprap varchar(20)
	select @dDataJos=''2008-10-10'', @dDataSus=''2012-10-31'',@cCod=''122'', @cGestiune=null, @cCodi=null, --@cCont=''371'', 
			@TipStocuri=''''
		--@den=''%'', @gr_cod=null, 
		,@tip_pret=''0''
		/*select * from tmpRefreshLuci where
	(@dDataJos=''2008-1-1'' and  @dDataSus=''2009-10-1'' and @cCod=null and  @cGestiune=null and  @cCodi=null and  @cCont=null and  @TipStocuri=''M'' and 
		@den=''%'' and  @gr_cod=null) or 1=1
		*/ -- select pentru refresh fields in Reporting, ca sa nu se incurce in tabela #stocuri
	--*/
'*/
DECLARE @dDataJos datetime,@dDataSus datetime,@cCod nvarchar(4000),@cGestiune nvarchar(3),@cCodi nvarchar(4000),@cCont nvarchar(4000),@TipStocuri nvarchar(1),@den nvarchar(4000),@gr_cod nvarchar(4000),@tip_pret nvarchar(1),@tiprap nvarchar(1)
	select @dDataJos='2012-01-01 00:00:00',@dDataSus='2012-01-31 00:00:00',@cCod=NULL,@cGestiune=N'211',@cCodi=NULL,@cCont=NULL,@TipStocuri=N'',@den=NULL,@gr_cod=NULL,@tip_pret=N'0',@tiprap=N'D'
exec rapBalantaStocuri @dDataJos=@dDataJos, @dDataSus=@dDataSus, @cCod=@cCod, @cGestiune=@cGestiune, @cCodi=@cCodi, @cCont=@cCont,
		@TipStocuri=@TipStocuri, @den=@den, @gr_cod=@gr_cod, @tip_pret=@tip_pret, @tiprap=@tiprap
		