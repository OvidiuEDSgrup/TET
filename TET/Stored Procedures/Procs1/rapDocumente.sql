--***
CREATE procedure rapDocumente(@sesiune varchar(50)=null,@datajos datetime,@datasus datetime,
				@detalii int=1,	--> 1=in detalii datele vin asa cum sunt in pozdoc, 2=doar gruparile superioare, 3=grupat pe document
				@tipRaport varchar(200)='Avize',	--> Avize, Receptii sau Intrari iesiri
				@ordonare int=1,	--> 1=cod/tip & numar & data, 2=denumire/data & tip & numar, Z-{1,2} = valoare
				@top int=null,		--> daca sa apara primele @top grupari superioare
				@nrmaximdetalii bigint=100000,	--> numarul maxim de randuri returnat (pentru a evita timpul indelungat de asteptare); daca este 0 se considera ca este nelimitat
				@Nivel1 varchar(2)=null, @Nivel2 varchar(2)=null, @Nivel3 varchar(2)=null, @Nivel4 varchar(2)=null, @Nivel5 varchar(2)=null,	--> nivelele de centralizare
				/*	Grupari  - lista alfabetica a codificarilor:
					CC	= Cont corespondent
					CF	= Cont factura
					CM	= Comanda
					CB	= Comanda beneficiar
					CO	= Cod
					CT	= Cont de stoc
					DA	= Data
					DO	= Document
					FA	= Factura
					FU	= Furnizor nomenclator
					FR	= Furnizor (intrare)
					GE	= Gestiune
					GP	= Gestiune primitoare
					GR	= Grupa nomenclator
					IB	= Indicator bugetar - pt acest caz se iau pozitiile documentului, se apeleaza procedura de luare indicatori si se re-grupeaza ulterior
					LO	= Loc de munca
					LU	= Luna
					LT	= Lot
					TE	= Tert
					TI	= Tip document
					--*/
			--> filtrele, in ordine alfabetica (va rog) pt ca sunt prea multe:
				@cod varchar(50)=null, @codintrare varchar(100)=null, @comanda varchar(50)=null,
				@comanda_beneficiar varchar(50)=null,
				@contCor varchar(40)=null, @contFactura varchar(40)=null, @ctstoc varchar(100)=null,
				@factura varchar(50)=null, @Furnizor varchar(20)=null, -->@furnizor = filtru pe furnizorul documentului de intrare
				@furnizor_nomenclator varchar(30)=null,
				@gestiune varchar(50)=null, @gestiuneprim varchar(50)=null, @greutate bit=0, --> daca sa apara greutatea
				@grupa varchar(20)=null,	--> filtru pe grupa de nomenclator
				@grupaTerti varchar(20)=null,
				@indicator varchar(20)=null,
				@lm varchar(50)=null,
				@locatia varchar(30)=null,
				@lot varchar(200)=null,
				@nrdoc varchar(200)=null,	--> filtru pe numar document
				@puncteLivrare bit=0,	--> daca @puncteLivrare=1 gruparile pe terti vor fi de fapt grupari pe terti + puncte livrare
				@pret_cu_amanuntul bit=0,
				@tert varchar(50)=null, 
				@tip_doc_str varchar(1000)=',AP,AC,AS,',	--> tipurile de documente concatenate, setat default pentru avize
				@tipArticole varchar(1000)='',	--> tipuri articole:	ST=Stocabile, SE=Servicii, sau tipurile de nomenclator "consacrate"
				@tipTert varchar(1)=null,	--> I=0=intracomunitar, U=1=UE, E=2=Extern
				@valneg bit=0,		--> daca sa aduca doar pozitiile de stornare, adica valoarea sa fie negativa; folosit in Avize
				@umalt varchar(200)=null,	--> daca se completeaza:	se recalculeaza cantitatile, fara a afecta valorile, folosind coeficientul de conversie din nomenclator;
													-->		pentru codurile de nomenclator care nu au respectiva unitate de masura se va pune cantitate 0
				@inPretCost int=0 --> Sa apara pretul de cost in loc de pretul de stoc
				)
as

declare @eroare varchar(max)
begin try
set transaction isolation level read uncommitted
--> verificari configurare nivele; e permisa doar completarea acestora in ordine, fara lipsuri; ultimele pot ramane necompletate
	if object_id('tempdb..#nivele') is not null drop table #nivele
	if object_id('tempdb..#final') is not null drop table #final
--/*
	declare @comSQL nvarchar(max)
	create table #final(tipnivel varchar(2000) default '', cod varchar(200) default '', parinte varchar(200) default '', nr_crt int default 0, cantitate decimal(15,3) default 0,
		valCost decimal(15,2) default 0, lm varchar(2000) default '',
		comanda varchar(2000) default '', gestiune varchar(2000)default '', TVA decimal(15,2) default 0, tip varchar(20) default '', numar varchar(20)  default '',
		data datetime default '1901-1-1', um varchar(50) default '', pret_de_stoc decimal(15,2) default 0, pret_vanzare decimal(15,2) default 0, pret_valuta decimal(15,2) default 0,
		discount decimal(15,2) default 0
		--> campurile specifice fiecarui raport se vor adauga ulterior cu alter table
		, nivel varchar(200) default 0, numeNivel varchar(2000) default '', ordine varchar(2000) default 0,
		codAfisat varchar(1000) default '', explicatii varchar(2000) default '', nivel1 varchar(200) default '', numeNivel1 varchar(2000) default '',
		valgr decimal(15,2) default 0, topgr int default 0)

		/*'+(case @tipRaport	when 'Avize' then 'sum(pfTVA) as pfTVA, sum(pcuTVA) as pcuTVA, SUM(adaos) as adaos, sum(greutate) greutate,'
							when 'Intrari iesiri' then 'max(cont_stoc) as cont_stoc, max(cont_factura) as cont_factura, max(codintrare) as codintrare,'
						else 'sum(valoare_furn) as valoare_furn, sum(pcuTVA) pcuTVA,' end)+'
						*/
--*/	if suser_name()='CLUJ\luci.maier' raiserror('Test eroare pt luci!',16,1)
	create table #nivele(nivel varchar(20), rang int)
	insert into #nivele(nivel, rang)	--> tabela doar pentru verificari
		select @nivel1 nivel,1 union all
		select @nivel2 nivel,2 union all
		select @nivel3 nivel,3 union all
		select @nivel4 nivel,4 union all
		select @nivel5 nivel,5

	--> nu are sens selectarea aceleiasi grupari de mai multe ori:
	if 1<(
	select top 1 count(1) from
	(	select nivel from #nivele) n
	where nivel is not null
	group by nivel order by count(1) desc)
	raiserror('Nu este permisa selectarea aceleiasi grupari de mai multe ori!',16,1)
	
	--> nu are sens selectarea nivelelor "in dezordine" - trebuie sa fie completate de la 1, in ordine crescatoare, fara pauze:
	
	if exists (select 1 from #nivele n where n.nivel is not null and exists (select 1 from #nivele nsup where nsup.nivel is null and nsup.rang<n.rang))
	raiserror('Gruparile nu sunt selectate corect! E permisa completarea acestora in ordine crescatoare, incepand cu prima, fara pauze!',16,1)
	
if object_id('tempdb..#nivele') is not null drop table #nivele

/**	Pregatire filtrare pe proprietati utilizatori*/
select @tipTert=(case @tipTert when 'I' then 0
								when 'U' then 1
								when 'E' then 2 else null end),
		@valneg=(case when @valneg is null then 0 else @valneg end),
		@codintrare=ltrim(rtrim(@codintrare)),
		@comanda=rtrim(ltrim(@comanda)),
		@comanda_beneficiar=(case when @comanda_beneficiar='' then '%' else @comanda_beneficiar end),
		@indicator=rtrim(ltrim(@indicator))


--> organizare pentru filtrarea pe tipuri articole:
set @tipArticole=isnull(@tipArticole,'')
if @tipArticole<>''
	select @tipArticole=
				','+(case @tipArticole	when 'ST' then 'M,P,A,O'	--> Stocabile inseamna cele 4 tipuri de nomenclator
										when 'SE' then 'R,S'		--> Servicii inseamna furnizate sau prestate
								else @tipArticole end				--> pt filtrare pe un tip de nomenclator propriu-zis (inclusiv mijloace fixe)
					)+','

declare @cSub varchar(20)
select @cSub=val_alfanumerica from par where Tip_parametru='GE' and Parametru='SUBPRO'
declare @valgr varchar(max),	--> campul valoare reflectat de grafic; depinde de raportul apelant
		@pret_wIaPreturi bit=0	--> daca sa se ia preturile cu wIaPreturi (e necesar pentru Transferuri deocamdata)
		
select @tip_doc_str=(case when left(@tip_doc_str,1)<>',' then ',' else '' end)+replace(@tip_doc_str,' ','')+(case when right(@tip_doc_str,1)<>',' then ',' else '' end)
select @tip_doc_str=(case @tipRaport --when 'Avize' then ',AP,AC,AS,'
										when 'Receptii' then ',RM,RS,'
										when 'Transferuri' then ',TE,'
										else @tip_doc_str
							end)
		, @pret_wIaPreturi=(case when @tipRaport='Transferuri' and @gestiune is not null then 1 else 0 end)
		
select @tip_doc_str=(case when charindex(',,',@tip_doc_str)>0 then null else @tip_doc_str end)

if left(@tip_doc_str,1)=',' set @tip_doc_str='('''+substring(@tip_doc_str,2,len(@tip_doc_str))
if right(@tip_doc_str,1)=',' set @tip_doc_str=substring(@tip_doc_str,1,len(@tip_doc_str)-1)+''')'
set @tip_doc_str=replace(@tip_doc_str,',',''',''')


select @valgr=(case @tipRaport when 'Avize' then 'pcutva' when 'Transferuri' then 'pftva'
										else 'valCost' end)
select @ordonare=(case when @ordonare in (1,2) then @ordonare else 3 end)
select @greutate=(case when @tipRaport='Avize' then @greutate else 0 end)
		
		--> in rest la transferuri se iau datele ca la avize (mai sus au fost setate tipul='TE', flag-ul de calcul preturi si valoarea graficului ca fiind valoarea fara tva):
select @tipRaport=(case when @tipRaport='Transferuri' then 'Avize' else @tipRaport end)

select @comsql='alter table #final add '+
	(case @tipraport when 'Avize' then 'pfTVA decimal(15,4) default 0, pcuTVA decimal(15,2) default 0, adaos decimal(15,2) default 0, greutate decimal(15,4) default 0'
					when 'Intrari iesiri' then 'cont_stoc varchar(40), cont_factura varchar(40), codintrare varchar(50)'
					else 'valoare_furn decimal(15,2), pcuTVA decimal(15,2)'
		end)

exec (@comsql)
	
--select @tipRaport=(case @tipRaport when 'Avize' then '("AP","AC","AS")' else '("RM","RS")' end)
declare @grupaNomenclatorpeNivele bit,
		@pret_de_stoc varchar(100)
select @grupaNomenclatorpeNivele=isnull((select val_logica from par where tip_parametru='GE' and parametru='GRUPANIV'),0),
		@ctstoc=rtrim(ltrim(@ctstoc))+'%',
		@contCor=rtrim(ltrim(@contCor))+'%',
		@contFactura=rtrim(ltrim(@contFactura))+'%',
		@pret_de_stoc=(case when @inPretCost=0 then 'p.pret_de_stoc' else 'isnull(pu.pret_unitar,p.pret_de_stoc)' end)
	--> daca pentru grupele de nomenclator e activa setarea de grupe pe nivele se filtreaza cu 'like %'

declare @tabeleJoin varchar(4000), @verificareNrRanduri varchar(max), @prefixcomsql varchar(max)
--> in @prefixcomsql se completeaza comenzi pregatitoare pentru comanda sql (quoted identifier, variabile necesare raportarii erorilor si calculului nr-ului de randuri):
select @prefixcomsql='
	declare @nr_randuri bigint, @nrmaximdetalii bigint, @eroare varchar(max)
	select @nrmaximdetalii='+convert(varchar(20),@nrmaximdetalii)
	
--> daca se depaseste nr maxim de randuri configurate pt raport se genereaza "eroare de tip warning"; mesajul e folosit pt apel fara @top - functioneaza rapid - si cu @top - dureaza mai mult
	--> aici se creeaza mesajul, de fapt se foloseste mai jos, in doua locuri
select @verificareNrRanduri='
	if (@nr_randuri>@nrmaximdetalii)
	begin
		select @eroare=
''Numarul de linii returnate de server pentru raport (>''+convert(varchar(20),@nrmaximdetalii)+'') ar conduce la timp de procesare indelungat si, posibil, la eroare.
In aceasta situatie se recomanda urmatoarele: renuntarea la anumite grupari (in special generarea cu detalii), utilizarea filtrelor din parametri, micsorarea intervalului calendaristic.

(Raportul se poate rula in configuratia curenta efectuand clic pe titlul de mai sus)
''
		raiserror(@eroare,16,1)
	end'

set @tabeleJoin=''

declare @nivelCurent varchar(2),@campnivel varchar(100),@groupby varchar(100)
declare @campnivel1 varchar(100),
		@s_nivel1 varchar(200),
		@s_nivel2 varchar(200),
		@s_nivel3 varchar(200),
		@s_nivel4 varchar(200),
		@s_nivel5 varchar(200),
		@s_nivel6 varchar(500),	--> 6 = nivel detalii
		@setare_reguli_nivel nvarchar(max)
select @detalii=(case when @detalii not in (3,1) then 2 else @detalii end)
select @s_nivel6=(case @detalii when 3 then 'p.tip+" "+rtrim(p.numar)+" "+convert(varchar(10),p.data,103)'
								when 1 then 'p.idpozdoc'
								else 'null' end)

declare @utilizator varchar(20), @eLmUtiliz int, @eGestUtiliz int,
	@comandaProprietati varchar(max)

select @utilizator=dbo.fIaUtilizator(@sesiune), @eLmUtiliz=0, @eGestUtiliz=0, @comandaProprietati=''
if isnull(@utilizator,'')='' raiserror('Utilizatorul nu a fost identificat!',15,1)
select @eLmUtiliz=1 from lmfiltrare where utilizator=@utilizator
select @eGestUtiliz=1 from fPropUtiliz(@sesiune) where valoare<>'' and cod_proprietate='GESTIUNE'

if @eLmUtiliz=1
select @comandaProprietati='declare @LmUtiliz table(valoare varchar(200))
insert into @LmUtiliz(valoare)
select cod from lmfiltrare where utilizator="'+@utilizator+'"'
if @eGestUtiliz=1
select @comandaProprietati=@comandaProprietati+'
declare @GestUtiliz table(valoare varchar(200), cod_proprietate varchar(20))
insert into @GestUtiliz(valoare, cod_proprietate)
select valoare, cod_proprietate from fPropUtiliz(@sesiune) where valoare<>"" and cod_proprietate="GESTIUNE"
'
--> se stabileste campul fiecarei grupari:
select @setare_reguli_nivel='SET QUOTED_IDENTIFIER OFF
							set @s_nivel=(case @nivel when "TE" then "rtrim(p.tert)'+
							(case when @puncteLivrare<>1 then '"' else
								'+(case when p.tip=''AP'' and d.gestiune_primitoare<>"""" then ""|""+d.gestiune_primitoare else """" end)"'
								end)+'
							when "TI" then "p.tip"
							when "CF" then "p.cont_factura"
							when "CT" then "p.cont_de_stoc"
							when "CC" then "(case when p.tip in(''RS'',''RM'',''RP'') then p.cont_factura else p.cont_corespondent end)"
							when "CO" then "p.cod"
							when "GE" then "p.gestiune"
							when "LU" then "convert(varchar(20),year(p.data))+'' ''+convert(varchar(20),month(p.data))"
							when "LO" then "p.loc_de_munca"
							when "DA" then "convert(varchar(20),p.data,102)"
							when "GR" then "n.tip+""|""+n.grupa"
							when "FA" then "p.factura"
							when "CM" then "p.comanda"
							when "CB" then "rtrim(cb.comanda_beneficiar)"
							when "FU" then "n.furnizor"
							when "FR" then ''isnull(s.tert,p.tert)''
							when "DO" then ''p.tip+" "+rtrim(p.numar)+" "+convert(varchar(10),p.data,103)''
							when "GP" then "p.gestiune_primitoare"
							when "IB" then "p.idpozdoc"
							when "LT" then ''isnull(nullif(rtrim(s.lot),""),p.lot)''
							else "null" end)
							'+	--> nu e permis sa se lase vreo valoare null deoarece esueaza concatenarile de la formarea gruparii recursive de la final: 
							'set @s_nivel=(case when @s_nivel="null" then "null" else "isnull("+@s_nivel+","""")" end)'

exec sp_executesql @setare_reguli_nivel,N'@s_nivel nvarchar(200) output, @nivel nvarchar(200)', @nivel=@nivel1, @s_nivel=@s_nivel1 output
exec sp_executesql @setare_reguli_nivel,N'@s_nivel nvarchar(200) output, @nivel nvarchar(200)', @nivel=@nivel2, @s_nivel=@s_nivel2 output
exec sp_executesql @setare_reguli_nivel,N'@s_nivel nvarchar(200) output, @nivel nvarchar(200)', @nivel=@nivel3, @s_nivel=@s_nivel3 output
exec sp_executesql @setare_reguli_nivel,N'@s_nivel nvarchar(200) output, @nivel nvarchar(200)', @nivel=@nivel4, @s_nivel=@s_nivel4 output
exec sp_executesql @setare_reguli_nivel,N'@s_nivel nvarchar(200) output, @nivel nvarchar(200)', @nivel=@nivel5, @s_nivel=@s_nivel5 output
--/*
declare @identificare_grupari nvarchar(max),
		@grContFactura varchar(1),
		@grContCorespondent varchar(1),
		@grCont varchar(1),
		@grTert varchar(1),
		@grCod varchar(1),
		@grGestiune varchar(1),
		@grLuna varchar(1),
		@grLocm varchar(1),
		@grData varchar(1),
		@grGrupa varchar(1),
		@grFactura varchar(1),
		@grComanda varchar(1),
		@grComandaBeneficiar varchar(1),
		@grFurnizorNomenclator varchar(1),
		@grGestiunePrimitoare varchar(1),
		@grTipuriDocumente varchar(1),
		@grIndicatoriBugetari varchar(1),
		@grLot varchar(1),
		@grFurnizorIntrare varchar(1)
	
--> se identifica datele necesare pentru grupari, fara a se cunoaste ordinea gruparilor (ca sa se stie de ce date e nevoie in continuare)
select @identificare_grupari='
select @tipgr=(case @cod when '''+isnull(@nivel1,'')+''' then ''1''
					when '''+isnull(@nivel2,'')+''' then ''2''
					when '''+isnull(@nivel3,'')+''' then ''3''
					when '''+isnull(@nivel4,'')+''' then ''4''
					when '''+isnull(@nivel5,'')+''' then ''5'' else null end)'

exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='CF', @tipgr=@grContFactura output
exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='CC', @tipgr=@grContCorespondent output
exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='CT', @tipgr=@grCont output
exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='TE', @tipgr=@grTert output
exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='CO', @tipgr=@grCod output
exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='GE', @tipgr=@grGestiune output
exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='LU', @tipgr=@grLuna output
exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='LO', @tipgr=@grLocm output
exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='DA', @tipgr=@grData output
exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='GR', @tipgr=@grGrupa output
exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='FA', @tipgr=@grFactura output
exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='CM', @tipgr=@grComanda output
exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='CB', @tipgr=@grComandaBeneficiar output
exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='FU', @tipgr=@grFurnizorNomenclator output
exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='GP', @tipgr=@grGestiunePrimitoare output
exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='TI', @tipgr=@grTipuriDocumente output
exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='IB', @tipgr=@grIndicatoriBugetari output
exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='LT', @tipgr=@grLot output
exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='FR', @tipgr=@grFurnizorIntrare output
--exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='DO', @tipgr=@grFurnizorNomenclator output

set @comSQL=@prefixComSql+'
	if object_id("tempdb..#pozitii") is not null drop table #pozitii
	--if object_id("tempdb..#final") is not null drop table #final
	if object_id("tempdb..#fluni") is not null drop table #fluni
	if object_id("tempdb..#top") is not null drop table #top
	if object_id("tempdb..#pcost") is not null drop table #pcost
	'+@comandaProprietati
	--> creez tabela temporara pentru pret de cost
	+(case when @inPretCost=1 then char(10)+'
		select data_lunii,comanda,max(pret_unitar) as pret_unitar 
		into #pcost
		from pretun
		where data_lunii between "'+convert(char(10),@datajos,101)+'" and "'+convert(char(10),@datasus,101)+'"'
		+(case when @cod is not null then char(10)+'and comanda like @cod' else '' end)+
		+char(10)+'group by data_lunii,comanda' else '' end)

declare @s_umalt varchar(200)
select @s_umalt=''''+rtrim(@umalt)+''''

set @tabeleJoin=/*(case when @grGrupa is not null or @grFurnizorNomenclator is not null or @grupa is not null or @furnizor_nomenclator is not null or @greutate=1 or @tipArticole<>''
		then */'left join nomencl n on p.cod=n.cod' /*else '' end )	*/+ '
	'+(case when @grupaTerti is not null or @tipTert is not null then 'left join terti t on t.subunitate=@csub and t.tert=p.tert' else '' end )+ '
	'+(case when @puncteLivrare=1 then 'inner join doc d on p.subunitate=d.subunitate and p.tip=d.tip and p.data=d.data and p.numar=d.numar' else '' end)+'
	'+(case when @Furnizor is not null or @lot is not null or @grLot is not null or @grFurnizorIntrare is not null or @inpretcost=1
		then (case when @inpretcost=1 then 'left ' else 'inner ' end)+
		'join pozdoc s on s.idpozdoc = coalesce(p.idintrarefirma, p.idintrare, p.idpozdoc) and s.subunitate="1"'
			+(case when @inpretcost=1 then '' else ' and s.tip in ("RM","RS")' end)	--> inainte de luarea pretului de cost se filtra pe tip document rm si rs; am mentinut conditia
		else '' end)+'
	'+	(case when @furnizor is not null then ' and s.tert like "'+@furnizor+'"' else '' end)+'
	'+(case when @tipTert is not null then 'left join infotert i on i.subunitate="1" and i.tert=t.tert and i.identificator=""' else '' end)+'
	'+(case when @s_umalt is not null then 'left join UMProdus u on u.cod=p.cod and u.um='+@s_umalt+'' else '' end)+'
	'+(case when @comanda_beneficiar is not null then 'inner join comenzi cb on cb.subunitate=p.subunitate and cb.comanda=p.comanda and cb.comanda_beneficiar<>""'
			when @grComandaBeneficiar is not null then 'left join comenzi cb on cb.subunitate=p.subunitate and cb.comanda=p.comanda' else '' end)+'
	'+(case when @inPretCost=0 then '' else 'left join #pcost pu on dbo.eom(s.data)=pu.data_lunii and pu.comanda=p.cod' end)

set @comSQL=@comSQL+
'	create table #pozitii (utilizator varchar(200),
	'+	--> campurile folosite pentru definirea gruparilor:
	'nivel1 varchar(200), nivel2 varchar(200), nivel3 varchar(200), nivel4 varchar(200), nivel5 varchar(200), nivel6 varchar(200),
	'+	--> campurile care vor contine denumirile atasate gruparilor:
	'numeNivel1 varchar(2000), numeNivel2 varchar(2000), numeNivel3 varchar(2000), numeNivel4 varchar(2000), numeNivel5 varchar(2000), numeNivel6 varchar(2000),
	'+	--> valori, detalii:
	'cantitate decimal(15,3), valCost decimal(15,2), tip varchar(20), numar varchar(20), data datetime, TVA decimal(15,2),
		um varchar(50), pret_de_stoc decimal(15,2), pret_vanzare decimal(15,2), pret_valuta decimal(15,2),
		discount decimal(15,2), indbug varchar(100), idpozdoc int,
	'		--> campuri suplimentare avize:
	+(case @tipRaport
		when 'Avize' then 'pfTVA decimal(15,4), pcuTVA decimal(15,2), adaos decimal(15,2), greutate decimal(15,4),
	'		--> campuri suplimentare intrari iesiri:
		when 'Intrari iesiri' then ' cont_stoc varchar(40), cont_factura varchar(40), codintrare varchar(50),
	'	else 'valoare_furn decimal(15,2), pcuTVA decimal(15,2),' end)+
		--> ordonarile pot fi pe denumiri, coduri si documente, dar exista exceptii - de exemplu pentru ordonarea pe date si luni ordonarea pe denumire nu are sens; prin campurile urmatoare se vor trata ordonarile:
	'ordNivel1 varchar(2000) default "", ordNivel2 varchar(2000) default "",	ordNivel3 varchar(2000) default "", ordNivel4 varchar(2000) default "", ordNivel5 varchar(2000) default "", ordNivel6 varchar(2000) default ""
	'	--> codificarile parametrilor de grupare; in rapoarte, folosindu-se grupari recursive, e mai la indemana ca tipul nivelului sa fie pe gruparea curenta, in caz de nevoie;
		--> se folosesc:
			--> la identificarea gruparilor "exceptionale" care se ordoneaza pe cod, chiar daca s-a cerut ordonare pe denumire
			--> in apel prin hiperlink - intrari iesiri - pentru a se determina daca e cazul sa se completeze filtre suplimentare gruparii curente
	+', tipNivel1 varchar(2000), tipNivel2 varchar(2000), tipNivel3 varchar(2000), tipNivel4 varchar(2000), tipNivel5 varchar(2000), tipNivel6 varchar(2000)
	'+	--> campuri auxiliare, utilizate pt hiperlink de pe grupare pe alt raport in intrari iesiri:
	', lm varchar(2000), comanda varchar(2000), gestiune varchar(2000), cod varchar(200), explicatii varchar(2000))
	
	insert into #pozitii(utilizator, nivel1, nivel2, nivel3, nivel4, nivel5, nivel6,
	numeNivel1, numeNivel2,
	numeNivel3, numeNivel4, numeNivel5, numeNivel6, cantitate,
	valCost, tip, numar, data, TVA, idpozdoc,
	um, pret_de_stoc, pret_vanzare, pret_valuta, discount,
	'	--> campuri suplimentare avize:
		+(case @tipRaport
			when 'Avize' then 'pfTVA, pcuTVA, adaos, greutate,
		'	--> campuri suplimentare intrari iesiri:
			when 'Intrari iesiri' then ' cont_stoc, cont_factura, codintrare,
		'	else 'valoare_furn, pcuTVA,
		' end)
		+'
	ordNivel1, ordNivel2,	ordNivel3, ordNivel4, ordNivel5, ordNivel6
	, tipNivel1, tipNivel2, tipNivel3, tipNivel4, tipNivel5, tipNivel6
	, lm, comanda, gestiune, cod, explicatii
	)
select 	'+(case when @top is null and @nrmaximdetalii>0 then 'top '+convert(varchar(20),@nrmaximdetalii+1) else '' end)
		+'"'+@utilizator+'" as utilizator, 
		--rtrim(isnull('+@s_nivel1+',"")) as nivel1, rtrim(isnull('+@s_nivel2+',"")) as nivel2, rtrim(isnull('+@s_nivel3+',"")) as nivel3,
		--rtrim(isnull('+@s_nivel4+',"")) as nivel4, rtrim(isnull('+@s_nivel5+',"")) as nivel5, rtrim(isnull('+@s_nivel6+',"")) as nivel6,
		rtrim('+@s_nivel1+') as nivel1, rtrim('+@s_nivel2+') as nivel2, rtrim('+@s_nivel3+') as nivel3,
		rtrim('+@s_nivel4+') as nivel4, rtrim('+@s_nivel5+') as nivel5, rtrim('+@s_nivel6+') as nivel6,	--*/
		'
		--+(case when @grLuna is not null then 'max(l.lunaalfa)+" "+convert(varchar(20),max(l.an))' else 'null' end )+' lunaalfa,
		+
		'"<"+rtrim('+@s_nivel1+')+">" as numeNivel1, "<"+rtrim('+@s_nivel2+')+">" as numeNivel2, "<"+rtrim('+@s_nivel3+')+">" as numeNivel3,
		"<"+rtrim('+@s_nivel4+')+">" as numeNivel4, "<"+rtrim('+@s_nivel5+')+">" as numeNivel5, "<"+rtrim('+@s_nivel6+')+">" as numeNivel6,
		'+case when @umalt is null then 'sum(p.cantitate)' else 'sum(case when isnull(u.coeficient,0)=0 then 0 else p.cantitate/isnull(u.coeficient,0) end)' end+' as cantitate,		
		sum(case when n.tip="S" then 0 else round(p.cantitate*'+(case when @pret_cu_amanuntul=0 then @pret_de_stoc else 'p.Pret_cu_amanuntul' end)+',2) end) as valCost,
		max(p.tip) tip, max(p.numar) numar, max(p.data) data, sum(p.tva_deductibil) as TVA, max(p.idpozdoc) idpozdoc,
		max(n.um) um, max(case when n.tip="S" then 0 else '+@pret_de_stoc+' end) pret_de_stoc, max(p.pret_vanzare) pret_vanzare, max(p.pret_valuta) pret_valuta, max(p.discount) discount,
		'	--> campuri suplimentare avize:
		+(case @tipRaport
			when 'Avize' then 'sum(round(p.cantitate*p.pret_vanzare,2)) as pfTVA,
				sum(round(p.cantitate*p.pret_vanzare,2)+p.tva_deductibil) as pcuTVA,
				sum(case when n.tip="S" then 0 else round(p.cantitate*(p.pret_vanzare-'+(case when @pret_cu_amanuntul=0 then @pret_de_stoc else 'p.Pret_cu_amanuntul' end)+'),2) end) as adaos,
				'+(case when @greutate=1 then 'sum(n.greutate_specifica*p.cantitate)' else '0' end)+' greutate,
		'	--> campuri suplimentare intrari iesiri:
			when 'Intrari iesiri' then 
				+'max(isnull(p.cont_de_stoc,'''')) as cont_stoc,
				max(isnull((case when p.tip in(''RS'',''RM'',''RP'') then p.cont_factura else p.cont_corespondent end),'''')) as cont_factura,
				max(isnull(p.cod_intrare,'''')) as codintrare,
				'
			else 'sum(round(p.cantitate*p.pret_valuta*(case when p.valuta<>"" then p.curs else 1 end),2)) as valoare_furn,
				sum(round(p.cantitate*p.pret_valuta*(case when p.valuta<>"" then p.curs else 1 end),2)+p.TVA_deductibil) as pcuTVA,
			' end)
		+'null ordNivel1, null ordNivel2, null ordNivel3,
		null ordNivel4, null ordNivel5, null ordNivel6,
		"'+isnull(@Nivel1,'')+'" tipNivel1, "'+isnull(@Nivel2,'')+'" tipNivel2, "'+isnull(@Nivel3,'')+'" tipNivel3, "'+isnull(@Nivel4,'')+
			'" tipNivel4, "'+isnull(@Nivel5,'')+'" tipNivel5, "'+(case when @detalii in (3,1) then 'DE' else '' end)+'" tipNivel6
		, max(p.loc_de_munca) lm, max(p.comanda) comanda, max(p.gestiune) gestiune, max(p.cod) cod, "cont de stoc: "+max(p.cont_de_stoc)
	from pozdoc p
	'+@tabeleJoin+'
	 where p.Subunitate=@cSub and (p.data between convert(char(10),@datajos,101) and (convert(char(10),@datasus,101)))
		'+(case when @tip_doc_str is null then '' else ' and p.tip in '+@tip_doc_str end)
		+(case when @cod is null then '' else ' and (p.cod like @cod)' end)
		+(case when @nrdoc is null then '' else ' and (p.numar = @nrdoc)' end)
		+(case when @codintrare is null then '' else ' and p.Cod_intrare=@codintrare' end)
		+(case when @comanda is null then '' else ' and left(p.Comanda,20)=@comanda' end)
		+(case when @contCor is null then '' else ' and isnull((case when p.tip in(''RS'',''RM'',''RP'') then p.cont_factura else p.cont_corespondent end),'''') like @contCor' end)
		+(case when @ctstoc is null then '' else ' and p.cont_de_stoc like @ctstoc' end)
		+(case when @contFactura is null then '' else ' and p.cont_factura like @contFactura' end)
		+(case when @factura is null then '' else ' and p.factura=@factura' end)
		+(case when @furnizor_nomenclator is null then '' else ' and n.furnizor=@furnizor_nomenclator' end)
		+(case when @gestiune is null then '' else ' and p.gestiune like @gestiune' end)
		+(case when @gestiuneprim is null then '' else ' and p.gestiune_primitoare=@gestiuneprim' end)
		+(case when @grupa is null then ''
				else ' and n.Grupa like @grupa'+(case when @grupaNomenclatorpeNivele=1 then '%' else '' end)
			end)
		+(case when @tipArticole='' then '' else ' and charindex(","+rtrim(n.tip)+",","+@tipArticole")>0' end)
		+(case when @grupaTerti is null then '' else ' and t.Grupa=@grupaTerti' end)
		--+(case when @indicator is null then '' else ' and substring(p.Comanda,21,20) like @indicator' end)
		+(case when @lm is null then '' else ' and p.loc_de_munca like @lm+''%''' end)
		+(case when @locatia is null then '' else ' and p.locatie=@locatia' end)
		+(case when @tert is null then '' else ' and p.tert=@tert' end)
		+(case when @lot is null then '' else ' and isnull(nullif(rtrim(s.lot),""),p.lot) like @lot' end)
		+(case when @eLmUtiliz=0 then '' else ' and exists (select 1 from @LmUtiliz u where u.valoare=p.Loc_de_munca)' end)
		+(case when @eGestUtiliz=0 then '' else ' and (p.tip in (''AS'',''RS'',''PF'',''CI'') or exists (select 1 from @GestUtiliz u where u.valoare=p.Gestiune))' end)
		+(case when @tipTert is null then '' else ' and i.zile_inc=@tipTert' end)
		+(case when @valneg=0 then '' else ' and p.cantitate<0' end)
		+(case when @comanda_beneficiar is null then '' else 'and cb.comanda_beneficiar like "'+@comanda_beneficiar+'"' end)
		/*		and	(@grupaTerti is null or t.Grupa=@grupaTerti)
		and (@grupa is null or n.grupa like @grupa)
		and (@furnizor_nomenclator is null or n.furnizor=@furnizor_nomenclator)'*/
	+' GROUP BY p.subunitate'+(case when @s_nivel1='null' then '' else ','+@s_nivel1 end)--+@s_nivel2+','+@s_nivel3+','+@s_nivel4+','+@s_nivel5+
				+(case when @s_nivel2='null' then '' else ','+@s_nivel2 end)
				+(case when @s_nivel3='null' then '' else ','+@s_nivel3 end)
				+(case when @s_nivel4='null' then '' else ','+@s_nivel4 end)
				+(case when @s_nivel5='null' then '' else ','+@s_nivel5 end)
				+(case when @detalii=2 then '' else ','+@s_nivel6 end)
				+(case when @pret_wIaPreturi=0 then '' else ', p.cod' end)	--> am nevoie de codul de produs daca iau preturi cu wIaPreturi
				+(case when @indicator is null then '' else ',p.idpozdoc' end)
	+'
	--select * from #pozitii
	'
--> daca se depaseste nr maxim de randuri configurate pt raport se genereaza "eroare de tip warning":
set @comSQL=@comSQL+case when @nrmaximdetalii>0 and @top is null then 
	'select @nr_randuri=rowcount_big()
	'+@verificareNrRanduri else '' end
--> luarea preturilor cu wIaPreturi (daca e necesara); se calculeaza preturile la @datasus (?e bine?); de asemenea nu prea stiu ce face wIaPreturi cand nu exista filtre pe tert si gestiune:
-------------------------------------	
	if @pret_wIaPreturi=1
	begin
	select @comsql=@comsql+'
			declare @px xml

			create table #preturi(cod varchar(20))
			exec CreazaDiezPreturi
			
			insert into #preturi (cod)
			select pz.cod
			from #pozitii pz
			group by pz.cod
			
			select @px = (select @gestiune as gestiune, CONVERT(varchar(10), @datasus, 101) as data for xml raw)
			exec wIaPreturi @sesiune = @sesiune, @parXML = @px
			
			update pz set pret_vanzare=pr.pret_vanzare, pftva=pz.cantitate*pr.pret_vanzare
			from #pozitii pz inner join #preturi pr on pz.cod=pr.cod and pr.pret_vanzare is not null
			
			drop table #preturi
		'
	end
--> daca se genereaza/filtreaza pe indicator bugetar sunt necesar cativa pasi suplimentari:
-------------------------------------
if @grIndicatoriBugetari is not null or @indicator is not null
begin
	--> in prealabil s-a grupat pe idpozdoc pt indicator bugetar
	--> se apeleaza procedura de luare indicator bugetar
	set @comSQL=@comSQL+'
		select "" as furn_benef, "pozdoc" as tabela, idpozdoc as idPozitieDoc, convert(varchar(200),"") indbug into #indbugPozitieDoc 
		from #pozitii
		
		exec indbugPozitieDocument @sesiune=@sesiune, @parXML=null
		
		update p set p.indbug=ib.indbug
		from #pozitii p
			left outer join #indbugPozitieDoc ib on ib.idPozitieDoc=p.idpozdoc
		
		drop table #indbugPozitieDoc
		'+(case when @indicator is not null then 'delete p from #pozitii p where p.indbug not like @indicator' else '' end)
		
	if @grIndicatoriBugetari is not null
	set @comsql=@comsql+'
		update p set nivel'+@grIndicatoriBugetari+'=p.indbug from #pozitii p'
end
-------------------------------------
--> identare luna  - un spatiu in fata numarului lunilor <10 - pt o ordonare corecta
if @grLuna  is not null select @comSQL=@comSQL+'
	update s set
		nivel'+@grLuna+'=convert(varchar(20),year(s.data))+" "+replace(str(month(s.data),2,0),'' '',''0''),
		numeNivel'+@grLuna+'=convert(varchar(20),year(s.data))+'' ''+replace(str(month(s.data),2,0),'' '',''0'')
	from #pozitii s'
--	test	select @comsql for xml path('')

if exists (select 1 from sys.objects o where o.name='rapDocumenteSP')
begin
	declare @parxml varchar(4000)
	select @parxml=(select @sesiune sesiune, convert(char(10),@datajos,101) datajos, convert(char(10),@datasus,101) datasus,
					@detalii detalii, @tipRaport tipRaport, @ordonare ordonare, @top [top],
					@nrmaximdetalii nrmaximdetalii,
					@Nivel1 Nivel1, @Nivel2 Nivel2, @Nivel3 Nivel3, @Nivel4 Nivel4, @Nivel5 Nivel5,
					@cod cod, @codintrare codintrare, @comanda comanda,
					@contCor contCor, @contFactura contFactura, @ctstoc ctstoc,
					@factura factura, @Furnizor Furnizor,
					@furnizor_nomenclator furnizor_nomenclator,
					@gestiune gestiune,
					@gestiuneprim gestiuneprim,
					@greutate greutate,
					@grupa grupa, @grupaTerti grupaTerti, @indicator indicator, @lm lm,
					@locatia locatia, @lot lot,
					@puncteLivrare puncteLivrare, @pret_cu_amanuntul pret_cu_amanuntul,
					@tert tert,  @tip_doc_str tip_doc_str, @tipArticole tipArticole,
					@tipTert tipTert, @valneg valneg for xml raw)
	
	select @comsql=@comsql+'
		exec rapDocumenteSP @sesiune=@sesiune, @parxml=@parxml
		'
end

/*
exec (@comSQL)
select @comSQL=@prefixComSql*/

--> selectarea datelor in cazul in care se cer doar primele @top grupari superioare
declare @joinTop varchar(max)
select @joinTop=''
if @top is not null
begin
	select @comSQL=@comSQL+'
		select row_number() over (order by sum('+@valgr+') '+(case when @top<0 then 'asc' else 'desc' end)+') as cate, 
			'+(case when isnull(@nivel1,'')<>'' then 'a.nivel1' else 'a.idpozdoc' end)+' as nivelTop into #top from #pozitii a
			group by '+(case when isnull(@nivel1,'')<>'' then 'a.nivel1' else 'a.idpozdoc' end)
		+'
		update p set p.nivel1="<Restul>",
					p.nivel2=(case when p.nivel2 is null then null else "<Restul>" end),
					p.nivel3=(case when p.nivel3 is null then null else "<Restul>" end),
					p.nivel4=(case when p.nivel4 is null then null else "<Restul>" end),
					p.nivel5=(case when p.nivel5 is null then null else "<Restul>" end),
					p.nivel6=(case when p.nivel6 is null then null else "<Restul>" end),
					p.numeNivel1="<Restul>",p.numeNivel2=null,p.numeNivel3=null,p.numeNivel4=null,p.numeNivel5=null,p.numeNivel6=null
					,p.numar="<Restul>",p.tip="--",p.data="", p.um="--"
		 from #pozitii p inner join
		 #top t on t.nivelTop='+(case when isnull(@nivel1,'')<>'' then 'p.nivel1' else 'p.idpozdoc' end)+' and t.cate>'+convert(varchar(20),abs(@top))
/*		+' delete #top where cate>'+convert(varchar(20),abs(@top))
			--> daca se depaseste nr maxim de randuri configurate pt raport se genereaza "eroare de tip warning":
	select @joinTop=' inner join #top t on a.nivel1=t.nivelTop
	'*/
	select @comsql=@comsql
		+case when @top<0 then '
		delete p from #pozitii p where p.nivel1="<Restul>"' else '' end
		+case when @nrmaximdetalii>0 then '
		select @nr_randuri=count(1) from #pozitii a '
		+'where nivel1<>"<Restul>"'
		+@verificareNrRanduri else '' end
end

/*
exec (@comSQL)
select @comSQL=@prefixComSql
*/
--> culegere denumiri:

if @grContFactura is not null
	select @comSQL=@comSQL+'
		update s set numeNivel'+@grContFactura+'=rtrim(isnull(c.denumire_cont,"")) from #pozitii s inner join conturi c on c.subunitate=@cSub and c.cont=nivel'+@grContFactura

if @grCont is not null
	select @comSQL=@comSQL+'
		update s set numeNivel'+@grCont+'=rtrim(isnull(c.denumire_cont,"")) from #pozitii s inner join conturi c on c.subunitate=@cSub and c.cont=nivel'+@grCont

if @grContCorespondent is not null
	select @comSQL=@comSQL+'
		update s set numeNivel'+@grContCorespondent+'=rtrim(isnull(c.denumire_cont,"")) from #pozitii s inner join conturi c on c.subunitate=@cSub and c.cont=nivel'+@grContCorespondent

if @grTert is not null 
begin
	select @comSQL=@comSQL+'
		update s set numeNivel'+@grTert+'=rtrim(isnull(t.denumire,"")) from #pozitii s inner join terti t on t.subunitate=@cSub and t.tert=nivel'+@grTert
	if @puncteLivrare=1 select @comSQL=@comSQL+'
		update s set numeNivel'+@grTert+'=rtrim(isnull(t.denumire,""))+" ("+rtrim(isnull(i.descriere,""))+")" from #pozitii s, terti t, infotert i
			where s.tip=''AP'' and i.subunitate=t.subunitate and t.tert=i.tert and identificator<>"" and
			t.subunitate=@cSub and rtrim(t.tert)+isnull("|"+rtrim(i.identificator),"")=nivel'+@grTert
end
	/*
	else  select @comSQL=@comSQL+'
		update s set numeNivel'+@grTert+'=rtrim(isnull(t.denumire,"")) from #pozitii s left join terti t on t.subunitate=@cSub and t.tert=nivel'+@grTert+'
			left join infotert i on s.tip=''AP'' and s.subunitate=i.subunitate and s.tert=i.tert and identificator<>'' and p.punct_livrare=i.identificator'
*/
/*+ '
	'+(case when @puncteLivrare=1 then 'left join infotert i on p.tip=''AP'' and p.subunitate=i.subunitate and p.tert=i.tert and identificator<>'' and p.punct_livrare=i.identificator' else '' end)*/
if @grCod  is not null select @comSQL=@comSQL+'
	update s set numeNivel'+@grCod+'=rtrim(isnull(n.denumire,""))+" ("+rtrim(n.um)+")" from #pozitii s inner join nomencl n on n.cod=nivel'+@grCod
if @grGestiune  is not null select @comSQL=@comSQL+'
	update s set numeNivel'+@grGestiune+'=rtrim(left(isnull(n.denumire_gestiune,""),30)) from #pozitii s inner join gestiuni n on n.cod_gestiune=nivel'+@grGestiune+' and s.tip not in ("PF","CI")
	update s set numeNivel'+@grGestiune+'=rtrim(left(isnull(p.nume,""),30)) from #pozitii s inner join personal p on p.marca=nivel'+@grGestiune+' and s.tip in ("PF","CI")'
if @grGestiunePrimitoare is not null select @comSQL=@comSQL+'
	update s set numeNivel'+@grGestiunePrimitoare+'=rtrim(left(isnull(n.denumire_gestiune,""),30)) from #pozitii s inner join gestiuni n on n.cod_gestiune=nivel'+@grGestiunePrimitoare
if @grLocm  is not null select @comSQL=@comSQL+'
	update s set numeNivel'+@grLocm+'=rtrim(isnull(n.denumire,"")) from #pozitii s inner join lm n on n.cod=nivel'+@grLocm
if @grGrupa  is not null select @comSQL=@comSQL+'
	update s set numeNivel'+@grGrupa+'=rtrim(isnull(n.denumire,"")) from #pozitii s inner join grupe n on rtrim(n.tip_de_nomenclator)+"|"+rtrim(n.grupa)=s.nivel'+@grGrupa
--if @grFactura  is not null select @comSQL=@comSQL+''
if @grComanda  is not null select @comSQL=@comSQL+'
	update s set numeNivel'+@grComanda+'=rtrim(isnull(n.descriere,"")) from #pozitii s inner join comenzi n on n.subunitate=@cSub and n.comanda=nivel'+@grComanda
if @grComandaBeneficiar  is not null select @comSQL=@comSQL+'
	update s set numeNivel'+@grComandaBeneficiar+'=rtrim(isnull(n.descriere,"")) from #pozitii s inner join comenzi n on n.subunitate=@cSub and n.comanda=nivel'+@grComandaBeneficiar
if @grFurnizorNomenclator  is not null select @comSQL=@comSQL+'
	update s set numeNivel'+@grFurnizorNomenclator+'=rtrim(isnull(t.denumire,""))
		from #pozitii s inner join terti t on t.subunitate=@cSub and t.tert=nivel'+@grFurnizorNomenclator
if @grFurnizorIntrare is not null select @comSQL=@comSQL+'
	update s set numeNivel'+@grFurnizorIntrare+'=rtrim(isnull(t.denumire,""))
		from #pozitii s inner join terti t on t.subunitate=@cSub and t.tert=nivel'+@grFurnizorIntrare
if @grTipuriDocumente is not null select @comSQL=@comSQL+'
	update s set numeNivel'+@grTipuriDocumente+'=nivel'+@grTipuriDocumente+'
		from #pozitii s'
if @grIndicatoriBugetari is not null select @comSQL=@comSQL+'
	update s set numeNivel'+@grIndicatoriBugetari+'=rtrim(isnull(i.denumire,"<fara indicator>"))
		from #pozitii s left join indbug i on i.indbug=nivel'+@grIndicatoriBugetari
if @grLot is not null select @comSQL=@comSQL+'
	update s set numeNivel'+@grLot+'=nivel'+@grLot+'
		from #pozitii s'
	
if @detalii<>2 select @comSQL=@comSQL+'
	update s set numeNivel6=s.tip+" "+rtrim(s.numar)+" "+convert(varchar(10),s.data,103) from #pozitii s'

--> stabilirea ordonarii datelor:
select @comSQL=@comSQL+'
	update s set	ordnivel1='+(case @ordonare when 3 then '""' when 2	then 'numeNivel1' else 'nivel1' end)+',
					ordnivel2='+(case @ordonare when 3 then '""' when 2	then 'numeNivel2' else 'nivel2' end)+',
					ordnivel3='+(case @ordonare when 3 then '""' when 2	then 'numeNivel3' else 'nivel3' end)+',
					ordnivel4='+(case @ordonare when 3 then '""' when 2	then 'numeNivel4' else 'nivel4' end)+',
					ordnivel5='+(case @ordonare when 3 then '""' when 2	then 'numeNivel5' else 'nivel5' end)+',
					ordnivel6='+(case @ordonare when 3 then '""' when 2	then 's.tip+"|"+s.numar+"|"+convert(varchar(20),s.data,102)'
														else 'convert(varchar(20),s.data,102)+"|"+s.tip+"|"+s.numar+"|"' end)+'
	from #pozitii s'
-->	ordonarea pe data si luna se face invariabil dupa "nivelX"; din acest motiv se seteaza "numeNivelX" dupa ordonare
if @grData  is not null select @comSQL=@comSQL+'
	update s set numeNivel'+@grData+'=rtrim(isnull(convert(varchar(20),s.data,103),"")) from #pozitii s'
if @grLuna  is not null select @comSQL=@comSQL+'
	select max(lunaalfa) lunaalfa, luna into #fluni from fcalendar("2010-1-1","2010-12-1") group by luna
	update s set numeNivel'+@grLuna+'=rtrim(isnull(f.lunaalfa,""))+" "+convert(varchar(20),year(s.data))
		,nivel'+@grLuna+'=convert(varchar(20),year(s.data))+" "+(case when month(s.data)<10 then " "+convert(varchar(1),month(s.data)) else convert(varchar(2),month(s.data)) end)
	from #pozitii s inner join #fluni f on f.luna=month(s.data)'

--> in mod normal, adaugarea de coloane suplimentare se executa doar in @comandaGrupare, formarea @comSQL ulterioara ar trebui sa ramana nealterata
--> nu trebuie modificate liniile care contin "[" sau "]" !!!
declare @comandaGrupare varchar(max), @deInlocuitLaTotal varchar(max), @randNivele varchar(max)
select @deInlocuitLaTotal='[n1] nivel, rtrim(max(numeNivel[n1])) numeNivel, "[n1]|"+max(ordNivel[n1]) as ordine,
		(case when max(tipNivel[n1]) not in ("DE","DA","DO","TI") then nivel[n1] else "" end) as codAfisat,',
		@randNivele=' rtrim(convert(varchar(200),nivel[n1])) cod, [parinte] as parinte, row_number() over (order by max(ordNivel[n1]), sum('+@valgr+') desc) as nr_crt,'
select @comandaGrupare=@randNivele+'
		sum(cantitate) as cantitate, SUM(valCost) as valCost, max(lm) lm, max(comanda) comanda, max(gestiune) as gestiune,
		sum(TVA) as TVA,
		max(tip) tip, max(numar) numar, max(data) data, max(um) um, max(pret_de_stoc) pret_de_stoc,
		max(pret_vanzare) pret_vanzare, max(pret_valuta) pret_valuta, max(discount) discount,
		'+(case @tipRaport	when 'Avize' then 'sum(pfTVA) as pfTVA, sum(pcuTVA) as pcuTVA, SUM(adaos) as adaos, sum(greutate) greutate,'
							when 'Intrari iesiri' then 'max(cont_stoc) as cont_stoc, max(cont_factura) as cont_factura, max(codintrare) as codintrare,'
						else 'sum(valoare_furn) as valoare_furn, sum(pcuTVA) pcuTVA,' end)+'
		'+@deInlocuitLaTotal+'
		max(explicatii) explicatii,"" nivel1, "" numeNivel1, 0 valgr, 0 topgr from #pozitii a'+@joinTop
--select 'test' return
select @comSQL=@comSQL
				+	'
				insert into #final(tipnivel, cod, parinte, nr_crt, cantitate, valCost, lm, comanda, gestiune, TVA, tip, numar, data, um, pret_de_stoc, pret_vanzare, pret_valuta, discount, 
				'+(case @tipRaport	when 'Avize' then 'pfTVA, pcuTVA, adaos, greutate,'
									when 'Intrari iesiri' then 'cont_stoc, cont_factura, codintrare,'
							else 'valoare_furn, pcuTVA,'
							end)
				+'nivel, numeNivel, ordine, codAfisat, explicatii, nivel1, numeNivel1, valgr, topgr)'+char(10)
				+	'
				select "" tipnivel,'+replace(		--> total
						replace(
							@comandaGrupare,@randNivele,
									'"Total" cod, "" as parinte, 0 as nr_crt,'
						),
						@deInlocuitLaTotal,
						'0 nivel, "Total" numeNivel, space(100) as ordine,"" codAfisat,')
--set @comandaGrupare=replace(@comandaGrupare,' into #final','')
select @comSQL=@comSQL
				+(case when @s_nivel1<>'null' then		--> mai dificila formarea select-ului pentru nivelul 1 pt ca se selecteaza si coloanele pentru grafic:
						' union all select max("|"+tipnivel1+"|"),'+replace(
						replace(replace(@comandaGrupare,'[parinte]','"Total|"'),'[n1]','1'),
						'"" nivel1, "" numeNivel1, 0 valgr, 0 topgr',
						'"|"+isnull(nivel1,"<fara cod>") nivel1, max(isnull(numeNivel1,"<fara cod>")) numeNivel1, sum('+@valgr+') valgr, row_number() over (order by sum('+@valgr+') desc) topgr'
						)
					+' group by nivel1' else '' end)
				+(case when @s_nivel2<>'null' then 
					' union all select max("|"+tipnivel1+"|"+tipnivel2+"|"),'+
						replace(replace(@comandaGrupare,'[n1]','2'),'[parinte]','nivel1+"|Total|"')+' group by nivel2,nivel1' else '' end)
				+(case when @s_nivel3<>'null' then 
					' union all select max("|"+tipnivel1+"|"+tipnivel2+"|"+tipnivel3+"|"),'+
						replace(replace(@comandaGrupare,'[n1]','3'),'[parinte]','nivel2+"|"+nivel1+"|Total|"')+' group by nivel3,nivel2,nivel1' else '' end)
				+(case when @s_nivel4<>'null' then 
					' union all select max("|"+tipnivel1+"|"+tipnivel2+"|"+tipnivel3+"|"+tipnivel4+"|"+tipnivel5+"|"),'+
						replace(replace(@comandaGrupare,'[n1]','4'),'[parinte]','nivel3+"|"+nivel2+"|"+nivel1+"|Total|"')+' group by nivel4,nivel3,nivel2,nivel1' else '' end)
				+(case when @s_nivel5<>'null' then 
					' union all select max("|"+tipnivel1+"|"+tipnivel2+"|"+tipnivel3+"|"+tipnivel4+"|"+tipnivel5+"|"+tipnivel6+"|"),'+
						replace(replace(@comandaGrupare,'[n1]','5'),'[parinte]','nivel4+"|"+nivel3+"|"+nivel2+"|"+nivel1+"|Total|"')+' group by nivel5,nivel4,nivel3,nivel2,nivel1' else '' end)+
				+(case when @detalii<>2 then 
					' union all select max("|"+tipnivel1+"|"+tipnivel2+"|"+tipnivel3+"|"+tipnivel4+"|"+tipnivel5+"|"+tipnivel6+"|"),'+
						replace(replace(@comandaGrupare,'[n1]','6'),'[parinte]',
--							'isnull(nullif(nivel5,"")+"|","")+isnull(nullif(nivel4,"")+"|","")+isnull(nullif(nivel3,"")+"|","")+isnull(nullif(nivel2,"")+"|","")+isnull(nullif(nivel1,""),"")+"|Total|"')+' group by nivel6,nivel5,nivel4,nivel3,nivel2,nivel1' else '' end)+
					'isnull(nivel5+"|","")+isnull(nivel4+"|","")+isnull(nivel3+"|","")+isnull(nivel2+"|","")+isnull(nivel1,"")+"|Total|"')+' group by nivel6,nivel5,nivel4,nivel3,nivel2,nivel1' else '' end)+
				'
				order by nivel, ordine, '+@valgr+' desc'
	--> daca se depaseste nr maxim de randuri configurate pt raport se genereaza "eroare de tip warning":
		--case when @nrmaximdetalii>0 then @verificareNrRanduri else '' end+

--exec(@comsql)

select @comsql=@comsql+'
				select * from #final'
select @comsql=@comsql+'
--select * from #pozitii a order by ordnivel1, ordnivel2, ordnivel3, ordnivel4, ordnivel5, ordnivel6
'
--*/--*/--*/
--test	select @comSQL comanda for xml path('')
--insert into trapDocumente	--*/

--/*
--exec (@comSQL)
--print @comSQL
select @comsql=replace(@comsql,'"','''')

exec sp_executesql @statement=@comSQL, 
		@params=N'@sesiune as varchar(max), @parXML xml, @csub varchar(20), @datajos datetime, @datasus datetime, @tip_doc_str varchar(500), @cod varchar(20), @codintrare varchar(20), 
				@comanda varchar(20), @contCor varchar(50), @ctstoc varchar(50), @contFactura varchar(50), @factura varchar(20), @furnizor_nomenclator varchar(50), @gestiune varchar(50), 
				@gestiuneprim varchar(50), @grupa varchar(50), @tipArticole varchar(1000), @grupaTerti varchar(20), @indicator varchar(20), @lm varchar(20), @locatia varchar(20), 
				@tert varchar(20), @tipTert varchar(1), @lot varchar(200), @nrdoc varchar(200)', 
		@sesiune=@sesiune, @parxml=@parxml, @csub=@csub, @datajos=@datajos, @datasus=@datasus, @tip_doc_str=@tip_doc_str, @cod=@cod, @codintrare=@codintrare, @comanda=@comanda,
		@contCor=@contCor, @ctstoc=@ctstoc, @contFactura=@contFactura, @factura=@factura, @furnizor_nomenclator=@furnizor_nomenclator, @gestiune=@gestiune, @gestiuneprim=@gestiuneprim,
		@grupa=@grupa, @tipArticole=@tipArticole, @grupaTerti=@grupaTerti, @indicator=@indicator, @lm=@lm, @locatia=@locatia, @tert=@tert, @tipTert=@tipTert, @lot=@lot, @nrdoc=@nrdoc

--test	select @comsql for xml path('')
--*/	raiserror('test',16,1)
end try
begin catch
	select @eroare='Eroare:'+char(10)+error_message()
--	select @eroare as numeNivel, '<Eroare>' as cod
	/*select '' tipnivel, '<Eroare>' cod, '' parinte, 0 nr_crt, 0 cantitate, 0 valCost, '' lm, '' comanda, '' gestiune, 0 TVA
		,'' tip, '' numar, '1901-1-1' data, '' um, 0 pret_de_stoc, 0 pret_vanzare, 0 pret_valuta, 0 discount, 0 pfTVA,
		0 pcuTVA, 0 adaos, 0 greutate, 0 nivel, @eroare numeNivel, '' ordine, '' codAfisat, '' explicatii, '' nivel1, '' numeNivel1, 0 valgr, 0 topgr*/
	insert into #final(cod, numenivel) select '<Eroare>', @eroare
	select * from #final
	select @comsql for xml path('')
end catch

if object_id('tempdb..#pozitii') is not null drop table #pozitii
if object_id('tempdb..#final') is not null drop table #final
if object_id('tempdb..#fluni') is not null drop table #fluni
if object_id('tempdb..#top') is not null drop table #top
if object_id('tempdb..#pcost') is not null drop table #pcost

if len(@eroare)>0 raiserror(@eroare,16,1)
