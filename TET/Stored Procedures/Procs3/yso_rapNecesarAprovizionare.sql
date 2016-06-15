--declare/*
create procedure yso_rapNecesarAprovizionare --*/
	@Data_inf_vanzari1 datetime=NULL, @Data_sup_vanzari1 datetime=NULL
	,@Data_inf_vanzari2 datetime=NULL, @Data_sup_vanzari2 datetime=NULL
	,@Data_inf_vanzari3 datetime=NULL, @Data_sup_vanzari3 datetime=NULL
	,@Data_inf_aprovizionari datetime=NULL, @Data_sup_aprovizionari datetime=NULL
	,@Tert_furnizor nvarchar(4000)=NULL, @Grupa_articole nvarchar(4000)=NULL, @Cod_articol nvarchar(4000)=NULL
	,@Coeficient_aprovizionare float=1
	,@Locatii_stoc_excluse nvarchar(4000)=NULL
	,@Lista_gestiuni nvarchar(4000)=NULL
	,@Lista_gestiuni_depozit nvarchar(4000)=NULL
	,@Lista_gestiuni_de_aprovizionat nvarchar(4000)=NULL
/*
select @Data_inf_vanzari1='2013-10-12 00:00:00',@Data_sup_vanzari1='2013-11-12 00:00:00'
	,@Data_inf_vanzari2='2012-10-12 00:00:00',@Data_sup_vanzari2='2012-11-12 00:00:00'
	,@Data_inf_vanzari3='2012-11-12 00:00:00',@Data_sup_vanzari3='2012-12-12 00:00:00'
	,@Data_inf_aprovizionari=NULL,@Data_sup_aprovizionari=NULL,@Tert_furnizor=NULL,@Grupa_articole=NULL,@Cod_articol='00402100'
	,@Coeficient_aprovizionare=1,@Locatii_stoc_excluse=N'EXPOZITIE;EXPUNERE;MONTAT;MONTAJ'
	,@Lista_gestiuni=NULL,@Lista_gestiuni_depozit=N'101;102;104',@Lista_gestiuni_de_aprovizionat='210.NT;211.NT'
--*/as

--select @Data_inf_vanzari1=ISNULL(@Data_inf_vanzari1,DATEADD(m,-1,getdate())),@Data_sup_vanzari1=ISNULL(@Data_sup_vanzari1,getdate())
--		,@Data_inf_vanzari2=ISNULL(@Data_inf_vanzari2,DATEADD(m,-13,getdate())),@Data_sup_vanzari2=ISNULL(@Data_sup_vanzari2,DATEADD(m,-12,getdate()))
--		,@Data_inf_vanzari3=ISNULL(@Data_inf_vanzari3,DATEADD(m,-12,getdate()+1)),@Data_sup_vanzari3=ISNULL(@Data_sup_vanzari3,DATEADD(m,-11,getdate()+1))
--		,@Data_inf_aprovizionari=ISNULL(@Data_inf_aprovizionari,''), @Data_sup_aprovizionari=ISNULL(@Data_sup_aprovizionari,GETDATE())

select @Lista_gestiuni = isnull(@Lista_gestiuni,'')+isnull(';'+@Lista_gestiuni_depozit,'')+isnull(';'+@Lista_gestiuni_de_aprovizionat,'') 

;with dateBaza as
(select sursa='NG'
	,cod=rtrim(n.Cod), gestiune=rtrim(g.Cod_gestiune)
	,sl.Stoc_min, sl.Stoc_max
	,Stoc=convert(float,0)
	,Stoc_depozit=convert(float,0)
	,Stoc_de_aprovizionat=convert(float,0)
	,cant_vanzari1=convert(float,0)
	,cant_vanzari2=convert(float,0)
	,cant_vanzari3=convert(float,0)
	,cant_aprov_operate=convert(float,0)
	,cant_aprov_definitive=convert(float,0)
from nomencl n
	inner join gestiuni g on g.Subunitate='1' and g.Tip_gestiune not in ('I','O','V')
	outer apply (select top 1 * from stoclim sl where sl.Subunitate='1' and sl.Tip_gestiune=g.Tip_gestiune and sl.Cod_gestiune=g.Cod_gestiune 
		and sl.Cod=n.Cod and sl.Data<=GETDATE() order by sl.Data desc) sl
where n.Tip IN ('M','A','P')
	and (@Lista_gestiuni_de_aprovizionat = '' or g.Cod_gestiune in (select f.string from dbo.fSplit(@Lista_gestiuni_de_aprovizionat,';') f))

union all
select sursa='ST'
	,cod=rtrim(s.cod), gestiune=rtrim(s.Cod_gestiune)
	,Stoc_min=0, Stoc_max=0
	,s.Stoc
	,Stoc_depozit=(case when s.Cod_gestiune in (select f.string from dbo.fSplit(@Lista_gestiuni_depozit,';') f) then s.Stoc else 0 end)
	,Stoc_de_aprovizionat=(case when s.Cod_gestiune in (select f.string from dbo.fSplit(@Lista_gestiuni_de_aprovizionat,';') f) then s.Stoc else 0 end)
	,cant_vanzari1=0
	,cant_vanzari2=0
	,cant_vanzari3=0
	,cant_aprov_operate=0
	,cant_aprov_definitive=0
from stocuri s --inner join nomencl n on n.Cod=s.Cod
where s.Subunitate='1' and s.Locatie not in (select f.string from dbo.fSplit(@Locatii_stoc_excluse,';') f)
	and (@Lista_gestiuni = '' or s.Cod_gestiune in (select f.string from dbo.fSplit(@Lista_gestiuni,';') f))

union all
select sursa='VZ'
	,cod=rtrim(vz.cod), gestiune=rtrim(vz.Gestiune)
	,Stoc_min=0, Stoc_max=0
	,Stoc=0, Stoc_depozit=0, Stoc_de_aprovizionat=0
	,cant_vanzari1=(case when vz.Data between @Data_inf_vanzari1 and @Data_sup_vanzari1 then vz.Cantitate else 0 end)
	,cant_vanzari2=(case when vz.Data between @Data_inf_vanzari2 and @Data_sup_vanzari2 then vz.Cantitate else 0 end)
	,cant_vanzari3=(case when vz.Data between @Data_inf_vanzari3 and @Data_sup_vanzari3 then vz.Cantitate else 0 end)
	,cant_aprov_operate=0
	,cant_aprov_definitive=0
from pozdoc vz --inner join nomencl n on n.Cod=vz.Cod
where vz.Subunitate='1' and vz.Tip in ('AP','AC') and left(vz.Cont_venituri,3) in ('707','709') 
	and (vz.Data between @Data_inf_vanzari1 and @Data_sup_vanzari1
		or vz.Data between @Data_inf_vanzari2 and @Data_sup_vanzari2
		or vz.Data between @Data_inf_vanzari3 and @Data_sup_vanzari3)
	and (@Lista_gestiuni_de_aprovizionat = '' or vz.Gestiune in (select f.string from dbo.fSplit(@Lista_gestiuni_de_aprovizionat,';') f))

union all
select sursa='FC'
	,cod=rtrim(fc.cod), gestiune=rtrim(fc.Factura)
	,Stoc_min=0, Stoc_max=0
	,Stoc=0, Stoc_depozit=0, Stoc_de_aprovizionat=0
	,cant_vanzari1=0
	,cant_vanzari2=0
	,cant_vanzari3=0
	,cant_aprov_operate=(case c.Stare when '0' then fc.Cantitate-fc.Cant_realizata else 0 end)
	,cant_aprov_definitive=(case c.Stare when '1' then fc.Cantitate-fc.Cant_realizata else 0 end)
from pozcon fc 
	inner join con c on c.Subunitate=fc.Subunitate and c.Tip=fc.Tip and c.Contract=fc.Contract and c.Data=fc.Data and c.Tert=fc.tert
	--inner join nomencl n on n.Cod=fc.Cod
where fc.Subunitate='1' and fc.Tip='FC' and c.Stare in ('0','1')
	and fc.Data between @Data_inf_aprovizionari and @Data_sup_aprovizionari
	and (@Lista_gestiuni = '' or fc.Factura in (select f.string from dbo.fSplit(@Lista_gestiuni,';') f))
)
select b.*
	,den_articol=RTRIM(n.Denumire)
	,den_gestiune=RTRIM(g.Denumire_gestiune)
	,tip_articol=RTRIM(n.Tip), den_tip_articol=dbo.denTipNomenclator(n.tip)
	,grupa_articole=RTRIM(n.Grupa), den_grupa_articole=RTRIM(ga.Denumire)
	,furnizor=RTRIM(n.Furnizor), den_furnizor=RTRIM(f.Denumire)
from dateBaza b
	inner join nomencl n on n.Cod=b.Cod
	inner join gestiuni g on g.Cod_gestiune=b.gestiune
	left join terti f on f.Subunitate='1' and f.Tert=n.Furnizor
	left join grupe ga on ga.Tip_de_nomenclator=n.Tip and ga.Grupa=n.Grupa
where n.Tip IN ('M','A','P')
	and (@Cod_articol is null or b.Cod like RTRIM(@Cod_articol))
	and (@Grupa_articole is null or n.Grupa like RTRIM(@Grupa_articole))
	and (@Tert_furnizor is null or n.Furnizor=@Tert_furnizor)

	