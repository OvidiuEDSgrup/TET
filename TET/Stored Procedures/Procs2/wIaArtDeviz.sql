--***
create procedure wIaArtDeviz @sesiune varchar(50), @parXML XML
as
if exists(select * from sysobjects where name='wIaArtDevizSP' and type='P')
	exec wIaArtDevizSP @sesiune, @parXML
else      
begin
set transaction isolation level READ UNCOMMITTED

--Declarare variabile 
Declare @codarticol varchar(20), @denumire varchar(100),  @UM varchar(3),  @subcapitol varchar(20) ,
        @prettotal float, @prettotalj float, @prettotals float

Set @codarticol = '%'+isnull(@parXML.value('(/row/@codarticol)[1]','varchar(20)'),'')+'%'
Set @denumire = '%'+isnull(@parXML.value('(/row/@denumire)[1]','varchar(100)'),'')+'%'
Set @UM = isnull(@parXML.value('(/row/@UM)[1]','varchar(3)'),'')
Set @subcapitol = isnull(@parXML.value('(/row/@subcapitol)[1]','varchar(20)'),'')
Set @prettotal = isnull(@parXML.value('(/row/@prettotal)[1]','float'),999999999)

--Set @prettotals = isnull(@parXML.value('(/row/@prettotals)[1]','float'),'9999999')
--Set @prettotalj = isnull(@parXML.value('(/row/@prettotalj)[1]','float'),'-9999999')

select top 100
	RTRIM(max(a.Cod_articol)) as codarticol,
	RTRIM(max(a.Denumire)) as denumire,	
	RTRIM(max(a.UM)) as um,
	--rtrim(max(u.denumire)) as denum,  
	RTRIM(max(a.subcapitol)) as subcapitol,
	--CONVERT(decimal(12,2),max(n.Pret_unitar)) as pret,
	--CONVERT(decimal(12,2),max(pa.cantitate)) as cantitate,
	sum(CONVERT(decimal(12,2),pa.Cantitate*n.Pret_unitar)) as prettotal 
	from art a			
	inner join um u on a.um=u.um		
	left join pozart pa on a.cod_articol=pa.cod_articol		
	left join nomres n on n.cod_resursa=pa.cod_resursa	
		-- where pa.cod_resursa=n.cod_resursa and pa.tip_resursa=n.tip_resursa --and t.tert=p.tert			 
			where	a.cod_articol like @codarticol
					    and a.denumire like @denumire
					    --and a.UM like @um
					    -- and a.subcapitol like @subcapitol
					   -- and ((pa.Cantitate)*(n.Pret_unitar) =@prettotal or @prettotal=999999999)					    
					  --  and (@prettotal between @prettotalj and @prettotals)				
			--group by pa.cantitate, n.pret_unitar
			group by a.cod_articol
			order by a.cod_articol
for xml raw
end

