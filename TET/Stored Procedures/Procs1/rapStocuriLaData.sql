create procedure rapStocuriLaData(@dData datetime
		,@tipstoc varchar(1)	-->	D=Depozit, F=Folosinta, C=Custodie
		,@gruppret bit			--> Grupare pe pret:	1=Da, 0=Nu
		,@ordonare varchar(1)='c'	--> c=Cod (nomenclator), d=Denumire (nomenclator)
		,@tippret varchar(1)='s'	--> s,t,v s=pret de stoc, t=f(tip gestiune), v=pret vanzare
		,@cont varchar(40)=null, @cCod varchar(40)=null,@cGestiune varchar(40)=null,@den varchar(200)=null
		,@nStocMin varchar(50)=null,@nStocMax varchar(50)=null,@gr_cod varchar(40)=null,@locatie varchar(40)=null
		,@lm varchar(40)=null	--> pt varianta in folosinta a raportului
		,@locmg varchar(200)=null	--> locul de munca al gestiunii
		,@comanda varchar(40)=null,@contract varchar(40)=null,@furnizor varchar(40)=null
		,@lot varchar(40)=null, @categPret smallint=null
		,@stoclimita bit=0			--> doar stocuri sub limita configurata in nomenclator: 1=Da, 0=Nu
		,@gGestiuni varchar(20)=null		--> grup de gestiuni
		,@grupa varchar(20)=null
		,@furnizor_nomenclator varchar(30)=null
		,@grupare int=null		/*	 pentru a trece in detalii "alternativa" gruparii;
									0=gestiuni, lm
									,1=conturi, lm
									,2=grupa nomenclator, pt folosinta: lm,gestiuni
									,3=lm
									,4=gestiuni
									,5=fara grupare superioara
									,6=comenzi
									,7=grupa nomenclator
								*/
		,@folosinta bit =0	--> e necesar pentru ca se suprapune valoare=2 a parametrului @grupare intre folosinta si restul;
						--> o solutie mai buna ar fi modificarea in raport folosinta dar ar trebui dupa aceea reintegrat cu asisplus.
		,@sesiune varchar(50)=null
		)
as
/*	--	apel procedura pt teste:
	declare @cont nvarchar(4000),@tipstoc nvarchar(1),@dData datetime,@cCod nvarchar(4000)
		,@cGestiune nvarchar(4),@den nvarchar(4000),@nStocMin nvarchar(4000),@nStocMax nvarchar(4000)
		,@gr_cod nvarchar(4000),@locatie nvarchar(4000),@lm nvarchar(4000),@comanda nvarchar(4000)
		,@contract nvarchar(4000),@furnizor nvarchar(4000),@lot nvarchar(4000),@gruppret bit
		,@ordonare nvarchar(1), @gGestiuni varchar(20)
	select @cont=NULL,@tipstoc=N'D',@dData='2012-01-13 00:00:00',@cCod=NULL,@cGestiune=N'101M',
		@den=NULL,@nStocMin=NULL,@nStocMax=NULL,@gr_cod=NULL,@locatie=NULL,@lm=NULL,@comanda=NULL,
		@contract=NULL,@furnizor=NULL,@lot=NULL,@gruppret=0,@ordonare=N'c', @gGestiuni=null
		
	exec rapStocuriLaData @dData=@dData,@tipstoc=@tipstoc,@gruppret=@gruppret,@ordonare=@ordonare
		,@cont=@cont,@cCod=@cCod,@cGestiune=@cGestiune,@den=@den
		,@nStocMin=@nStocMin,@nStocMax=@nStocMax,@gr_cod=@gr_cod,@locatie=@locatie
		,@lm=@lm,@comanda=@comanda,@contract=@contract,@furnizor=@furnizor,@lot=@lot
--*/
set transaction isolation level read uncommitted
declare @eroare varchar(500)
begin try
	if object_id('tempdb..#preturi') is not null drop table #preturi
	if object_id('tempdb..#stocuri') is not null drop table #stocuri
	if object_id('tempdb..#final') is not null drop table #final
	if object_id('tempdb..#gestiuni') is not null drop table #gestiuni
	
	declare @comanda_str varchar(max)	
	declare @q_cont varchar(20) 
	set @q_cont=ISNULL(@cont,'')
	if (@tippret not in ('s','t') and @cGestiune is null and @categPret is null)
		raiserror('Pentru tip pret diferit de pret de stoc alegeti o categorie de pret!',16,1)
	
	select @grupa=@grupa+(case when isnull((select val_logica from par where tip_parametru='GE' and parametru='GRUPANIV'),0)=0 then '' else '%' end)
		--> daca pentru grupele de nomenclator e activa setarea de grupe pe nivele se filtreaza cu 'like %'

		/**	Pregatire filtrare pe proprietati utilizatori*/
	declare @SFL int
	set @SFL=isnull((select max(convert(int, val_logica)) from par where tip_parametru='GE' and parametru='SUBGLMFOL'),0)
	declare @utilizator varchar(20), @fltGstUt int, @eLmUtiliz int
	select @utilizator=dbo.fIaUtilizator(@sesiune)
	declare @GestUtiliz table(valoare varchar(200), cod varchar(20))
	insert into @GestUtiliz (valoare,cod)
	select valoare, cod_proprietate from fPropUtiliz(null) where cod_proprietate='GESTIUNE' and valoare<>'' and @TipStoc<>'F'
	set	@fltGstUt=isnull((select count(1) from @GestUtiliz),0)
	declare @LmUtiliz table(valoare varchar(200), marca varchar(20))
	insert into @LmUtiliz(valoare, marca)
	select l.cod, p.marca
			from lmfiltrare l left join personal p 
				on l.utilizator=@utilizator and (@sfl=1 or rtrim(l.cod)=rtrim(p.loc_de_munca))
		where l.cod<>'' and @TipStoc='F'
			and l.utilizator=@utilizator
	set @eLmUtiliz=isnull((select max(1) from @LmUtiliz),0)

	create table #stocuri(subunitate varchar(20), cod varchar(20), gestiune varchar(20), cod_intrare varchar(20), pret float,
			tip_gestiune varchar(1), data datetime, stoc float, loc_de_munca varchar(20), cont varchar(20),pret_cu_amanuntul float,
			data_expirarii datetime, comanda varchar(100) default null)

	if @dData is null
	begin
		set @dData=convert(char(10),getdate(),101)
		insert into #stocuri(subunitate, cod, gestiune, cod_intrare, pret, tip_gestiune, data, stoc, loc_de_munca, cont,pret_cu_amanuntul, data_expirarii, comanda)
		select subunitate, cod, rtrim(cod_gestiune), cod_intrare, pret, tip_gestiune, data, stoc, loc_de_munca, cont,pret_cu_amanuntul, data_expirarii, comanda
		from stocuri 
		where (@cCod is null or cod=@cCod) 
			and (@cGestiune is null or Cod_gestiune=@cGestiune)
			and (@tipstoc='D' and Tip_gestiune not in ('F','T') or @tipstoc=Tip_gestiune)
			and cont like RTRIM(@q_cont)+'%'
			and (@locatie is null or locatie=@locatie)
			and (@comanda is null or comanda=@comanda)
			and (@contract is null or contract=@contract)
			and (@furnizor is null or Furnizor=@furnizor)
			and (@fltGstUt=0 or exists(select 1from @GestUtiliz pr where pr.valoare=cod_gestiune))
			and (@locatie is null or locatie=@locatie)
			and (isnull(@lm,'')='' or @tipstoc='F' and @SFL=1 and rtrim(loc_de_munca) like rtrim(@lm)+'%' or @tipstoc='F' and @SFL=0 and exists (select 1 from personal where marca=stocuri.cod_gestiune and rtrim(loc_de_munca) like rtrim(@lm)+'%')) 
			and (@eLmUtiliz=0 or 
			exists(select 1from @LMUtiliz pr
				where rtrim(pr.valoare) like rtrim(loc_de_munca)+'%'
					and (@sfl=1 or rtrim(pr.marca)=rtrim(furnizor))))
		----, @lot
	end
	else
	begin
		declare @parXML xml
		select @parXML=(select --convert(varchar(20),@dDataJos,102) dDataJos, 
			convert(varchar(20),@dData,102) dDataJos,
			convert(varchar(20),@dData,102) dDataSus,
			@cCod cCod, @cGestiune cGestiune, 1 GrCod, 1 GrGest, 1 GrCodi, @TipStoc TipStoc, @q_cont cCont, 
				@grupa cGrupa, @locatie Locatie, @comanda Comanda, @contract Contract, @furnizor Furnizor, @lot Lot--, 1 cufStocuri
				,@lm lm, (case when @tipstoc<>'D' then null else @gGestiuni end) as grupGestiuni
				,@sesiune sesiune
		for xml raw)
				
		if object_id('tempdb..#docstoc') is not null drop table #docstoc
			create table #docstoc(subunitate varchar(9))
			exec pStocuri_tabela
		 
		exec pstoc @sesiune=@sesiune, @parxml=@parxml

		insert into #stocuri(subunitate, cod, gestiune, cod_intrare, pret, tip_gestiune, data, stoc, loc_de_munca, cont,pret_cu_amanuntul, data_expirarii, comanda)
		select subunitate, cod, gestiune, cod_intrare, pret, tip_gestiune, data, stoc, loc_de_munca, cont, pret_cu_amanuntul, data_expirarii, comanda
		--from dbo.fStocuriCen(@dData,@cCod,@cGestiune,NULL,1,1,1, @tipstoc, @q_cont, @grupa, @locatie, null, @comanda, @contract, @furnizor, @lot)
		from #docstoc 
		--where (@gGestiuni is null or gestiune like @gGestiuni+'%')
	end
--test		select * from #docstoc where abs(stoc)>0
	create table #preturi(cod varchar(20),nestlevel int)
	
	insert into #preturi
	select s.cod, @@NESTLEVEL
	from #stocuri s
	group by s.cod

	exec CreazaDiezPreturi
	
	if (@tippret='V')
	begin
		declare @px xml
		select @px=(select @categPret as categoriePret,@dData as data,@cGestiune as gestiune for xml raw)
		exec wIaPreturi @sesiune=null,@parXML=@px
	end
	
	select g.subunitate, g.tip_gestiune, g.cod_gestiune, g.denumire_gestiune
		into #gestiuni from gestiuni g
	where (@locmg is null or g.detalii.value('(/row/@lm)[1]','varchar(200)') like @locmg+'%')

	select convert(varchar(1000),'') grupare1, convert(varchar(1000),'') dengrupare1,
			convert(varchar(1000),'') grupare2, convert(varchar(1000),'') dengrupare2,
		@tipstoc tip_stoc, r.cod, max(n.denumire) as denprod, max(n.um) as um, 
		r.gestiune,
		--ltrim(rtrim(case @tipstoc when 'F' then max(p.nume) when 'T' then max(t.Denumire) else max(g.denumire_gestiune) end)) as dengest,
		max(ltrim(rtrim(case @tipstoc when 'F' then p.nume when 'T' then t.Denumire else g.denumire_gestiune end))) as dengest,
		max(r.cod_intrare) as cod_intrare, 
		(case @tippret when 's' then r.pret  --Pret de stoc
			when 'v' then max(pr.pret_amanunt) --Pret vanzare pe o categorie din wIaPreturi 
			else	--In functie de tipul gestiunii
				(case when max(r.tip_gestiune)='A' then max(r.Pret_cu_amanuntul) else max(r.pret) end) 
		end) as pret,
		min(r.data) as data, sum(r.stoc) as stoc, max(r.loc_de_munca) as loc_de_munca,MAX(l.Denumire) as nume_lm,
		rtrim(r.cont) as cont, max(rtrim(c.Denumire_cont)) as Denumire_cont,
		min(isnull(sl.stoc_min,slstd.stoc_min)) as stocmin,
		max(n.grupa) grupa,
		convert(varchar(20),min(r.data),103)+
			(case when @tipstoc='F' then ' -> '+convert(varchar(20),min(r.data_expirarii),103)
				else '' end)+' - '+
			(case when @grupare=1 then max(rtrim(r.gestiune)+'-'+
						rtrim((case when @tipstoc='F' then p.nume else g.denumire_gestiune end))
						)
					else rtrim(r.cont) end) as detalii,
		min(r.data_expirarii) data_expirarii,
		max(rtrim(gr.denumire)) denGrupa,
		rtrim(--case when @ordonare='c' then 
			(case @grupare	when 1 then max(r.cont)+(case when @tipstoc='F' then '|'+max(r.loc_de_munca) else '' end)
							when 2 then (case when @tipstoc='F' then max(r.loc_de_munca)+max(r.gestiune) else max(n.grupa) end)
							when 3 then max(r.loc_de_munca)
							when 5 then ''
							when 6 then max(r.comanda)
							else max(r.gestiune) end)
			/*else (case @grupare	when 0 then max(case @tipstoc when 'F' then p.nume when 'T' then t.Denumire else g.denumire_gestiune end)
							when 1 then max(c.Denumire_cont)
							else (case when @tipstoc='F' then max(l.denumire) else max(gr.denumire) end) end) end*/) ord1,
		rtrim(case when @ordonare='c' then max(r.cod) else max(n.denumire) end) ord2,
		rtrim(case when @gruppret=0 then max(r.cod_intrare) else '' end) as ordCodIntrare,
		max(rtrim(n.um_1)) um_1,
		convert(decimal(15,2),sum(case when n.um_1='' or abs(coeficient_conversie_1)<0.001 then '' else r.stoc/n.coeficient_conversie_1 end)) cantitate_1,
		max(r.comanda) comanda,
		max(rtrim(n.um_2)) um_2,
		convert(decimal(15,2),sum(case when n.um_2='' or abs(coeficient_conversie_2)<0.001 then '' else r.stoc/n.coeficient_conversie_2 end)) cantitate_2
	into #final
	from #stocuri r
		left join #preturi pr on pr.Cod=r.cod
		left outer join nomencl n on r.cod=n.cod
		left join #gestiuni g on r.subunitate=g.subunitate and r.gestiune=g.cod_gestiune
		left join lm l on rtrim(r.loc_de_munca)=rtrim(l.Cod) and @tipstoc='F'
		left join conturi c on c.Cont=r.cont
		left join stoclim sl on r.cod=sl.cod and sl.subunitate='1' and sl.tip_gestiune=g.tip_gestiune and sl.cod_gestiune=r.gestiune
		left join stoclim slstd on r.cod=slstd.cod and slstd.subunitate='1' and slstd.tip_gestiune='' and slstd.cod_gestiune=''
		left join grupe gr on gr.grupa=n.grupa
		left join personal p on r.gestiune=p.marca
		left join terti t on t.Subunitate='1' and t.Tert=r.gestiune
	where (isnull(n.denumire,'')='' or n.denumire like '%'+ isnull(@den,'')+'%')
		--and (@gGestiuni is null or r.gestiune like @gGestiuni+'%')
		and (@grupa is null or n.grupa like @grupa)
		and (@furnizor_nomenclator is null or @furnizor_nomenclator=n.furnizor)
		and (@locmg is null or g.cod_gestiune is not null)
	group by r.cod, r.gestiune, (case when @gruppret=0 then r.cod_intrare else '' end),
		r.pret, l.cod, r.cont
	having 
		(@nStocMin is null or sum(r.stoc)>=@nStocMin) and 
		(@nStocMax is null or sum(r.stoc)<=@nStocMax) and 
		--(@stoclimita=0 or sum(r.stoc)<sum(isnull(sl.stoc_min,isnull(slstd.stoc_min,0)))) and 
		(isnull(@gr_cod,'')='' or r.cod like @gr_cod+'%') and abs(sum(r.stoc))>0.0009
	--order by (case when @ordonare='c' then r.cod else max(n.denumire) end), data
	
	if @stoclimita=1
	begin
		set @comanda_str='
		delete f from #final f inner join
			(select (case when sum(stoc)<min(stocmin) then 1 else 0 end) as sub_stoc, r.cod, r.gestiune
			from #final r group by r.cod, r.gestiune) r on f.cod=r.cod and f.gestiune=r.gestiune and sub_stoc=0'
		exec (@comanda_str)
	end
	
	if exists (select 1 from sys.objects o where name='rapStocuriLaData_detaliiSP')
		exec rapStocuriLaData_detaliiSP
		
	declare @p xml
	select @p=(select @tipstoc tipstoc, @dData dData for xml raw)
	if exists (select 1 from sys.objects o where name='rapStocuriLaDataSP')
		exec rapStocuriLaDataSP @sesiune=@sesiune, @parxml=@p
	
	/*
	0=gestiuni, lm
	,1=conturi, lm
	,2=grupa nomenclator, pt folosinta: lm,gestiuni
	,3=lm
	,4=gestiuni
	,5=fara grupare superioara
	,6=comenzi
	,7=grupa nomenclator
	*/
	
	if @folosinta=0
	begin
		update f set 
			grupare1=isnull(rtrim(case @grupare when 0 then gestiune when 1 then cont when 2 then grupa else '' end),''),
			dengrupare1=isnull(rtrim(case @grupare when 0 then dengest when 1 then denumire_cont when 2 then dengrupa else '' end),'')
		from #final f
		
		if @grupare=6	--> comanda
		update f set 
			grupare1=isnull(rtrim(f.comanda),''),
			dengrupare1=isnull(rtrim(c.descriere),'')
		from #final f left join comenzi c on f.comanda=c.comanda
	end
	
	if @folosinta=1
	begin
		update f set 
			grupare1=isnull(rtrim(case @grupare when 0 then gestiune when 1 then cont when 2 then loc_de_munca else '' end),''),
			dengrupare1=isnull(rtrim(case @grupare when 0 then dengest when 1 then denumire_cont when 2 then nume_lm else '' end),'')
		from #final f
		
		update f set 
			grupare2=isnull(rtrim(case when @grupare in (2,4) then gestiune when @grupare=5 then '' when @grupare=7 then grupa else loc_de_munca end),''),
			dengrupare2=isnull(rtrim(case when @grupare in (2,4) then dengest when @grupare=5 then '' when @grupare=7 then dengrupa else nume_lm end),'')
		from #final f
	end
	
	select grupare1, dengrupare1, grupare2, dengrupare2,
		r.cod, r.denprod, r.um, r.gestiune,
		dengest as dengest,
		r.cod_intrare, r.pret, r.data, r.stoc, r.loc_de_munca, r.nume_lm, r.cont,
		r.Denumire_cont, r.stocmin,
		rtrim(r.grupa) grupa, denGrupa, r.detalii,
		data_expirarii,
		um_1, cantitate_1, um_2, cantitate_2
	from #final r
	order by ord1, ord2, ordCodIntrare, pret
end try
begin catch
	set @eroare='rapStocuriLaData: '+ERROR_MESSAGE()
end catch

if object_id('tempdb..#preturi') is not null drop table #preturi
if object_id('tempdb..#stocuri') is not null drop table #stocuri
if object_id('tempdb..#final') is not null drop table #final
if object_id('tempdb..#gestiuni') is not null drop table #gestiuni
if len(@eroare)>0 raiserror(@eroare,16,1)
