--***
/* procedura pentru populare macheta tip 'operatii' pentru registru electronic (Revisal) */
Create procedure wpopRegistruElectronic @sesiune varchar(50), @parXML xml 
as  

declare @data datetime, @Luna int, @An int, @datajos datetime, @datasus datetime, 
@codfiscal varchar(20), @tipsocietate varchar(60), @reprlegal varchar(100), @utilizator varchar(10)

exec wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator output

set @tipsocietate=dbo.iauParA('PS','ITMTIPSOC')
set @reprlegal=dbo.iauParA('PS','ITMNUME')
set @codfiscal=dbo.iauParA('PS','CODFISC')
if @codfiscal=''
	set @codfiscal=dbo.iauParA('GE','CODFISC')

select @Luna=month(getdate()), @An=year(getdate())
set @datajos=convert(datetime,str(@luna,2)+'/01/'+str(@an,4))
set @datasus=dbo.eom(convert(datetime,str(@luna,2)+'/01/'+str(@an,4)))
set @data=@datasus

select convert(char(10),@data,101) as data
	,@Luna as luna
	,@An as an
	,@datajos as datajos, @datasus as datasus
	,@codfiscal as codfiscal
	,rtrim(@tipsocietate) as tipsoc
	,rtrim(@reprlegal) reprlegal
for xml raw
