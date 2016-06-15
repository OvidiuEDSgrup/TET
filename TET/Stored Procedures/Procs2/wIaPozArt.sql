--***
create procedure wIaPozArt @sesiune varchar(50),@parXML XML      
as      
if exists(select * from sysobjects where name='wIaPozArtSP' and type='P')      
	exec wIaPozArtSP @sesiune,@parXML      
else      
begin
declare	@codarticol varchar(20), @tipresursa varchar(20),@codresursa varchar(20), @cantitate float, @pret float, 
		@cautare varchar(30)

set @codarticol = @parXML.value('(/row/@codarticol)[1]','varchar(100)')
set @codresursa = @parXML.value('(/row/row/@codresursa)[1]','varchar(100)')
set @tipresursa = @parXML.value('(/row/row/@tipresursa)[1]','varchar(100)')
Set @pret = isnull(@parXML.value('(/row/row/@pret)[1]','float'),'9999999')
Set @cantitate = isnull(@parXML.value('(/row/row/@cantitate)[1]','float'),'9999999')
set @cautare = '%'+replace(ISNULL(@parXML.value('(/row/@_cautare)[1]','varchar(100)'),'%'),' ','%')+'%'

Set @tipresursa = (case @tipresursa when 'Material' then 'M' when 'Manopera' then 'N' else left(@tipresursa,1) end)	

select top 100
rtrim(pa.cod_articol) as codarticol, 
rtrim(pa.cod_resursa) as codresursa, 
rtrim(n.denumire) as denumire, 
rtrim(pa.cantitate) as cantitate,
convert(decimal(12,2),n.pret_unitar) as pret,
--	rtrim(p.tip_resursa) as tipresursa,
	rtrim(pa.tip_resursa) as denres, 
(case when pa.Tip_resursa ='M' then 'Material' 
				  when pa.Tip_resursa ='N'  then 'Manopera' 
				  when pa.Tip_resursa ='U'  then 'Utilaj' 
				  when pa.Tip_resursa ='T'  then 'Transport' 
										    end)  as tipresursa

from pozart pa
	 inner join art a on a.cod_articol=pa.cod_articol
	 inner join nomres n on pa.cod_resursa=n.cod_resursa
where a.cod_articol=@codarticol
      and n.denumire like '%'+@cautare+'%'
      
order by n.denumire
for xml raw

end
