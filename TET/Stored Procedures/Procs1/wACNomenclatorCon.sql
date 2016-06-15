--***
create procedure wACNomenclatorCon @sesiune varchar(50),@parXML XML      
as      
if exists(select * from sysobjects where name='wACNomenclatorConSP' and type='P')      
	exec wACNomenclatorConSP @sesiune,@parXML      
else      
begin
	declare @FltStocPred int, @searchText varchar(80), @subunitate varchar(9), @tip varchar(2), @gestiune varchar(20),@gestutiliz varchar(20), @categoriePret int
	declare @aplicatie varchar(100), @subtip varchar(2),@numar varchar(10),@tert varchar(20),@data datetime,@sursa varchar(13)
	declare @utilizator varchar(10)
	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	IF @utilizator IS NULL
		RETURN -1


	exec luare_date_par 'GE', 'FNOMPRED', @FltStocPred output, 0, ''
	
	declare @lista_gestiuni int
	set @lista_gestiuni=(case when exists (select 1 from proprietati 
		where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='GESTIUNE' and Valoare<>'') then 1 else 0 end)

	select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''), 
		@subunitate=ISNULL(@parXML.value('(/row/@subunitate)[1]', 'varchar(9)'), '1'), 
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''), 
		@subtip=ISNULL(@parXML.value('(/row/@subtip)[1]', 'varchar(2)'), ''),
		@sursa=ISNULL(@parXML.value('(/row/@sursa)[1]', 'varchar(13)'), ''), 
		@aplicatie=ISNULL(@parXML.value('(/row/@aplicatie)[1]', 'varchar(2)'), ''),
		@numar=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(10)'), ''),
	    @tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''), 
	    @tert=ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(20)'), ''),
	    @data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), ''),
		@gestiune=ISNULL(@parXML.value('(/row/@gestiune)[1]', 'varchar(20)'), '')

	if @aplicatie<>''
		set @tip=@aplicatie
	set @gestutiliz=isnull((select max(valoare) from proprietati where tip='UTILIZATOR' and cod_proprietate='GESTIUNE' and cod=@utilizator),'')
	
	set @categoriePret=isnull((select max(valoare) from proprietati where tip='GESTIUNE' and cod_proprietate='CATEGPRET' and cod=@gestutiliz),'1')

	set @searchText=REPLACE(@searchText, ' ', '%')
	select top 100      
	rtrim(nomencl.cod) as cod,  
	'Pret: '+convert(varchar,convert(decimal(15, 2),max(nomencl.Pret_vanzare)))+ '  Cont: '+RTRIM(max(nomencl.Cont)) as info,  
	rtrim(max(nomencl.denumire)) as denumire 
	from nomencl
	left join preturi pretGest on pretGest.Cod_produs=nomencl.Cod and pretGest.um=@categoriePret and pretGest.Tip_pret=1 and pretGest.Data_superioara='2999-01-01' 
	left join preturi pretCat1 on pretCat1.Cod_produs=nomencl.Cod and pretCat1.um=1 and pretCat1.Tip_pret=1 and pretCat1.Data_superioara='2999-01-01' 
	left join stocuri on stocuri.Subunitate=@subunitate 
		and (@tip in ('PF','CI') and stocuri.Tip_gestiune='F' or @tip not in ('PF','CI') and stocuri.Tip_gestiune not in ('F', 'T'))
			and stocuri.Cod=nomencl.cod and (@gestiune='' or stocuri.Cod_gestiune=@gestiune)
		and (@lista_gestiuni=0 or exists (select 1 from proprietati gu where gu.valoare=stocuri.cod_gestiune and gu.tip='UTILIZATOR' and gu.cod=@utilizator and gu.cod_proprietate='GESTIUNE'))  --Se filtreaza pe gestiunile provenite din proprietati
	
	where (nomencl.denumire like '%'+@searchText+'%' or nomencl.cod like @searchText+'%')
	and (@subtip not in ('BF')or nomencl.tip='S' )
	and (@subtip not in ('FA')or nomencl.tip='R' )
	and (@subtip not in ('SP','PR') or (nomencl.Tip='S' and nomencl.Cod in (select cod from pozcon p where p.Contract=@numar and p.Data=@data and p.Tert=@tert and( p.Mod_de_plata=@sursa or @sursa=''))))
	
	group by nomencl.cod,nomencl.Denumire,nomencl.tip
	having (@FltStocPred=0 or nomencl.tip not in ('R') or @tip not in ('AP', 'AC', 'CM', 'TE', 'DF', 'AE', 'PF', 'CI') or sum(ISNULL(stocuri.stoc, 0))>=0.001)
	order by patindex('%'+@searchText+'%',nomencl.denumire),1
	for xml raw 
end
