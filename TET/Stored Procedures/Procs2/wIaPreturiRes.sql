--***
create procedure wIaPreturiRes @sesiune varchar(50),@parXML XML      
as      
if exists(select * from sysobjects where name='wIaPreturiResSP' and type='P')      
	exec wIaPreturiResSP @sesiune,@parXML      
else      
begin
Declare @codresursa varchar(100), @tipresursa varchar(100), @denumire varchar(100),  @UM varchar(100), @pret float, 
        @datapret datetime,  @cautare varchar(30), @denres varchar(100)

Set @codresursa = isnull(@parXML.value('(/row/@codresursa)[1]','varchar(100)'),'')
Set @tipresursa = isnull(@parXML.value('(/row/@tipresursa)[1]','varchar(100)'),'')
set @cautare = '%'+replace(ISNULL(@parXML.value('(/row/@_cautare)[1]','varchar(100)'),'%'),' ','%')+'%'
Set @tipresursa = (case @tipresursa when 'Material' then 'M' when 'Manopera' then 'N' else left(@tipresursa,1) end)
/*Set @denres=  (case when @tipresursa ='M' then 'Material' 
				    when @tipresursa ='N' then 'Manopera' 
				    when @tipresursa ='U' then 'Utilaj' 
				    when @tipresursa ='T' then 'Transport' 
								   end)
*/
select top 100
	RTRIM(p.Cod_resursa) as codresursa,	
	rtrim(p.tip_resursa) as tipresursa,
	rtrim(p.tip_resursa) as denres, 
	RTRIM(p.tert) as tert,	
	rtrim(t.denumire) as dentert, 
	convert(decimal(12,2),p.pret) as pret,
	RTRIM ( convert(varchar(20),p.Data_pretului,101)) as datapret
	from ppreturi p	
	inner join terti t on t.tert=p.tert	-- and t.subunitate='1'
	--inner join nomres n on p.cod_resursa=n.cod_resursa and p.tip_resursa=n.Tip_resursa
	where p.cod_resursa=@codresursa and p.tip_resursa=@tipresursa
             and t.denumire like '%'+@cautare+'%'
      
--order by p.tert
for xml raw

end
