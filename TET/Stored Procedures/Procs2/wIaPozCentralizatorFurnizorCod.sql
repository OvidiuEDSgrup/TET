--***
Create procedure wIaPozCentralizatorFurnizorCod  @sesiune varchar(30), @parXML XML
as
declare @cod varchar(20), @tip varchar(20), @_cautare varchar(20), @subtip varchar(2), @stareneaprobate int
select @_cautare=isnull(@parXML.value('(/row/@_cautare)[1]', 'varchar(25)'),''),
	   @subtip=isnull(@parXML.value('(/row/@subtip)[1]', 'varchar(25)'),''),
	   @tip=isnull(@parXML.value('(/row/@tip)[1]', 'varchar(25)'),''),
	   @cod=isnull(@parXML.value('(/row/@cod)[1]', 'varchar(25)'),''),
	   @stareneaprobate=isnull(@parXML.value('(/row/@stareneaprobate)[1]', 'int'),0)
set @_cautare= '%'+REPLACE(@_cautare,' ','%')+'%'

select distinct top 100  rtrim(pc.contract) as comanda,
						 RTRIM(max((pc.Tert)))as tert,
						 rtrim(@tip) as tip,
						 'CI' as subtip,
						 isnull(RTRIM(max(t.denumire)),'') as dentert,
						 SUM(cast (pc.cantitate as decimal(12,2))) as comandat,
						 SUM(cast(pc.Cant_aprobata as decimal(12,2))) as aprobat,
						 RTRIM(max(c.Gestiune)) as gestiune,
						 RTRIM(max(g.Denumire_gestiune)) as dengestiune,
						 max(CONVERT(varchar(20),pc.Data,101)) as datacon,
						 max(c.loc_de_munca) as lm,
						 max(lm.Denumire) as denlm,
						 (case when SUM(cast (pc.cantitate as decimal(12,2)))>SUM(cast(pc.Cant_aprobata as decimal(12,2))) then 'red' 
						  when  SUM(cast (pc.cantitate as decimal(12,2)))<=SUM(cast(pc.Cant_aprobata as decimal(12,2))) then 'green' end) as culoare

			from pozcon pc
			inner join con c on pc.Subunitate=c.Subunitate and pc.Tip=c.Tip and pc.Tert=c.Tert and pc.Contract=c.Contract
			left outer join terti t on t.Tert=pc.Tert
			left outer join nomencl n on pc.cod=n.cod 
			left outer join gestiuni g on g.Cod_gestiune=c.Gestiune
			left outer join lm on lm.cod=c.loc_de_munca
			where c.tip='bk'  and pc.Cod=@cod and c.stare=@stareneaprobate
				 -- and t.denumire like @_cautare or @_cautare='' 
			group by pc.contract
			
for xml raw
