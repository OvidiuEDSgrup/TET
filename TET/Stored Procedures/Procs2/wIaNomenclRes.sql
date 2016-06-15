--***
create procedure wIaNomenclRes @sesiune varchar(50), @parXML XML
as
if exists(select * from sysobjects where name='wIaNomenclResSP' and type='P')
	exec wIaNomenclResSP @sesiune, @parXML
else      
begin
set transaction isolation level READ UNCOMMITTED

--Declarare variabile 
Declare @codresursa varchar(100), @tipresursa varchar(100), @denumire varchar(100),  @UM varchar(100), @pret float, 
        --@pretjos float, @pretsus float, 
        @denres varchar(100), @greutate float

Set @codresursa = '%'+isnull(@parXML.value('(/row/@codresursa)[1]','varchar(100)'),'')+'%'
Set @tipresursa = '%'+isnull(@parXML.value('(/row/@tipresursa)[1]','varchar(100)'),'')+'%'
Set @denumire = '%'+isnull(@parXML.value('(/row/@denumire)[1]','varchar(100)'),'')+'%'
Set @UM = isnull(@parXML.value('(/row/@um)[1]','varchar(100)'),'')
Set @pret = isnull(@parXML.value('(/row/@pret)[1]','float'),'9999999')
Set @greutate = isnull(@parXML.value('(/row/@greutate)[1]','float'),'9999999')

Set @denres=  (case when @tipresursa ='M' then 'Material' 
				    when @tipresursa ='N' then 'Manopera' 
				    when @tipresursa ='U' then 'Utilaj' 
				    when @tipresursa ='T' then 'Transport' 
										   end)

select top 100
	RTRIM(n.Cod_resursa) as codresursa,	
   (case when n.Tip_resursa ='M' then 'Material' 
				  when n.Tip_resursa ='N'  then 'Manopera' 
				  when n.Tip_resursa ='U'  then 'Utilaj' 
				  when n.Tip_resursa ='T'  then 'Transport' 
										   end)  as tipresursa,
										   
    rtrim(n.tip_resursa) as denres, 
	RTRIM(n.Denumire) as denumire,	
	RTRIM(n.UM) as um,	
	convert(decimal(12,2),n.pret_unitar) as pret,
	convert(decimal(12,2),n.greutate) as greutate
	from nomres	n		
	left join um u on n.um=u.um					 
				  where  --n.cod_Resursa=@codresursa and
				  -- n.Pret_unitar =@pret or @pret=999999999
				        n.cod_resursa like @codresursa
				        and n.tip_resursa like @tipresursa
					    and n.denumire like @denumire                  
				            			            
				order by n.cod_Resursa
for xml raw
end

