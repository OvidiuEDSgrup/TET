--***
create function fDenumiriRap
/**	Functia care se foloseste de rapoartele web pentru a aduce "date secundare" (etichete filtre, nume firma, etc).
	Motiv: necesitatea de a centraliza metoda de citire date secundare, pentru o mai buna gestionare.
	Dilema: ar fi mai corect sa se creeze functii separate pt fiecare informatie/tabela din care se aduc date,
		dar ar insemna sa se scrie f. multe functii.
Obs:
	1. se vor adauga parametri la functie, dar nu se va sterge nimic din ea 
			fara sa se corecteze in toate rapoartele care o folosesc
	2. nu se vor adauga parametri in functie care au acelasi scop/"select" cu altul deja existent,
		se va modifica in raport astfel incat functia sa primeasca parametrul existent
	3. toti parametri asociati valorilor din fDenumiriRapSP vor avea in denumire sufixul 'SP'
*/
--***
(@sesiune varchar(50), @parXML xml)
returns @denumiri table (parametru varchar(50), valoare varchar(2000))
as 
begin
declare @utilizator varchar(500)
		,@datajos datetime, @datasus datetime, @cont varchar(50), @grupaTert varchar(50), @tert varchar(50), @cod_judet varchar(50)
		,@punctLivrare varchar(50)
		,@locm varchar(50), @codNomenclator varchar(50), @gestiune varchar(50), @grupaNomenclator varchar(50)
		,@categoriePret varchar(50), @antetInventar int, @dataLunii datetime
		,@rIntervalDocFinanciare varchar(500)	--> @rIntervalDocFinanciare va aduce in raport un subtitlu referitor la interval, 
												-->	in functie de @datajos, @datasus, data implementarii si data ultimei initializari
--	par (AS, CG, ...)
		,@adresa varchar(50), @localit varchar(50), @judet varchar(50), @codfisc varchar(50), @autoriz  varchar(50), @ordreg  varchar(50), @banca varchar(50), @contbc varchar(50)
		,@email varchar(50), @telfax varchar(50), @fax varchar(50), @codcaen varchar(50), @codjudeta varchar(50)
		,@locatie varchar(30), @um varchar(30)
--	detalii adresa unitate
		,@strada varchar(50), @numar varchar(50), @bloc varchar(50), @scara varchar(50), @etaj varchar(50), @apartam varchar(50), @codpostal varchar(50)
--	functie si nume director general, director economic
		,@fdirgen varchar(50), @dirgen varchar(50), @fdirec varchar(50), @direc varchar(50)
--	nume, prenume si functie pt. persoana care intocmeste declaratiile de salarii, cod fiscal specific salariilor (ANAR)
		,@npersaut varchar(50), @ppersaut varchar(50), @fpersaut varchar(50)
--	nume si functie pt. persoana care intocmeste declaratiile de TVA
		,@ndecltva varchar(50), @fdecltva varchar(50)
--	Autofiltrari:
		,@propLocm varchar(50), @propGestiune varchar(50), @intervalDocFinanciare varchar(50)
--	MF:
		,@categoriaMF varchar(50), @mFix varchar(50), @codClasificareMF varchar(50)
--	Imobilizari:
		,@imob varchar(50)
--	PC:
		,@comanda varchar(50), @grupaComanda varchar(50)
--	TB:
		,@indicatorTB varchar(50)
--	Bugetari:
		,@indicator varchar(50), @grindicator varchar(50)
--	auxiliare:
		,@dataImplementarii datetime
		,@dataSolduri datetime		/**	data pana la care orice sume vor aparea ca solduri	*/
		,@subunitate varchar(20)

select @subunitate=isnull((select max(rtrim(val_alfanumerica)) from par where parametru='subpro' and tip_parametru='GE'),'1'),
		@utilizator=dbo.fIaUtilizator(@sesiune)
/*		--> mai mult incurca, deocamdata:
		if @utilizator ='' and suser_name()<>'sa'
		begin
			insert into @denumiri(parametru, valoare)
			select '@eroare','Utilizatorul nu a fost identificat!'
			return
		end
*/
select
--	Parametri generali (AS,CG,...)
		@datajos=@parXML.value('(row/@datajos)[1]','datetime'),
		@datasus=@parXML.value('(row/@datasus)[1]','datetime'),
		@cont=@parXML.value('(row/@cont)[1]','varchar(50)'),
		@grupaTert=@parXML.value('(row/@grupaTert)[1]','varchar(50)'),
		@tert=@parXML.value('(row/@tert)[1]','varchar(50)'),
		@cod_judet=@parXML.value('(row/@cod_judet)[1]','varchar(50)'),
		@punctLivrare=@parXML.value('(row/@punctLivrare)[1]','varchar(50)'),
		@locm=@parXML.value('(row/@locm)[1]','varchar(50)'),
		@codNomenclator=@parXML.value('(row/@codNomenclator)[1]','varchar(50)'),
		@gestiune=@parXML.value('(row/@gestiune)[1]','varchar(50)'),
		@grupaNomenclator=@parXML.value('(row/@grupaNomenclator)[1]','varchar(50)'),
		@categoriePret=@parXML.value('(row/@categoriePret)[1]','varchar(50)'),
		@antetInventar=@parXML.value('(row/@antetInventar)[1]','varchar(50)'),
		@dataLunii=@parXML.value('(row/@dataLunii)[1]','datetime'),
		@locatie=@parXML.value('(row/@locatie)[1]','varchar(30)'),
		@um=@parXML.value('(row/@um)[1]','varchar(30)'),
--	par
		@adresa=(case when @parXML.value('(row/@adresa)[1]','varchar(50)') is not null then 'ADRESA' else null end),
		@localit=(case when @parXML.value('(row/@localit)[1]','varchar(50)') is not null then 'LOCALIT' else null end),
		@judet=(case when @parXML.value('(row/@judet)[1]','varchar(50)') is not null then 'JUDET' else null end),
		@codfisc=(case when @parXML.value('(row/@codfisc)[1]','varchar(50)') is not null then 'CODFISC' else null end),
		@autoriz=(case when @parXML.value('(row/@autoriz)[1]','varchar(50)') is not null then 'AUTORIZ' else null end),
		@ordreg=(case when @parXML.value('(row/@ordreg)[1]','varchar(50)') is not null then 'ORDREG' else null end),
		@banca=(case when @parXML.value('(row/@banca)[1]','varchar(50)') is not null then 'BANCA' else null end),
		@contbc=(case when @parXML.value('(row/@contbc)[1]','varchar(50)') is not null then 'CONTBC' else null end),
		@telfax=(case when @parXML.value('(row/@telfax)[1]','varchar(50)') is not null then 'TELFAX' else null end),
		@fax=(case when @parXML.value('(row/@fax)[1]','varchar(50)') is not null then 'FAX' else null end),
		@email=(case when @parXML.value('(row/@email)[1]','varchar(50)') is not null then 'EMAIL' else null end),
		@codcaen=(case when @parXML.value('(row/@codcaen)[1]','varchar(50)') is not null then 'CODCAEN' else null end),
		@codjudeta=(case when @parXML.value('(row/@codjudeta)[1]','varchar(50)') is not null then 'CODJUDETA' else null end),
		@strada=(case when @parXML.value('(row/@strada)[1]','varchar(50)') is not null then 'STRADA' else null end),
		@numar=(case when @parXML.value('(row/@numar)[1]','varchar(50)') is not null then 'NUMAR' else null end),
		@bloc=(case when @parXML.value('(row/@bloc)[1]','varchar(50)') is not null then 'BLOC' else null end),
		@scara=(case when @parXML.value('(row/@scara)[1]','varchar(50)') is not null then 'SCARA' else null end),
		@etaj=(case when @parXML.value('(row/@etaj)[1]','varchar(50)') is not null then 'ETAJ' else null end),
		@apartam=(case when @parXML.value('(row/@apartam)[1]','varchar(50)') is not null then 'APARTAM' else null end),
		@codpostal=(case when @parXML.value('(row/@codpostal)[1]','varchar(50)') is not null then 'CODPOSTAL' else null end),
--	nume director general, director economic
		@fdirgen=(case when @parXML.value('(row/@fdirgen)[1]','varchar(50)') is not null then 'FDIRGEN' else null end),
		@dirgen=(case when @parXML.value('(row/@dirgen)[1]','varchar(50)') is not null then 'DIRGEN' else null end),
		@fdirec=(case when @parXML.value('(row/@fdirec)[1]','varchar(50)') is not null then 'FDIREC' else null end),
		@direc=(case when @parXML.value('(row/@direc)[1]','varchar(50)') is not null then 'DIREC' else null end),
--	nume, prenume si functie pt. persoana care intocmeste declaratiile de salarii
		@npersaut=(case when @parXML.value('(row/@npersaut)[1]','varchar(50)') is not null then 'NPERSAUT' else null end),
		@ppersaut=(case when @parXML.value('(row/@ppersaut)[1]','varchar(50)') is not null then 'PPERSAUT' else null end),
		@fpersaut=(case when @parXML.value('(row/@fpersaut)[1]','varchar(50)') is not null then 'FPERSAUT' else null end),
--	nume si functie pt. persoana care intocmeste declaratiile de TVA
		@ndecltva=(case when @parXML.value('(row/@ndecltva)[1]','varchar(50)') is not null then 'NDECLTVA' else null end),
		@fdecltva=(case when @parXML.value('(row/@fdecltva)[1]','varchar(50)') is not null then 'FDECLTVA' else null end),
--	"autofiltrari"
		@propLocm=@parXML.value('(row/@propLocm)[1]','varchar(50)'),
		@propGestiune=@parXML.value('(row/@propGestiune)[1]','varchar(50)'),
		@intervalDocFinanciare=@parXML.value('(row/@intervalDocFinanciare)[1]','varchar(50)'),

--	MF
		@categoriaMF=@parXML.value('(row/@categoriaMF)[1]','varchar(50)'),
		@mFix=@parXML.value('(row/@mFix)[1]','varchar(50)'),
		@codClasificareMF=@parXML.value('(row/@codClasificareMF)[1]','varchar(50)'),
--	Imobilizari
		@imob=@parXML.value('(row/@imob)[1]','varchar(50)'),
--	PC	
		@comanda=@parXML.value('(row/@comanda)[1]','varchar(50)'),
		@grupaComanda=@parXML.value('(row/@grupaComanda)[1]','varchar(50)'),
--	TB	
		@indicatorTB=@parXML.value('(row/@indicatorTB)[1]','varchar(50)'),
--	Bugetari
		@indicator=@parXML.value('(row/@indicator)[1]','varchar(50)'),
		@grindicator=@parXML.value('(row/@grindicator)[1]','varchar(50)')
		
	if (isnull(@antetInventar,0)<>0) set @gestiune=null		

	declare @userAsis varchar(50), @loc_pref varchar(1000), @gest_pref varchar(1000),
			@separator_categoriaMF varchar(1)
		--> parametri care determina daca se tine cont de separatorul "." in identificarea categoriilor sau a codurilor de clasificare
	select @loc_pref='', @gest_pref='', 
		@separator_categoriaMF=(case when charindex('.',@categoriaMF)=0 then '.' else '' end)

	select	@categoriaMF=replace(@categoriaMF,@separator_categoriaMF,'')
			
	select @userAsis=dbo.fiautilizator (@sesiune)
	if (@propLocm is not null)
	begin
		select @loc_pref=@loc_pref+rtrim(l.cod)+', '
			from lmfiltrare l where not exists (select 1 from lmfiltrare l1 where l.cod like rtrim(l1.cod)+'%' and l.cod<> l1.cod and l.utilizator=l1.utilizator)
					and l.utilizator=@utilizator	--> aici nu trebuie luate decat nivelurile superioare ale locurilor de munca
			order by rtrim(l.cod)
		set @loc_pref=(case when len(@loc_pref)>0 then 'restrictionat pe lm: '+left(@loc_pref,len(@loc_pref)-1) else '' end)
	end
	if (@propGestiune is not null)
	begin
		select @gest_pref=@gest_pref+rtrim(pr.Valoare)+',' from proprietati pr where pr.Cod_proprietate='GESTIUNE' and cod=@userAsis and valoare<>''
			order by pr.Valoare
		set @gest_pref=(case when len(@gest_pref)>0 then 'restrictionat pe gestiuni: '+left(rtrim(@gest_pref),len(@gest_pref)-1) else '' end)
	end
	
	set @rIntervalDocFinanciare=''
	if (@intervalDocFinanciare is not null and @datasus is not null)
	begin
		select @dataImplementarii=--'1921-1-1'
		dateadd(d,-1,	dateadd(m,1,
		isnull((select convert(varchar(4),val_numerica) from par where tip_parametru='ge' and parametru='ANULIMPL'),'1921')+'-'+
		isnull((select convert(varchar(2),val_numerica) from par where tip_parametru='ge' and parametru='lunaimpl'),'1')+'-1'
		)),
		@dataSolduri=(select max(case when parametru='ANULINC' then convert(varchar(20),val_numerica) else '' end)+'-'
								+max(case when parametru='LUNAINC' then convert(varchar(20),val_numerica) else '' end)+'-1'
						from par p where tip_parametru='GE' and parametru in ('ANULINC','LUNAINC'))
		if (@dataSolduri<@dataImplementarii)		--> nu se vor lua date anterioare datei implementarii
		begin
	 		set @rIntervalDocFinanciare='(de la '+convert(varchar(20),@dataImplementarii,103)+')'
	 		set @dataSolduri=@dataImplementarii
		end
		else set @rIntervalDocFinanciare='(de la '+convert(varchar(20),@dataSolduri,103)+')'
				--set @dataSolduri=@dataImplementarii
		if (@datajos>@dataSolduri)					
		begin
			set @rIntervalDocFinanciare='de la '+convert(varchar(20),@datajos,103)
			set @dataSolduri=@datajos
		end
		if (@dataSolduri<=@datasus) set @rIntervalDocFinanciare=rtrim(@rIntervalDocFinanciare)+' pana la '+convert(varchar(20),@datasus,103)
		if (@datasus<@datajos) set @rIntervalDocFinanciare='cu interval gresit ( '+convert(varchar(20),@datajos,103)+' > '+convert(varchar(20),@datasus,103)+' )'
	end
	
if (isnull(@antetInventar,0)<>0)		--> poate ca nu exista antet inventar (?)
	select @gestiune=a.gestiune--'@gestiune', isnull((select rtrim(max(a.gestiune))+' ('+rtrim(max(g.denumire_gestiune))+')'
	from antetinventar a 
--			left join gestiuni g on g.Cod_gestiune=a.gestiune
		where a.idInventar=@antetInventar--),'<nu exista>') union all
		
insert into @denumiri(parametru,valoare)
	select '1' as parametru,rtrim(val_alfanumerica) as valoare
		from par where tip_parametru='GE' and parametru='NUME' union all	--<-- pt compatibilitate in urma
--	par
	select '@'+lower(rtrim(parametru)) as parametru,rtrim(val_alfanumerica) as valoare
		from par where tip_parametru='GE' and parametru in 
		('NUME',@adresa,@codfisc,@autoriz,@ordreg,@banca,@contbc,@telfax,@fax,@email,@judet,@ndecltva,@fdecltva,@fdirgen,@dirgen,@fdirec,@direc) union all
	select '@'+lower(rtrim(parametru)) as parametru,(case when Parametru in (@codpostal) then rtrim(convert(char(50),val_numerica)) else rtrim(val_alfanumerica) end) as valoare
		from par where tip_parametru='PS' and parametru in (@localit,@codcaen,@codjudeta,@strada,@numar,@bloc,@scara,@etaj,@apartam,@codpostal,@npersaut,@ppersaut,@fpersaut) union all
	select '@cont', rtrim(isnull((select max(c.Denumire_cont) from conturi c where c.cont=@cont and c.Subunitate=@subunitate),'<nu exista>')) 
		where @cont is not null union all
	select '@grupaTert', rtrim(isnull((select max(g.Denumire) from gterti g where g.grupa=@grupaTert),'<nu exista>')) 
		where @grupaTert is not null union all
	select '@tert', rtrim(isnull((select max(t.Denumire) from terti t where t.Tert=@tert and t.Subunitate=@subunitate),'<nu exista>')) 
		where @tert is not null union all
	select '@denjudet', rtrim(isnull((select max(j.Denumire) from judete j where j.cod_judet=@cod_judet),'<nu exista>')) 
		where @cod_judet is not null union all
	select '@punctLivrare', rtrim(isnull((select max(i.Descriere) from infotert i where i.Tert=@tert and i.Subunitate=@subunitate and i.Identificator=@punctLivrare),'<nu exista>')) 
		where @tert is not null and @punctLivrare is not null union all
	select '@locm', rtrim(isnull((select max(lm.Denumire) from lm where lm.Cod=@locm),'<nu exista>'))
		where @locm is not null union all
	select '@codNomenclator', rtrim(isnull((select max(n.Denumire) from nomencl n where n.Cod=@codNomenclator),'<nu exista>'))
		where @codNomenclator is not null union all
	select '@grupaNomenclator', rtrim(isnull((select max(g.Denumire) from grupe g where g.Grupa=@grupaNomenclator),'<nu exista>'))
		where @grupaNomenclator is not null union all
	select '@gestiune', rtrim(isnull((select max(left(g.Denumire_gestiune,30)) from gestiuni g where g.Cod_gestiune=@gestiune),'<nu exista>'))
		where @gestiune is not null union all
	select '@categoriePret', rtrim(isnull((select max(c.Denumire) from categpret c where c.Categorie=@categoriePret),'<nu exista>'))
		where @categoriePret is not null union all
	select top 1 '@dataLunii', rtrim(lunaalfa)+' '+convert(varchar(4), year(@dataLunii)) from calstd where month(data)=month(@dataLunii) union all

--	autofiltrari
	select '@propLocm',	@loc_pref where @loc_pref<>'' union all
	select '@propGestiune',	@gest_pref where @gest_pref<>'' union all
	select '@rIntervalDocFinanciare',	@rIntervalDocFinanciare where @rIntervalDocFinanciare<>'' union all
	select '@dataSolduri', convert(varchar(20),@dataSolduri,103) where @rIntervalDocFinanciare<>''
	
	if @locatie is not null
	if @gestiune is null or not exists (select top 1 1 from gestiuni where Cod_gestiune=@gestiune and ISNULL(detalii.value('(/*/@custodie)[1]','bit'),0)=1)
	insert into @denumiri(parametru,valoare)
/*	select 'blah!', @gestiune union all
	select 'blah2!', @locatie
*/	select '@locatie', rtrim(isnull((select top 1 descriere FROM locatii l where l.cod_locatie=@locatie and (@gestiune is null or l.cod_gestiune=@gestiune)),'<nu exista>'))
		where @locatie is not null
	else
	insert into @denumiri(parametru,valoare)
	select '@locatie',
			rtrim(t.denumire)+ISNULL('/'+RTRIM(it.Descriere),'') as denumire
	from terti t left join infotert it on it.subunitate=t.Subunitate and it.tert=t.tert --and it.identificator<>''
	where rtrim(t.tert)+REPLICATE(' ',13-LEN(rtrim(t.tert)))+ISNULL(rtrim(it.identificator),'')=@locatie
	
	if @um is not null
	insert into @denumiri(parametru,valoare)
	select '@um', isnull((select rtrim(u.denumire) from um u where u.um=@um),'<nu exista>')

--	MF
	insert into @denumiri(parametru,valoare)
	select '@mFix', rtrim(isnull((select max(m.Denumire) from mfix m where m.Numar_de_inventar=@mFix),'<nu exista>'))
		where @mFix is not null
--	Imobilizari
	if exists (select 1 from sys.objects where name='imobilizari')
	insert into @denumiri(parametru,valoare)
	select '@imob', rtrim(isnull((select max(i.Denumire) from Imobilizari i where i.nrinv=@imob),'<nu exista>'))
		where @imob is not null
--	PC
	insert into @denumiri(parametru,valoare)
	select '@comanda', rtrim(isnull((select max(c.Descriere) from comenzi c where c.Comanda=@comanda),'<nu exista>')) 
		where @comanda is not null union all
	select '@grupaComanda', rtrim(isnull((select max(g.Denumire_grupa) from grcom g where g.Grupa=@grupaComanda),'<nu exista>')) 
		where @grupaComanda is not null
--	PS
	if exists (select 1 from sysobjects o where o.type='TF' and o.name='fDenumiriRapPS') 
	and exists (select 1 from sysobjects o where o.type='U' and o.name='istpers')
		insert into @denumiri(parametru,valoare)
		select parametru,valoare from dbo.fDenumiriRapPS(@sesiune,@parXML)

--	UA
	if exists (select 1 from sysobjects o where o.type='TF' and o.name='fDenumiriRapUA') 
	and exists (select 1 from sysobjects o where o.type='U' and o.name='antetfactAbon')
		insert into @denumiri(parametru,valoare)
		select parametru,valoare from dbo.fDenumiriRapUA(@sesiune,@parXML)
		
--	MM
	if exists (select 1 from sysobjects o where o.type='TF' and o.name='fDenumiriRapMM') 
	and exists (select 1 from sysobjects o where o.type='U' and o.name='elemactivitati')
		insert into @denumiri(parametru,valoare)
		select parametru,valoare from dbo.fDenumiriRapMM(@sesiune,@parXML)

--	Imobilizari
	if exists (select 1 from sysobjects o where o.type='TF' and o.name='fDenumiriRapImob') 
		insert into @denumiri(parametru,valoare)
		select parametru,valoare from dbo.fDenumiriRapImob(@sesiune,@parXML)
		
--	Bugetari
	if (@indicator is not null)		-->	s-ar putea ca tabela sa nu existe
	insert into @denumiri(parametru,valoare)
	select '@indicator', rtrim(isnull((select max(i.Denumire) from indbug i where i.Indbug=@indicator),'<nu exista>')) 
		where @indicator is not null
		
--	Bugetari
	if (@grindicator is not null)	-->	s-ar putea ca tabela sa nu existe
	insert into @denumiri(parametru,valoare)
	select '@grindicator', rtrim(isnull((select max(g.Denumire_grupa) from indbuggr g where g.Grupa=@grindicator),'<nu exista>')) 
		where @grindicator is not null
	
	if (@indicatorTB is not null)
	insert into @denumiri(parametru,valoare)	
	select '@indicatorTB', rtrim(isnull((case when @indicatorTB is not null then (select max(i.Denumire_Indicator) from indicatori i where i.Cod_Indicator=@indicatorTB) else '' end),'<nu exista>'))
		where @indicatorTB is not null
	
	if (isnull(@antetInventar,0)<>0)		--> poate ca nu exista antet inventar (?)
	insert into @denumiri(parametru,valoare)
	select '@dataInventar', rtrim(isnull((select convert(varchar(20),max(a.data),103) from antetinventar a 
			where a.idInventar=@antetInventar),'<nu exista>'))
			 
	-- MF
	if (@categoriaMF is not null)		--> poate ca nu exista codclasif (?)
	insert into @denumiri(parametru,valoare)
	select '@categoriaMF', rtrim(isnull((select max(c.Denumire) from Codclasif c 
			where replace(c.Cod_de_clasificare,@separator_categoriaMF,'')=@categoriaMF
				and (len(replace(c.Cod_de_clasificare,'.',''))=1 or
					len(replace(c.Cod_de_clasificare,'.',''))=2 and left(replace(c.Cod_de_clasificare,'.',''),1)='2')
			 ),'<nu exista>'))
	
	if (@categoriaMF is not null)		--> poate ca nu exista codclasif (?)
	insert into @denumiri(parametru,valoare)
	select '@codClasificareMF', rtrim(isnull((select max(c.Denumire) from Codclasif c 
			where	--rtrim(replace(c.Cod_de_clasificare,@separator_codClasificareMF,''))=
					rtrim(c.Cod_de_clasificare)=
					rtrim(@codClasificareMF)),'<nu exista>'))
		where @codClasificareMF is not null

	/*	Completare casa de sanatate cu denumirea. */
	update d set d.valoare=rtrim(e.val_inf)
	from @denumiri d
	left outer join extinfop e on e.cod_inf='#CASSAN' and e.marca=d.valoare
	where parametru='@'+rtrim(@codjudeta)

	-- functia SPecifica
	if exists (select 1 from sysobjects o where o.type='TF' and o.name='fDenumiriRapSP')
	insert into @denumiri(parametru,valoare)
	select parametru, valoare from fDenumiriRapSP(@sesiune, @parXML)
	return
end