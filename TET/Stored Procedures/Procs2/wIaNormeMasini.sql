--***
create procedure wIaNormeMasini @sesiune varchar(50),@parXML XML      
as      
if exists(select * from sysobjects where name='wIaNormeMasiniSP' and type='P')      
	exec wIaNormeMasiniSP @sesiune,@parXML      
else      
begin
declare	@codMasina varchar(20)

select 
	@codMasina=ISNULL(@parXML.value('(/row/@codMasina)[1]', 'varchar(20)'), '')

DECLARE @coloane VARCHAR(max), @cTextSelect VARCHAR(max)

SELECT @coloane = COALESCE(@coloane,'') + 
'ltrim(str(SUM(CASE WHEN e.cod = ' + QUOTENAME(rtrim(e.cod),'''')+ ' THEN c.Valoare ELSE 0 END),10,2)) + '+CHAR(10)
+ '	MAX(CASE WHEN e.cod = ' + QUOTENAME(rtrim(e.cod),'''')+ ' THEN (case when e.um<>'''' then '' ''+RTRIM(e.UM) else '''' end )+
			(case when c.interval<>0 then ''/''+ convert(varchar,round(c.interval,2)) +'' ''+ 
				(case	when e.UM2 = ''D'' then ''Luni'' 
						when e.UM2 = ''A'' then rtrim(e.UM) 
						else RTRIM(e.um2) end) 
			ELSE '''' END)
		else '''' end)'+
' AS ' + QUOTENAME(replace(rtrim(e.cod),' ','_')) + ',' + CHAR(10)
FROM elemente e
left outer join coefmasini c on e.Cod=c.Coeficient and c.Masina=@codMasina
WHERE Tip<>'C'  
group by cod
order by cod
		
/* in caz ca rezultatul e null*/
set @coloane = coalesce(@coloane,''''' as nimic,'+char(10)) 		
/*elimin <enter> si , de la sfarsit*/
set @coloane = substring(@coloane,1,LEN(@coloane)-2) 

set @cTextSelect= N'select '+@coloane +'
FROM elemente e
inner join coefmasini c on e.Cod=c.Coeficient
WHERE Tip<>''C'' and c.Masina='+quotename(@codMasina,'''')+'
for xml raw'

--print @cTextSelect
exec (@cTextSelect)	

end

