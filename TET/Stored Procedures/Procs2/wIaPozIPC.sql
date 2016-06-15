--***
create procedure wIaPozIPC @sesiune varchar(50), @parXML xml
as 
set transaction isolation level READ UNCOMMITTED
declare @datal datetime, @tip varchar(2) --, @userASiS varchar(10), @dataj datetime, @datas datetime, 
	
--exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
select @datal=xA.row.value('@datal', 'datetime'), @tip=xA.row.value('@tip', 'char(2)') 
	from @parXML.nodes('row') as xA(row) 

select @tip as tip, @tip as subtip, /*convert(char(10),a.Data,101) as data, */convert(char(4),a.An) as an, 
convert(decimal(10,0),a.Luna) as luna, convert(decimal(14,2),a.Indice_total) as indtotal, 
convert(decimal(14,2),a.Indice_mf_alim) as indmarfurialim, 
convert(decimal(14,2),a.Indice_mf_nealim) as indmarfurinealim, 
convert(decimal(14,2),a.Indice_servicii) as indservicii
FROM MF_ipc a 
WHERE Data=@datal
order by data, an, luna
for xml raw
