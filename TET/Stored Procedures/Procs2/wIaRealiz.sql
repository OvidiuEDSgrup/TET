--***
create procedure [dbo].[wIaRealiz] @sesiune varchar(50), @parXML xml 
as  

declare @subunitate varchar(20), @userASiS varchar(20), @iDoc int,@lCuTermene int ,@lista_clienti bit, @f_contract varchar(20),@fresponsabil varchar(80),
    @tipDoc varchar (2), @numar varchar(20), @data datetime , @data_jos datetime , @data_sus datetime, @fcontract varchar(20), @beneficiar varchar(80),
    @fstare varchar(80) , @valoare_minima varchar (80), @valoare_maxima varchar(80),@dencontract varchar(90),@fbeneficiar varchar(80),@fdenumire varchar(80),
    @fsursa varchar(80),@lista_gestiuni bit ,@realizat varchar(1),@facturat varchar(1),@nefacturat varchar(1), @TermPeSurse int,@flocmunca varchar(20),
    @tert varchar(13), @Periodicitate int,  @dataCon datetime
    
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
select @lista_gestiuni=0, @lista_clienti=0
select @lista_gestiuni=(case when cod_proprietate='GESTIUNE' then 1 else @lista_gestiuni end), 
		   @lista_clienti=(case when cod_proprietate='CLIENT' then 1 else @lista_clienti end)
from proprietati 
where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate in ('GESTIUNE', 'CLIENT', 'LOCMUNCA') and valoare<>''
select @subunitate=val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO'                              
select @lCuTermene=Val_logica from par where tip_parametru='UC' and parametru='TERMCNTR'
exec luare_date_par 'UC', 'POZSURSE', @TermPeSurse output, 0, ''
exec luare_date_par 'UC', 'PERIODCON', @Periodicitate output, 0, ''

select  @tipDoc=isnull(@parXML.value('(/row/@tipDoc)[1]','varchar(2)'),''),
		@numar=isnull(@parXML.value('(/row/@numar)[1]','varchar(20)'),''),
		@data=isnull(@parXML.value('(/row/@data)[1]','datetime'),'1901-01-01'),
		@dataCon=isnull(@parXML.value('(/row/@data)[1]','datetime'),''),
		@tert=isnull(@parXML.value('(/row/@tert)[1]','varchar(13)'),''),
		
		@data_jos=isnull(@parXML.value('(/row/@datajos)[1]','datetime'),'1901-01-01'),
		@data_sus=isnull(@parXML.value('(/row/@datasus)[1]','datetime'),'2901-01-01'),
		@fcontract=isnull(@parXML.value('(/row/@f_numar)[1]','varchar(20)'),''),
		@beneficiar=isnull(@parXML.value('(/row/@beneficiar)[1]','varchar(80)'),''),
		@fbeneficiar=isnull(@parXML.value('(/row/@f_denTert)[1]','varchar(80)'),''),
		@fdenumire=isnull(@parXML.value('(/row/@f_denumire)[1]','varchar(80)'),''),
		@fsursa=isnull(@parXML.value('(/row/@f_sursa)[1]','varchar(80)'),''),
		@flocmunca=isnull(@parXML.value('(/row/@f_denlm)[1]','varchar(80)'),''),
		@dencontract=isnull(@parXML.value('(/row/@dencontract)[1]','varchar(80)'),''),
		@fresponsabil=isnull(@parXML.value('(/row/@f_responsabil)[1]','varchar(80)'),''),
		@fstare=isnull(@parXML.value('(/row/@f_stare)[1]','varchar(10)'),''),
		@valoare_minima=isnull(@parXML.value('(/row/@f_valoarejos)[1]','varchar(80)'),''),
		@valoare_maxima=isnull(@parXML.value('(/row/@f_valoaresus)[1]','varchar(80)'),'')
             

set @fbeneficiar=Replace(@fbeneficiar,' ','%')
set @fdenumire=Replace(@fdenumire,' ','%')
set @fsursa=Replace(@fsursa,' ','%')

	select 
		t.subunitate,t.Tip,t.Cod,
		RTRIM(t.tert) as tert, 
		convert(varchar(10),t.data,101)as data, 
		rtrim(t.contract) as contract, rtrim(te.denumire) as denTert, 
		t.Cantitate, t.Pret, 
		(case when (t.cant_realizata<>0 or t.val2=1 and t.val1=0) then 'P' when t.Val2=1 and t.val1<>0 then 'R' else 'N' end) as stare,
		(case when (t.cant_realizata<>0 or t.val2=1 and t.val1=0) then '#808080' when t.Val2=1 then 'Green' else 'Black' end) as culoare
	into #temp	
	from termene t 
		inner join terti te on te.Subunitate=t.Subunitate and te.tert=t.tert
	where (t.Tip=@tipDoc or @tipDoc ='')
	   and (t.Data=@data or @data='1901-01-01') 
	   and (t.Contract=@numar or @numar ='')
	   and (t.Tert=@tert or @tert='')
	   and isnull(te.denumire, '') like '%'+@fbeneficiar+'%'
	   and isnull(t.Contract, '') like '%' + isnull(@fcontract, '') + '%'
	   and t.Termen between @data_jos and @data_sus
	   --and charindex((case when (t.cant_realizata<>0 or t.val2=1 and t.val1=0) then 'P' when t.Val2=1 then 'R' else 'N' end),@fstare)>0 --like @fstare+'%'
		

	select top 100	convert(varchar(10),@data_jos,101 ) as datajos,convert(varchar(10),@data_sus,101 )as datasus,
					t.tip as tipDoc ,t.contract as numar, max(t.denTert) as denTert,t.tert,convert(varchar(10),t.data,101 )as data,rtrim(isnull(max(c.responsabil),'')) as info6,
					rtrim(ltrim(max(c.Loc_de_munca)))as loc_de_munca,
					convert(decimal(15,4),max(c.total_contractat)) as valoare,
					convert(decimal(15,4),sum(t.cantitate*t.pret)) as valFact,
					rtrim(max(lm.Denumire))as denLm,
					/*max(c.stare) + '-' + (case when isnull(max(pa.val_alfanumerica), '')<>'' then rtrim(max(pa.val_alfanumerica)) 
					else (case max(c.stare) when '0' then 'Operat' when '1' then 'Definitiv' when '2' then 'Blocat' when '3' then 'Confirmat' when '4' then 'Expediat' when '5' 
					then 'In vama' when '6' then 'Realizat' when '7' then 'Reziliat' else max(c.stare) end) end) as denstare,*/
					(case when min(t.stare)='N' then 'Nefacturat' when (min(t.stare)='P' and min(t.stare)='R') or min(t.stare)='R'  then 'Bun de facturat' else 'Facturat' end ) as denstare,
					RTRIM(max(c.Explicatii))as explicatii, @fstare as stare,
					convert(varchar(10),max(c.Data_rezilierii),101)as valabilitate,rtrim(max(c.Punct_livrare))as punct_livrare,RTRIM(max(c.valuta)) as valuta,
					(case when min(t.stare)='N' then 'Black' when min(t.stare)='P' and MAX(t.stare)='R' or (min(t.stare)='R' and MAX(t.stare)='R') then 'Green' else '#808080' end ) as culoare	
	from #temp t
					inner join con c on c.subunitate=t.subunitate and c.Data=t.data and c.Tert=t.tert and c.Contract=t.contract and c.Stare='1'
					left join par pa on pa.tip_parametru='UC' and pa.parametru='STAREBK'+c.stare
					inner join lm  on lm.Cod=c.Loc_de_munca 
	where 
					c.Loc_de_munca + lm.Denumire like '%'+isnull(@flocmunca,'')+'%'
					and c.Responsabil  like '%'+isnull(@fresponsabil,'')+'%'
					and (t.stare like '%'+@fstare+'%' or isnull(@fstare,'')='')
					and (dbo.f_areLMFiltru(@userASiS)=0 or exists(select (1) from LMFiltrare pr where pr.utilizator=@userASiS and pr.cod=c.Loc_de_munca)) 
	group by t.subunitate,t.tip,t.data,t.contract,t.tert
	for xml raw

