exec sp_executesql N'/*	----- CG	Financiar	Documente pe terti
declare @cFurnBenef nvarchar(1),@cData datetime,@cTert nvarchar(4000),@cFactura nvarchar(4000),@cContTert nvarchar(4000),@soldmin nvarchar(1),@soldabs int,@dDataFactJos nvarchar(4000),@dDataFactSus nvarchar(4000),@dDataScadJos nvarchar(4000),@dDataScadSus nvarchar(4000),@aviz_nefac nvarchar(1),@grupa nvarchar(4000),@grupa_strict nvarchar(1),@exc_grupa nvarchar(4000),
		@fsolddata datetime, @comanda varchar(20), @indicator varchar(20), @locm varchar(20)
		
select @cFurnBenef=N''B'',@cData=''2011-09-14 00:00:00'',@cTert=NULL,@cFactura=NULL,@cContTert=NULL,@soldmin=N''0'',@soldabs=0,@dDataFactJos=NULL,
		@dDataFactSus=NULL,@dDataScadJos=NULL,@dDataScadSus=NULL,@aviz_nefac=N''0'',@grupa=NULL,@grupa_strict=N''0'',@exc_grupa=NULL
		--,@fsolddata=''2012-3-14''
		--, @locm=''140''
--*/

exec yso_rapDocVanzPeComisioaneIntermediari @cFurnBenef=@cFurnBenef, @cData=@cData, @cTert=@cTert,
			@cFactura=@cFactura, @cContTert=@cContTert, @locm=@locm, @soldmin=@soldmin, @soldabs=@soldabs,
			@dDataFactJos=@dDataFactJos, @dDataFactSus=@dDataFactSus, @dDataScadJos=@dDataScadJos, @dDataScadSus=@dDataScadSus,
			@aviz_nefac=@aviz_nefac, @grupa=@grupa, @grupa_strict=@grupa_strict, @exc_grupa=@exc_grupa,
			@fsolddata=@fsolddata, @comanda=@comanda, @indicator=@indicator, @punctLivrare=@punctLivrare, @tipdoc=@tipdoc',N'@cFurnBenef nvarchar(1),@cData datetime,@cTert nvarchar(9),@cFactura nvarchar(4000),@cContTert nvarchar(4000),@locm nvarchar(4000),@soldmin nvarchar(1),@soldabs int,@dDataFactJos nvarchar(4000),@dDataFactSus nvarchar(4000),@dDataScadJos nvarchar(4000),@dDataScadSus nvarchar(4000),@aviz_nefac nvarchar(1),@grupa nvarchar(4000),@grupa_strict nvarchar(1),@exc_grupa nvarchar(4000),@fsolddata nvarchar(4000),@comanda nvarchar(4000),@indicator nvarchar(4000),@punctLivrare nvarchar(4000),@tipdoc nvarchar(1)',@cFurnBenef=N'F',@cData='2016-05-31 00:00:00',@cTert=N'RO6380669',@cFactura=NULL,@cContTert=NULL,@locm=NULL,@soldmin=N'0',@soldabs=0,@dDataFactJos=NULL,@dDataFactSus=NULL,@dDataScadJos=NULL,@dDataScadSus=NULL,@aviz_nefac=N'0',@grupa=NULL,@grupa_strict=N'0',@exc_grupa=NULL,@fsolddata=NULL,@comanda=NULL,@indicator=NULL,@punctLivrare=NULL,@tipdoc=N'F'