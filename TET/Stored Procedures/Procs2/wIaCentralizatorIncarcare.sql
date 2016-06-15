--***
create procedure wIaCentralizatorIncarcare @sesiune varchar(30), @parXML XML
as
declare @datajos datetime, @datasus datetime, @f_lm varchar(20), @f_comanda varchar(20), @f_tert varchar(20),@f_gest varchar(20), @f_nrtr varchar(20)
select @datajos = isnull(@parXML.value('(/row/@datajos)[1]','datetime'),'1900-01-01'),
	   @datasus = isnull(@parXML.value('(/row/@datasus)[1]','datetime'),'2900-01-01'),
	   @f_lm = isnull(@parXML.value('(/row/@f_lm)[1]','varchar(20)'),''),
	   @f_tert = isnull(@parXML.value('(/row/@f_tert)[1]','varchar(20)'),''),
	   @f_comanda = isnull(@parXML.value('(/row/@f_comanda)[1]','varchar(20)'),''),
	   @f_gest = isnull(@parXML.value('(/row/@f_gest)[1]','varchar(20)'),''),
	   @f_nrtr = isnull(@parXML.value('(/row/@f_nrtr)[1]','varchar(20)'),'')
	   
select 
    distinct top 100
    rtrim(pc.contract) as comanda, 
    rtrim(convert(varchar(20),pc.data,101)) as datacon, 
    rtrim(pc.tert) as tert, 
    rtrim(t.denumire) as dentert,
    rtrim(lm.Cod) as lm, 
    rtrim(upper(lm.Denumire)) as denlm,
    RTRIM(t.Adresa) as adresa,
    RTRIM(c.Gestiune) as gestiune,
    RTRIM(g.Denumire_gestiune) as dengestiune,
    (case when c.mod_penalizare='' then 'Fara transport' else RTRIM(c.Mod_penalizare) end) as nrtransport
from pozcon pc
inner join con c on pc.Subunitate=c.Subunitate and pc.Tip=c.Tip and pc.Tert=c.Tert and pc.Contract=c.Contract
inner join nomencl n on pc.cod=n.cod
inner join terti t on t.tert=c.Tert
inner join gestiuni g on g.Cod_gestiune=c.Gestiune
left outer join lm on lm.Cod=c.Loc_de_munca
where c.Tip='BK' and c.Stare=1
     and c.data between @datajos and @datasus 
     and lm.Denumire like '%'+isnull(@f_lm,'')+'%' 
     and pc.Contract like '%'+isnull(@f_comanda,'')+'%'
     and t.denumire like '%'+isnull(@f_tert,'')+'%'
     and g.Denumire_gestiune like '%'+isnull(@f_gest,'')+'%'
     and c.Mod_penalizare like '%'+isnull(@f_nrtr,'')+'%'
for xml raw

