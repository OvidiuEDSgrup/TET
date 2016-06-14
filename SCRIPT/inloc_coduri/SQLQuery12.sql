exec sp_executesql N'/*
declare @cFurnBenef varchar(1),@cDataJos datetime,@cDataSus datetime,@cTert varchar(50),@cContTert varchar(20),@grupa varchar(50),
	@exc_grupa varchar(50),@cFactura varchar(40),@grfact varchar(40),@lm varchar(40),@comanda varchar(40),@cont_cor varchar(40),
	@tipinc varchar(40),@dataAnt datetime,@indicator varchar(40),@detTVA varchar(1)

select	@cFurnBenef=N''F'',@cDataJos=''2009-01-01 00:00:00'',@cDataSus=''2009-12-31 00:00:00'',@cTert=N''1185'',@cContTert=N''4091'',@grupa=NULL,
		@exc_grupa=NULL,@cFactura=NULL,@grfact=NULL,@lm=NULL,@comanda=NULL,@cont_cor=NULL,@tipinc=NULL,
		@indicator=NULL,@detTVA=N''1''
*/

exec rapFisaContTert @cFurnBenef=@cFurnBenef, @cDataJos=@cDataJos, @cDataSus=@cDataSus, @cTert=@cTert, @cContTert=@cContTert,
	@grupa=@grupa, @exc_grupa=@exc_grupa, @cFactura=@cFactura, @grfact=@grfact, @lm=@lm, @comanda=@comanda,
	@cont_cor=@cont_cor, @tipinc=@tipinc, @indicator=@indicator, @detTVA=@detTVA, @ordonare=@ordonare',N'@cFurnBenef nvarchar(1),@cDataJos datetime,@cDataSus datetime,@cTert nvarchar(4000),@cContTert nvarchar(5),@grupa nvarchar(4000),@exc_grupa nvarchar(4000),@cFactura nvarchar(4000),@grfact nvarchar(4000),@lm nvarchar(4000),@comanda nvarchar(4000),@cont_cor nvarchar(4000),@tipinc nvarchar(4000),@indicator nvarchar(4000),@detTVA nvarchar(1),@ordonare nvarchar(1)',@cFurnBenef=N'F',@cDataJos='2014-06-01 00:00:00',@cDataSus='2014-06-30 00:00:00',@cTert=NULL,@cContTert=N'401.1',@grupa=NULL,@exc_grupa=NULL,@cFactura=NULL,@grfact=NULL,@lm=NULL,@comanda=NULL,@cont_cor=NULL,@tipinc=NULL,@indicator=NULL,@detTVA=N'1',@ordonare=N'1'