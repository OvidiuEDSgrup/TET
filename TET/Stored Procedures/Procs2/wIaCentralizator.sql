--***
create procedure wIaCentralizator  @sesiune varchar(30), @parXML XML
as
if exists (select 1 from sysobjects where [type]='P' and [name]='wIaCentralizatorSP')
begin 
	declare @returnValue int 
	exec @returnValue = wIaCentralizatorSP @sesiune, @parXML output
	return @returnValue
end

RAISERROR('Aceasta procedura nu este testata. Pentru situatii urgente, testati si dezvoltati o procedura specifica.', 11, 1)

declare @stareneaprobate varchar(1), @f_furnizor varchar(20), @f_gestiune varchar(20), @f_cod varchar(20), @f_comenzi varchar(20),
		@f_lm varchar(20), @datajos datetime, @datasus datetime, @cod varchar(20), @tip varchar(2), @subtip varchar(2), @f_dencod varchar(20)
set @stareneaprobate='0'
select @f_cod = isnull(@parXML.value('(/row/@f_cod)[1]','varchar(20)'),''),
	   @f_furnizor = isnull(@parXML.value('(/row/@f_furnizor)[1]','varchar(20)'),''),
	   @f_gestiune = isnull(@parXML.value('(/row/@f_gestiune)[1]','varchar(20)'),''),
	   @f_dencod = isnull(@parXML.value('(/row/@f_dencod)[1]','varchar(20)'),''),
	   @datajos = isnull(@parXML.value('(/row/@datajos)[1]','datetime'),'1900-01-01'),
	   @datasus = isnull(@parXML.value('(/row/@datasus)[1]','datetime'),'1900-01-01'),
	   @cod = isnull(@parXML.value('(/row/@cod)[1]','varchar(20)'),''),
	   @tip = isnull(@parXML.value('(/row/@tip)[1]','varchar(20)'),''),
	   @subtip = isnull(@parXML.value('(/row/@subtip)[1]','varchar(20)'),'')
	   
select  rtrim(pc.cod) as cod,
		RTRIM(@tip) as tip,
		rtrim(@subtip) as subtip,
		RTRIM(@stareneaprobate) as stareneaprobate,
        rtrim(n.Denumire) as denumire,
        RTRIM(max(g.Denumire_gestiune)) as dengestiune,
        SUM(cast (pc.cantitate as decimal(12,2))) as comandat,
        max(rtrim(tt.denumire)) as denfurn,
        isnull((select SUM(cast(st.stoc as decimal(12,2)))  from stocuri st where st.cod=pc.cod and Tip_gestiune='C' and Cod_gestiune='1'),0) as stoc,
        isnull((select (SUM(cast(st.stoc as decimal(12,2)))-SUM(cast(pc.cantitate as decimal(12,2)))) from stocuri st 
		where st.cod=pc.cod and st.Tip_gestiune='C' and Cod_gestiune='1'),-SUM(cast(pc.cantitate as decimal(12,2)))) as disponibil
		
from pozcon pc
inner join con c on pc.Subunitate=c.Subunitate and pc.Tip=c.Tip and pc.Tert=c.Tert and pc.Contract=c.Contract
inner join nomencl n on pc.cod=n.cod
inner join terti t on t.tert=c.Tert
inner join gestiuni g on g.Cod_gestiune=c.Gestiune
inner join terti tt on tt.Tert=n.Furnizor
where c.Tip='BK' and c.Stare=@stareneaprobate
	  and tt.Denumire like '%'+isnull(@f_furnizor,'')+'%'
	  and n.cod like '%'+isnull(@f_cod,'')+'%' 
	  and n.Denumire like '%'+isnull(@f_dencod,'')+'%' 
	  and (c.Gestiune like '%'+isnull(@f_gestiune,'')+'%' or g.Denumire_gestiune like '%'+isnull(@f_gestiune,'')+'%')
	  and (pc.Cod=@cod or @cod='')
	  group by n.denumire,pc.cod
for xml raw
