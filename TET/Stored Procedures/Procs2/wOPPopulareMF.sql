--***
/* procedura pentru populare machete de operatii */
create procedure wOPPopulareMF @sesiune varchar(50), @parXML xml 
as  
declare @sub varchar(9), @codMeniu varchar(2), @tip varchar(2), @subtip varchar(2), 
	@numar varchar(8), @data datetime, @nrinv varchar(13), @denmf varchar(80), 
	@Luna int, @An int, @datajos datetime, @datasus datetime, @lunainch int, @anulinch int, 
	@concl varchar(200), @termen datetime, @comisar1 char(15), @comisar2 char(15), 
	@comisar3 char(15), @comisar4 char(15)

set @sub=dbo.iauParA('GE','SUBPRO')

select @codMeniu=isnull(@parXML.value('(/row/@codMeniu)[1]','varchar(2)'),'')
select @tip=isnull(@parXML.value('(/row/@tip)[1]','varchar(2)'),'')
select @subtip=isnull(@parXML.value('(/row/row/@subtip)[1]','varchar(2)'),'')
select @numar=isnull(@parXML.value('(/row/row/@numar)[1]','varchar(8)'),'')
select @data=@parXML.value('(/row/row/@data)[1]','datetime')
select @data=isnull(@data,convert(datetime,convert(char(10),dbo.eom(getdate()),104),104))
set @lunainch=isnull((select max(val_numerica) from par where tip_parametru='MF' and 
	parametru='LUNAINCH'), isnull((select max(val_numerica) from par where tip_parametru='MF' and 
	parametru='LUNAI'), 1))
set @anulinch=isnull((select max(val_numerica) from par where tip_parametru='MF' and 
	parametru='ANULINCH'), isnull((select max(val_numerica) from par where tip_parametru='MF' and 
	parametru='ANULI'), 1901))
/*Select @luna=(case when @lunainch=12 then 1 else @lunainch+1 end),
@An=(case when @lunainch=12 then @anulinch+1 else @anulinch end)
if @lunainch not between 1 and 12 or @anulinch<=1901*/
Select @luna=month(getdate()), @An=year(getdate())
set @datajos=dateadd(month,0,convert(datetime,str(@luna,2)+'/01/'+str(@an,4)))
set @datasus=dbo.eom(dateadd(month,0,convert(datetime,str(@luna,2)+'/01/'+str(@an,4))))
if @codMeniu='MF' --and @tip='MI'
Begin
	select @nrinv=isnull(@parXML.value('(/row/row/@nrinv)[1]','varchar(13)'),'')
	select @denmf=Denumire from mfix where subunitate=@sub and Numar_de_inventar=@nrinv
	select @concl=observatii, @termen=data_expedierii, 
		@comisar1=left(numele_delegatului,15), @comisar2=substring(numele_delegatului,16,15), 
		@comisar3=left(eliberat,15), @comisar4=substring(eliberat,16,15) 
		from anexadoc where subunitate=@sub and Numar=@numar and data=@data
		and tip=(case right(@tip,1)+@subtip when 'IAF' then '1' when 'IPF' then '2' 
		when 'IPP' then '3' when 'IDO' then '4' when 'IAS' then '5' when 'ISU' then '6' 
		when 'IAL' then '7' else right(@tip,1)+Left(@subtip,1) end) 
End

select convert(char(10),@data,101) as data, @Luna as luna, @An as an, 
	convert(char(10),@datajos,101) as datajos, convert(char(10),@datasus,101) as datasus,
	(case when left(@codMeniu,1)='X' then 1 end) as stergdoc, 
	(case when left(@codMeniu,1)='X' then 1 end) as gendoc,
	(case when @codMeniu='MF' /*and @tip='MI' */then @nrinv end) as nrinv, 
	(case when @codMeniu='MF' /*and @tip='MI' */then @denmf end) as denmf, 
	(case when @codMeniu='MF' /*and @tip='MI' */then @concl end) as concl, 
	(case when @codMeniu='MF' /*and @tip='MI' */then convert(char(10),@termen,101) end) as termen, 
	(case when @codMeniu='MF' /*and @tip='MI' */then @comisar1 end) as comisar1, 
	(case when @codMeniu='MF' /*and @tip='MI' */then @comisar2 end) as comisar2, 
	(case when @codMeniu='MF' /*and @tip='MI' */then @comisar3 end) as comisar3, 
	(case when @codMeniu='MF' /*and @tip='MI' */then @comisar4 end) as comisar4
for xml raw
