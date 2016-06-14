/*	----- CG	Financiar	Documente pe terti
declare @cFurnBenef nvarchar(1),@cData datetime,@cTert nvarchar(4000),@cFactura nvarchar(4000),@cContTert nvarchar(4000),@soldmin nvarchar(1),@soldabs int,@dDataFactJos nvarchar(4000),@dDataFactSus nvarchar(4000),@dDataScadJos nvarchar(4000),@dDataScadSus nvarchar(4000),@aviz_nefac nvarchar(1),@grupa nvarchar(4000),@grupa_strict nvarchar(1),@exc_grupa nvarchar(4000),
		@fsolddata datetime, @comanda varchar(20), @indicator varchar(20), @locm varchar(20)
		
select @cFurnBenef=N'B',@cData='2011-09-14 00:00:00',@cTert=NULL,@cFactura=NULL,@cContTert=NULL,@soldmin=N'0',@soldabs=0,@dDataFactJos=NULL,
		@dDataFactSus=NULL,@dDataScadJos=NULL,@dDataScadSus=NULL,@aviz_nefac=N'0',@grupa=NULL,@grupa_strict=N'0',@exc_grupa=NULL
		--,@fsolddata='2012-3-14'
		--, @locm='140'
--*/

exec rapDocumentepeTerti @cFurnBenef=@cFurnBenef, @cData=@cData, @cTert=@cTert,
			@cFactura=@cFactura, @cContTert=@cContTert, @locm=@locm, @soldmin=@soldmin, @soldabs=@soldabs,
			@dDataFactJos=@dDataFactJos, @dDataFactSus=@dDataFactSus, @dDataScadJos=@dDataScadJos, @dDataScadSus=@dDataScadSus,
			@aviz_nefac=@aviz_nefac, @grupa=@grupa, @grupa_strict=@grupa_strict, @exc_grupa=@exc_grupa,
			@fsolddata=@fsolddata, @comanda=@comanda, @indicator=@indicator, @punctLivrare=@punctLivrare, @sursa=@sursa