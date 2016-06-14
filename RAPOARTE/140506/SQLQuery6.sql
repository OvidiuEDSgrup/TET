--/*
declare @cDataJos datetime, @cDataSus datetime, @cFurnBenef nvarchar(1), @cContTert nvarchar(4), @cTert nvarchar(4),@tipdoc nvarchar(1),@ordonare nvarchar(1),
		@compensari nvarchar(1),@centralizare nvarchar(1),@doar_facturi_pe_sold nvarchar(1)
select @cDataJos='2013-01-01',@cDataSus='2013-12-31',@cFurnBenef=N'B',@cContTert=NULL,@cTert=N'RO6602668',@tipdoc=N'X',@ordonare=N'0',@compensari=N'1'
	,@centralizare=N'1',@doar_facturi_pe_sold=N'0'--,@locm=NULL,@valuta=NULL
--*/

exec rapBalantaTerti @datajos=@cDataJos, @datasus=@cDataSus, @tip=@cFurnBenef, @cont=@cContTert, @tert=@cTert, @tipdoc=@tipdoc, 
		@ordonare=@ordonare, @compensari=@compensari, @centralizare=@centralizare, @doar_facturi_pe_sold=@doar_facturi_pe_sold, @locm=null,
		@valuta=null--@cDataJos datetime,@cDataSus datetime,@cFurnBenef nvarchar(1),@cContTert nvarchar(4000),@cTert nvarchar(9),@tipdoc nvarchar(1),@ordonare nvarchar(1),@compensari nvarchar(1),@centralizare nvarchar(1),@doar_facturi_pe_sold nvarchar(1),@locm nvarchar(4000),@valuta nvarchar(4000)
	
select * 
from dbo.fFacturi ('B', '2013-01-01', '2013-12-31', 'RO6602668', '%', null, 0, 0, 0, null, null) p