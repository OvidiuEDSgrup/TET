--***
Create procedure wIaCentralizatorFurnizorCod  @sesiune varchar(30), @parXML XML
as

declare @stareneaprobate varchar(1), @f_furnizor varchar(20), @f_gestiune varchar(20), @f_cod varchar(20), @f_comenzi varchar(20),
		@f_lm varchar(20), @datajos datetime, @datasus datetime, @cod varchar(20), @tip varchar(2), @subtip varchar(2), @f_dencod varchar(20),
		@aregestBK int, @utilizator varchar(40)
set @stareneaprobate='0'
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
set @aregestBK=(case when exists(select 1 from fPropUtiliz(@sesiune) where cod_proprietate='GESTBK' and valoare<>'') then 1 else 0 end)
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
        rtrim(max(n.Denumire)) as denumire,
        rtrim(max(c.gestiune)) as gestiune,
        RTRIM(max(g.Denumire_gestiune)) as dengestiune,
        SUM(cast (pc.cantitate as decimal(12,2))) as comandat,
        isnull(max(rtrim(tt.denumire)),'') as denfurn,
        isnull((select SUM(cast(st.stoc as decimal(12,2)))  from stocuri st where st.cod=pc.cod and Tip_gestiune='C' and Cod_gestiune='1'),0) as stoc,
        isnull((select (SUM(cast(st.stoc as decimal(12,2)))-SUM(cast(pc.cantitate as decimal(12,2)))) from stocuri st 
		where st.cod=pc.cod and st.Tip_gestiune='C' and Cod_gestiune='1'),-SUM(cast(pc.cantitate as decimal(12,2)))) as disponibil
from pozcon pc
inner join con c on pc.Subunitate=c.Subunitate and pc.Tip=c.Tip and pc.Tert=c.Tert and pc.Contract=c.Contract
left outer join nomencl n on pc.cod=n.cod
left outer join terti t on t.tert=c.Tert
left outer join gestiuni g on g.Cod_gestiune=c.Gestiune
left outer join terti tt on tt.Tert=n.Furnizor
left outer join fPropUtiliz(@sesiune) fp on cod_proprietate='GESTBK' and c.gestiune=fp.valoare
where c.Tip='BK' and c.Stare=@stareneaprobate
	  and (tt.Denumire like '%'+isnull(@f_furnizor,'')+'%' or @f_furnizor='')
	  and n.cod like '%'+isnull(@f_cod,'')+'%' 
	  and n.Denumire like '%'+isnull(@f_dencod,'')+'%' 
	  and (c.Gestiune like '%'+isnull(@f_gestiune,'')+'%' or g.Denumire_gestiune like '%'+isnull(@f_gestiune,'')+'%')
	  and (@aregestBK=0 or fp.valoare is not null)
	  and (pc.Cod=@cod or @cod='')	
	  group by pc.cod
for xml raw
