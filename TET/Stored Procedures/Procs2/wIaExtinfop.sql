--***
Create procedure wIaExtinfop @sesiune varchar(50), @parXML xml
as  
declare @_cautare varchar(100), @tip varchar(2), @tiptab varchar(2), @marca char(6), @userASiS varchar(10), @LunaInch int, @AnulInch int, @DataInch datetime

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
set @LunaInch=(case when dbo.iauParN('PS','LUNA-INCH')=0 then 1 else dbo.iauParN('PS','LUNA-INCH') end)
set @AnulInch=(case when dbo.iauParN('PS','ANUL-INCH')=0 then 1901 else dbo.iauParN('PS','ANUL-INCH') end)
set @DataInch=dbo.Eom(convert(datetime,str(@LunaInch,2)+'/01/'+str(@AnulInch,4)))

select @tip=xA.row.value('@tip', 'varchar(2)'), @tiptab=xA.row.value('@tiptab', 'varchar(2)'), @marca=xA.row.value('@marca', 'varchar(6)') 
from @parXML.nodes('row') as xA(row) 
select @_cautare=@parXML.value('(/row/@_cautare)[1]', 'varchar(100)')

select @tip as tip, (case when @tip='S' then @tiptab else @tip end) as subtip, 
	(case when @tip='AI' or @tiptab='AI' then 'Alte info. personal' when @tip='DP' then 'Date personal' else 'Informatii personal' end) as densubtip, 
	(case when @tip='AI' or @tiptab='AI' then (case when e.data_inf<>'01/01/1901' then '0' else '1' end) else '' end) as tipinfo,
	rtrim(e.marca) as marca, rtrim(e.Cod_inf) as cod, rtrim(c.Denumire) as denumire, rtrim(e.Val_inf) as valoare, 
	rtrim((case when c.Tip='V' and isnull(v.Descriere,'')<>'' then isnull(v.Descriere,'') else e.Val_inf end)) as descrvaloare, 
	convert(char(10),e.Data_inf,101) as data, convert(decimal(8,2),e.Procent) as procent, 
	(case when e.Data_inf<=@DataInch and e.Data_inf<>'01/01/1901' then '#808080' else '#000000' end) as culoare,
	(case when e.Data_inf<=@DataInch and e.Data_inf<>'01/01/1901' then 1 else 0 end) as _nemodificabil
from extinfop as e
	left outer join catinfop c on c.Cod=e.Cod_inf
	left outer join valinfopers v on v.Cod_inf=e.Cod_inf and v.Valoare=e.Val_inf
where e.Marca=@marca and e.Cod_inf not like '#'+'%' 
	and ((@tip='DP' or @tiptab='DP') and e.Data_inf<>'01/01/1901' or (@tip='IN' or @tiptab='IN') and e.Data_inf='01/01/1901' or (@tip='AI' or @tiptab='AI'))
	and e.Cod_inf not in ('NRSCARNET','TIPACTIDENT','PASAPORT','CETATENIE','NATIONALITATE','CODNATIONAL','PERMISMUNCA','MENTIUNI','CODSIRUTA','#CODCOR',
		'DATAINCH','CNTRITM','TEMEIINCET','TXTTEMEIINCET','CONTRDET','MMODIFCNTR','MODIFEXPL','DATAVALID','SALINLOCIN','SALINLOCSF',
		'RTIPACTIDENT','RCETATENIE','RCODNATIONAL','REPTIMPMUNCA','RTEMEIINCET','TIPINTREPTM')
	and e.Cod_inf not like 'SC%' and e.Cod_inf not like 'DET%' and e.Cod_inf not like 'AUT%'
	and (@_cautare is null or e.Cod_inf like '%'+rtrim(@_cautare)+'%' or c.Denumire like '%'+rtrim(@_cautare)+'%'
		or e.Val_inf like '%'+replace(rtrim(@_cautare),' ','%')+'%'
		or convert(char(10),e.Data_inf,103) like '%'+rtrim(@_cautare)+'%')
order by e.Cod_inf, e.Val_inf, e.Data_inf
for xml raw
