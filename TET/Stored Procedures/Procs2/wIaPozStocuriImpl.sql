--***
create procedure [dbo].wIaPozStocuriImpl @sesiune varchar(30), @parXML XML
AS    
	Declare @sub varchar(9), @marca varchar(9),@cod_gestiune varchar(13),@data_lunii datetime,@doc xml,@an_impl int,@luna_impl int,@mod_impl int,@data_impl datetime,
		@tip_gestiune varchar(1),@data_jos datetime,@data_sus datetime,@tip varchar(2),@flt_gestiune varchar(50),@_cautare varchar(50)

select  @tip=isnull(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''), 
		@cod_gestiune=isnull(@parXML.value('(/row/@cod_gestiune)[1]', 'varchar(13)'), ''), 
		@tip_gestiune=isnull(@parXML.value('(/row/@tip_gestiune)[1]', 'varchar(13)'), ''),
		@tip=isnull(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
		@data_jos=isnull(@parXML.value('(/row/@datajos)[1]', 'datetime'), '1901-01-01') ,
		@data_sus=isnull(@parXML.value('(/row/@datasus)[1]', 'datetime'), '2901-01-01') ,
		@data_lunii=isnull(@parXML.value('(/row/@data_lunii)[1]', 'datetime'), '1901-01-01'),
		@_cautare=isnull(@parXML.value('(/row/@_cautare)[1]', 'varchar(50)'), '') 

set @data_impl='1901-01-01'	

	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output		
	exec luare_date_par 'GE', 'ANULIMPL', 0, @an_impl output, ''
	exec luare_date_par 'GE', 'LUNAIMPL', 0, @luna_impl output, ''
	exec luare_date_par 'GE', 'IMPLEMENT', @mod_impl output, 0, ''

if @an_impl<>0
	set @data_impl=dbo.EOM(convert(datetime,str(@luna_impl,2)+'/01/'+str(@an_impl,4),101))
	
set @doc=(
select top 100 @tip as tip, a.Tip_gestiune as tip_gestiune, rtrim(a.Cod_gestiune) as cod_gestiune, RTRIM(a.cod) as cod, RTRIM(a.cont) as cont, RTRIM(ct.Denumire_cont) as dencont,
		convert(varchar(10),a.Data,101) as data, convert(varchar(10),a.Data_lunii,101) as data_lunii, 
		convert(decimal(12,4),a.Pret) as pret, RTRIM(cod_intrare) as codintrare, convert(varchar(10),a.Data_expirarii,101) as data_expirarii,
		convert(decimal(12,4),a.Pret_vanzare) as pret_vanzare, convert(decimal(12,4),a.Stoc_UM2) as stoc_UM2, convert(decimal(12,4),a.stoc) as stoc, RTRIM(a.lot) as lot,
		convert(decimal(12,2),TVA_neexigibil) as tva_neexigibil, RTRIM(a.Loc_de_munca) as lm, RTRIM(lm.Denumire) as denlm, RTRIM(n.denumire) as denumire, RTRIM(a.furnizor) as furnizor,
		RTRIM(a.Comanda) as comanda, RTRIM(c.Descriere) as dencomanda, RTRIM(contract) as contract, convert(decimal(12,4),a.Pret_cu_amanuntul) as pret_cu_amanuntul,-- a.Pret_cu_amanuntul) as pret_cu_amanuntul,
		RTRIM(a.Locatie) as locatie ,rtrim(t.Denumire) as denfurnizor, rtrim(a.cod)+'-'+rtrim(n.Denumire) as cod_de, (case when a.stoc<>0 then n.um else n.UM_1 end) as um, 
		(case when a.Stoc_UM2=0 then 1 else 2 end) as stoc_um,
		(case when a.stoc <> 0 then convert(decimal(12,4),a.stoc) else convert(decimal(12,4),a.Stoc_UM2) end) as stoc_f, rtrim(p.Nume) as denmarca,
		(case when n.UM_2='Y' then 'MS' else 
				(case when (a.Data_lunii<=@data_impl and a.Tip_gestiune='F') then 'OF'
					  when (a.Data_lunii>@data_impl and a.Tip_gestiune='F') then 'OI'
					   else 'SI'end) end) as subtip,	
		(case when n.UM_2='Y' then 2 else 1 end) as ordine,
		
		(select RTRIM(pds.gestiune) as gestiune, RTRIM(pds.cod) as cod, rtrim(pds.Cod)+'-'+rtrim(n.Denumire) as dencod, RTRIM(pds.cod_intrare) as codintrareS, rtrim(pds.Serie) as cod_de,   
					CONVERT(decimal(12,3),pds.stoc) as stoc_f, rtrim(isnull(n.UM, '')) as um, '#08088A' as culoare, convert(varchar(10),pds.data_lunii,101) as data_lunii, RTRIM(pds.Serie) as serie,
					(case when charindex(',',pds.Serie)<>0 then SUBSTRING(pds.serie,charindex(',',pds.Serie)+1,LEN(pds.Serie)-charindex(',',pds.serie)) else '' end) as prop2,
					(case when charindex(',',pds.Serie)<>0 then SUBSTRING(pds.Serie,1,charindex(',',pds.Serie)-1) else RTRIM(pds.Serie) end) as prop1 ,
					(case when charindex(',',pds.Serie)<>0 then SUBSTRING(pds.serie,charindex(',',pds.Serie)+1,LEN(pds.Serie)-charindex(',',pds.serie)) else '' end) as denprop2,
					(case when charindex(',',pds.Serie)<>0 then SUBSTRING(pds.Serie,1,charindex(',',pds.Serie)-1) else RTRIM(pds.Serie) end) as denprop1,
				--(case when YEAR(@data_lunii)<>@an_impl and MONTH(@data_lunii)<>@luna_impl then 1 else 0 end) as _nemodificabil,
					'SE' as subtip, CONVERT(decimal(12,3),pds.stoc) as stoc
			 from istoricserii pds
				left join nomencl n on n.Cod=pds.Cod
			 where a.subunitate=pds.Subunitate and pds.Cod=a.Cod and pds.Cod_intrare=a.Cod_intrare
			 order by pds.Serie
			 for xml raw,type),	
		rtrim(@_cautare) as _cautare
from istoricstocuri a 
		left outer join nomencl n on n.Cod=a.cod
		left outer join lm on lm.Cod=a.Loc_de_munca
		left outer join personal p on p.Marca=a.Cod_gestiune and a.Tip_gestiune='F'
		left outer join terti t on t.Subunitate=@sub and a.Furnizor=t.Tert
		left outer join comenzi c on c.Subunitate=@sub and c.Comanda=a.Comanda
		left outer join conturi ct on ct.Subunitate=@sub and ct.Cont=a.Cont
where a.Data_lunii =@data_lunii
	and a.Cod_gestiune=@cod_gestiune
  --and (@tip_gestiune=a.Tip_gestiune or @tip_gestiune<>'F')
  --and ((a.Data_lunii between @data_jos and @data_sus) or (@tip<>'SU' and @tip<>'OI'))	
	and (isnull(@_cautare,'')='' or a.Cod like @_cautare+'%' 
		or (rtrim(n.Denumire) like '%'+@_cautare+'%'))
order by ordine,a.Data desc
for xml raw,root('Ierarhie')
	)
select @doc for xml path('Date')	
--select * from serii
--select * from istoricstocuri where tip_gestiune='F'
