exec sp_executesql N'/*
declare @cContTert nvarchar(4000),@grupa nvarchar(4000),@cTert nvarchar(8),@indicator nvarchar(4000),@locm nvarchar(4000)
select @cContTert='''',@grupa='''',@cTert=N''12751583'',@indicator='''',@locm=''''
*/

declare @p xml
set @p=(select	@cContTert as cont, @grupa as grupaTert, @cTert as tert, @locm as locm, @indicator as indicator,
				(case when @cTert is not null and @cFurnBenef=''B'' then @punctLivrare else null end) as punctLivrare,
				'''' as propLocm,
				convert(varchar(20),convert(datetime,''1901-1-1''),102) as datajos, convert(varchar(20),@cData,102) as datasus,
		'''' as intervalDocFinanciare for xml raw)
select parametru, convert(varchar(500),valoare) as valoare from fDenumiriRap('''',@p) --where parametru=''@rIntervalDocFinanciare''',N'@cContTert nvarchar(4000),@grupa nvarchar(4000),@cTert nvarchar(1),@locm nvarchar(4000),@indicator nvarchar(4000),@cFurnBenef nvarchar(1),@punctLivrare nvarchar(4000),@cData datetime',@cContTert=NULL,@grupa=NULL,@cTert=N' ',@locm=NULL,@indicator=NULL,@cFurnBenef=N'F',@punctLivrare=NULL,@cData='2016-05-09 00:00:00'