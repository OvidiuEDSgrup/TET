--***
CREATE procedure rapAvize(@sesiune varchar(50)=null,@datajos datetime,@datasus datetime, @tert varchar(50)=null, @cod varchar(50)=null,
					@gestiune varchar(50)=null, @lm varchar(50)=null, @factura varchar(50)=null, @comanda varchar(50)=null,
				@Nivel1 varchar(2)=null, @Nivel2 varchar(2)=null, @Nivel3 varchar(2)=null, @Nivel4 varchar(2)=null, @Nivel5 varchar(2)=null,
				/*	TE=Tert
					CO=Cod
					GE=Gestiune
					LU=Luna
					LO=Loc de munca
					DA=Data
					GR=Grupa nomenclator
					FA=Factura
					CM=Comanda
					FU=Furnizor nomenclator
					DO=Documente	--*/
				@ordonare int,	--> 1=cod/tip & numar & data , 2=denumire/data & tip & numar
				@grupaTerti varchar(20)=null,
				@grupa varchar(20)=null,	--> filtru pe grupa de nomenclator
				@puncteLivrare bit=0,	--> daca @puncteLivrare=1 gruparile pe terti vor fi de fapt grupari pe terti + puncte livrare
				@Furnizor varchar(20)=null, -->daca @Furnizor diferit de null se va rula fStocuri pentru filtrare
				@locatia varchar(30)=null,
				@furnizor_nomenclator varchar(30)=null,
				@detalii int=0,	--> 0=in detalii datele vin asa cum sunt in pozdoc, 1=doar gruparile superioare, 2=grupat pe document
				@sicoduri bit=1,	--> daca sa apara si coduri in denumiri
				@greutate bit=0,
				@top int=null		--> daca sa apara primele @top grupari superioare
				)
as
begin try
set transaction isolation level read uncommitted

declare @cSub varchar(20)
select @cSub=val_alfanumerica from par where Tip_parametru='GE' and Parametru='SUBPRO'

declare @grupaNomenclatorpeNivele bit
select @grupaNomenclatorpeNivele=isnull((select val_logica from par where tip_parametru='GE' and parametru='GRUPANIV'),0)
if @grupaNomenclatorpeNivele=1
	select @grupa=@grupa+'%'
	--> daca pentru grupele de nomenclator e activa setarea de grupe pe nivele se filtreaza cu 'like %'

declare @comSQL nvarchar(max),@tabeleJoin varchar(4000)
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
select @s_nivel6=(case @detalii when 1 then 'null'
					when 2 then 'p.tip+" "+rtrim(p.numar)+" "+convert(varchar(10),p.data,103)'
					when 0 then 'convert(varchar(20),p.idpozdoc)' end)

declare @utilizator varchar(20), @eLmUtiliz int, @eGestUtiliz int,
	@comandaProprietati varchar(max)

select @utilizator=dbo.fIaUtilizator(@sesiune), @eLmUtiliz=0, @eGestUtiliz=0, @comandaProprietati=''
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
select valoare, cod_proprietate from fPropUtiliz("'+isnull(@sesiune,'')+'") where valoare<>"" and cod_proprietate="GESTIUNE"
'
--> se stabileste campul fiecarei grupari:
select @setare_reguli_nivel='SET QUOTED_IDENTIFIER OFF
							set @s_nivel=(case @nivel when "TE" then "rtrim(p.tert)'+(case when @puncteLivrare<>1 then '"' else 
								--'+""|""+p.punct_livrare"'
								'+(case when p.tip=''AP'' and d.gestiune_primitoare<>"""" then isnull(""|""+d.gestiune_primitoare,"""") else """" end)"'
								end)+'
							when "CO" then "p.cod"
							when "GE" then "p.gestiune"
							when "LU" then "convert(varchar(20),l.an)+'' ''+convert(varchar(20),l.luna)"
							when "LO" then "p.loc_de_munca"
							when "DA" then "convert(varchar(20),p.data,102)"
							when "GR" then "n.tip+""|""+n.grupa"
							when "FA" then "p.factura"
							when "CM" then "p.comanda"
							when "FU" then "n.furnizor"
							when "DO" then ''p.tip+" "+rtrim(p.numar)+" "+convert(varchar(10),p.data,103)''
							else "null" end)
							set @s_nivel=(case when @s_nivel<>"null" then "rtrim("+@s_nivel+")" else @s_nivel end)'

exec sp_executesql @setare_reguli_nivel,N'@s_nivel nvarchar(200) output, @nivel nvarchar(200)', @nivel=@nivel1, @s_nivel=@s_nivel1 output
exec sp_executesql @setare_reguli_nivel,N'@s_nivel nvarchar(200) output, @nivel nvarchar(200)', @nivel=@nivel2, @s_nivel=@s_nivel2 output
exec sp_executesql @setare_reguli_nivel,N'@s_nivel nvarchar(200) output, @nivel nvarchar(200)', @nivel=@nivel3, @s_nivel=@s_nivel3 output
exec sp_executesql @setare_reguli_nivel,N'@s_nivel nvarchar(200) output, @nivel nvarchar(200)', @nivel=@nivel4, @s_nivel=@s_nivel4 output
exec sp_executesql @setare_reguli_nivel,N'@s_nivel nvarchar(200) output, @nivel nvarchar(200)', @nivel=@nivel5, @s_nivel=@s_nivel5 output
--/*
declare @identificare_grupari nvarchar(max),
		@grTert varchar(1),
		@grCod varchar(1),
		@grGestiune varchar(1),
		@grLuna varchar(1),
		@grLocm varchar(1),
		@grData varchar(1),
		@grGrupa varchar(1),
		@grFactura varchar(1),
		@grComanda varchar(1),
		@grFurnizor varchar(1)
	
--> se identifica datele necesare pentru grupari, fara a se cunoaste ordinea gruparilor (ca sa se stie de ce date e nevoie in continuare)
select @identificare_grupari='
select @tipgr=(case @cod when '''+isnull(@nivel1,'')+''' then ''1''
					when '''+isnull(@nivel2,'')+''' then ''2''
					when '''+isnull(@nivel3,'')+''' then ''3''
					when '''+isnull(@nivel4,'')+''' then ''4''
					when '''+isnull(@nivel5,'')+''' then ''5'' else null end)'
					
exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='TE', @tipgr=@grTert output
exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='CO', @tipgr=@grCod output
exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='GE', @tipgr=@grGestiune output
exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='LU', @tipgr=@grLuna output
exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='LO', @tipgr=@grLocm output
exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='DA', @tipgr=@grData output
exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='GR', @tipgr=@grGrupa output
exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='FA', @tipgr=@grFactura output
exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='CM', @tipgr=@grComanda output
exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='FU', @tipgr=@grFurnizor output
--exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='DO', @tipgr=@grFurnizor output

set @comSQL='SET QUOTED_IDENTIFIER OFF
	if object_id("tempdb..#top") is not null drop table #top
	if object_id("tempdb..#avize") is not null drop table #avize
	
	create table #avize (utilizator varchar(200), nivel1 varchar(200), nivel2 varchar(200), nivel3 varchar(200),
	nivel4 varchar(200), nivel5 varchar(200), nivel6 varchar(200), lunaalfa varchar(200), numeNivel1 varchar(2000), numeNivel2 varchar(2000),
	numeNivel3 varchar(2000), numeNivel4 varchar(2000), numeNivel5 varchar(2000), numeNivel6 varchar(2000), cantitate decimal(15,2),
	pfTVA decimal(15,4), pcuTVA decimal(15,2), valCost decimal(15,2), adaos decimal(15,2),
	tip varchar(20), numar varchar(20), data datetime, greutate decimal(15,2),
	ordNivel1 varchar(2000) default "", ordNivel2 varchar(2000) default "",	ordNivel3 varchar(2000) default "", ordNivel4 varchar(2000) default "", ordNivel5 varchar(2000) default "", ordNivel6 varchar(2000) default ""
	, tipNivel1 varchar(2000), tipNivel2 varchar(2000), tipNivel3 varchar(2000), tipNivel4 varchar(2000), tipNivel5 varchar(2000), tipNivel6 varchar(2000))
	'+@comandaProprietati

set @tabeleJoin=(case when @grLuna is not null then 'left join #fLuni l on p.data=l.data' else '' end )+'
	'+(case when @grGrupa is not null or @grFurnizor is not null or @grupa is not null or @furnizor_nomenclator is not null or @greutate=1 then 'left join nomencl n on p.cod=n.cod' else '' end )+ '
	'+(case when @grupaTerti is not null then 'left join terti t on t.subunitate="'+@csub+'" and t.tert=p.tert' else '' end )+ '
	'+(case when @puncteLivrare=1 then 'inner join doc d on p.subunitate=d.subunitate and p.tip=d.tip and p.data=d.data and p.numar=d.numar' else '' end)

if @grluna is not null
	set @comSQL=@comSQL+'
	select data, rtrim(lunaalfa) lunaalfa, (case when luna<10 then " " else "" end)+convert(varchar(20),luna) as luna, an
	into #fLuni
	from dbo.fCalendar("'+convert(char(10),@datajos,101)+'","'+(convert(char(10),@datasus,101))+'")'

set @comSQL=@comSQL+'
insert into #avize (utilizator, nivel1, nivel2, nivel3, nivel4, nivel5, nivel6, lunaalfa, numeNivel1, numeNivel2, numeNivel3, numeNivel4, numeNivel5, numeNivel6,
		cantitate, pfTVA, pcuTVA, valCost, adaos, tip, numar, data, greutate, tipNivel1, tipNivel2, tipNivel3, tipNivel4, tipNivel5, tipNivel6)
select 	"'+@utilizator+'" as utilizator, 
		'+@s_nivel1+' as nivel1,'+@s_nivel2+' as nivel2,'+@s_nivel3+' as nivel3,'+@s_nivel4+' as nivel4,'+@s_nivel5+' as nivel5,'+@s_nivel6+' as nivel6,'
		+(case when @grLuna is not null then 'max(l.lunaalfa)+" "+convert(varchar(20),max(l.an))' else 'null' end )+' lunaalfa,'
		+@s_nivel1+' as numeNivel1,'+@s_nivel2+' as numeNivel2,'+@s_nivel3+' as numeNivel3,'+@s_nivel4+' as numeNivel4,'+@s_nivel5+' as numeNivel5,'+@s_nivel6+' as numeNivel6,
		sum(p.cantitate) as cantitate,
		sum(p.cantitate*p.pret_vanzare) as pfTVA,
		sum(p.cantitate*p.pret_vanzare+p.tva_deductibil) as pcuTVA,
		sum(p.cantitate*p.pret_de_stoc) as valCost, 
		sum(p.cantitate*(p.pret_vanzare-p.pret_de_stoc)) as adaos,
		max(p.tip) tip, max(p.numar) numar, max(p.data) data,
		'+(case when @greutate=1 then 'sum(n.greutate_specifica*p.cantitate)' else '0' end)+' greutate,
		"'+isnull(@Nivel1,'')+'", "'+isnull(@Nivel2,'')+'", "'+isnull(@Nivel3,'')+'", "'+isnull(@Nivel4,'')+'", "'+isnull(@Nivel5,'')+'", "'+(case when @detalii=2 then 'DE' else '' end)+'"
	from pozdoc p
	'+@tabeleJoin+'
	 where p.Subunitate="'+@cSub+'"and (p.data between "'+convert(char(10),@datajos,101)+'" and "'+(convert(char(10),@datasus,101))+'")
		and p.tip in ("AP","AC","AS")'+
		(case when nullif(@tert,'') is null then '' else ' and (p.tert="'+@tert+'")' end)
		+(case when nullif(@cod,'') is null then '' else ' and (p.cod="'+@cod+'")' end)
		+(case when nullif(@gestiune,'') is null then '' else ' and (p.gestiune="'+@gestiune+'")' end)
		+(case when nullif(@lm,'') is null then '' else ' and (p.loc_de_munca="'+@lm+'")' end)
		+(case when nullif(@factura,'') is null then '' else ' and (p.factura="'+@factura+'")' end)
		+(case when nullif(@comanda,'') is null then '' else ' and (p.comanda="'+@comanda+'")' end)
		+(case when nullif(@locatia,'') is null then '' else ' and (p.locatie="'+@locatia+'")' end)
		+(case when @eLmUtiliz=0 then '' else ' and exists (select 1 from @LmUtiliz u where u.valoare=p.Loc_de_munca)' end)
		+(case when @eGestUtiliz=0 then '' else ' and (p.tip="AS" or exists (select 1 from @GestUtiliz u where u.valoare=p.Gestiune))' end)
		+(case when @grupaTerti is null then '' else ' and t.Grupa="'+@grupaTerti+'"' end)
		+(case when @grupa is null then ''
				when @grupaNomenclatorpeNivele=1 then ' and n.Grupa like "'+@grupa+'"'
				else ' and n.Grupa="'+@grupa+'"' end)
		+(case when @furnizor_nomenclator is null then '' else ' and n.furnizor="'+@furnizor_nomenclator+'"' end)
		/*		and	(@grupaTerti is null or t.Grupa=@grupaTerti)
		and (@grupa is null or n.grupa like @grupa)
		and (@furnizor_nomenclator is null or n.furnizor=@furnizor_nomenclator)'*/
	+' GROUP BY p.subunitate'+(case when @s_nivel1='null' then '' else ','+@s_nivel1 end)--+@s_nivel2+','+@s_nivel3+','+@s_nivel4+','+@s_nivel5+
				+(case when @s_nivel2='null' then '' else ','+@s_nivel2 end)
				+(case when @s_nivel3='null' then '' else ','+@s_nivel3 end)
				+(case when @s_nivel4='null' then '' else ','+@s_nivel4 end)
				+(case when @s_nivel5='null' then '' else ','+@s_nivel5 end)
				+(case when @detalii=1 then '' else ','+@s_nivel6 end)
	+' ORDER BY 9 desc'

--> culegere denumiri:
if @grTert is not null 
begin
	select @comSQL=@comSQL+'
		update s set numeNivel'+@grTert+'=rtrim(isnull(t.denumire,"")) from #avize s left join terti t on t.subunitate="'+@cSub+'" and t.tert=nivel'+@grTert
	if @puncteLivrare=1 select @comSQL=@comSQL+'
		update s set numeNivel'+@grTert+'=rtrim(isnull(t.denumire,""))+" ("+rtrim(isnull(i.descriere,""))+")" from #avize s, terti t, infotert i
			where s.tip=''AP'' and i.subunitate=t.subunitate and t.tert=i.tert and identificator<>"" and
			t.subunitate="'+@cSub+'" and rtrim(t.tert)+isnull("|"+rtrim(i.identificator),"")=nivel'+@grTert
end
	/*
	else  select @comSQL=@comSQL+'
		update s set numeNivel'+@grTert+'=rtrim(isnull(t.denumire,"")) from #avize s left join terti t on t.subunitate="'+@cSub+'" and t.tert=nivel'+@grTert+'
			left join infotert i on s.tip=''AP'' and s.subunitate=i.subunitate and s.tert=i.tert and identificator<>'' and p.punct_livrare=i.identificator'
*/
/*+ '
	'+(case when @puncteLivrare=1 then 'left join infotert i on p.tip=''AP'' and p.subunitate=i.subunitate and p.tert=i.tert and identificator<>'' and p.punct_livrare=i.identificator' else '' end)*/
if @grCod  is not null select @comSQL=@comSQL+'
	update s set numeNivel'+@grCod+'=rtrim(isnull(n.denumire,"")) from #avize s left join nomencl n on n.cod=nivel'+@grCod
if @grGestiune  is not null select @comSQL=@comSQL+'
	update s set numeNivel'+@grGestiune+'=rtrim(isnull(n.denumire_gestiune,"")) from #avize s left join gestiuni n on n.cod_gestiune=nivel'+@grGestiune
if @grLocm  is not null select @comSQL=@comSQL+'
	update s set numeNivel'+@grLocm+'=rtrim(isnull(n.denumire,"")) from #avize s left join lm n on n.cod=nivel'+@grLocm
if @grGrupa  is not null select @comSQL=@comSQL+'
	update s set numeNivel'+@grGrupa+'=rtrim(isnull(n.denumire,"")) from #avize s left join grupe n on rtrim(n.tip_de_nomenclator)+"|"+rtrim(n.grupa)=s.nivel'+@grGrupa
--if @grFactura  is not null select @comSQL=@comSQL+''
if @grComanda  is not null select @comSQL=@comSQL+'
	update s set numeNivel'+@grComanda+'=rtrim(isnull(n.descriere,"")) from #avize s left join comenzi n on n.subunitate="'+@cSub+'" and n.comanda=nivel'+@grComanda
if @grFurnizor  is not null select @comSQL=@comSQL+'
	update s set numeNivel'+@grFurnizor+'=rtrim(isnull(t.denumire,"")) from #avize s left join terti t on t.subunitate="'+@cSub+'" and t.tert=nivel'+@grFurnizor
	
if @detalii<>1 select @comSQL=@comSQL+'
	update s set numeNivel6=s.tip+" "+rtrim(s.numar)+" "+convert(varchar(10),s.data,103) from #avize s'

--> stabilirea ordonarii datelor:
select @comSQL=@comSQL+'
	update s set	ordnivel1='+(case when @ordonare=2	then 'numeNivel1' else 'nivel1' end)+',
					ordnivel2='+(case when @ordonare=2	then 'numeNivel2' else 'nivel2' end)+',
					ordnivel3='+(case when @ordonare=2	then 'numeNivel3' else 'nivel3' end)+',
					ordnivel4='+(case when @ordonare=2	then 'numeNivel4' else 'nivel4' end)+',
					ordnivel5='+(case when @ordonare=2	then 'numeNivel5' else 'nivel5' end)+',
					ordnivel6='+(case when @ordonare=2	then 's.tip+"|"+s.numar+"|"+convert(varchar(20),s.data,102)'
														else 'convert(varchar(20),s.data,102)+"|"+s.tip+"|"+s.numar+"|"' end)+'
	from #avize s'
-->	ordonarea pe data si luna se face invariabil dupa "nivelX"; din acest motiv se seteaza "numeNivelX" dupa ordonare
if @grData  is not null select @comSQL=@comSQL+'
	update s set numeNivel'+@grData+'=rtrim(isnull(convert(varchar(20),s.data,103),"")) from #avize s'
if @grLuna  is not null select @comSQL=@comSQL+'
	update s set numeNivel'+@grLuna+'=rtrim(isnull(s.lunaalfa,"")) from #avize s'

--> selectarea datelor in cazul in care se cer doar primele @top grupari superioare
declare @joinTop varchar(max)
select @joinTop=''
if @top is not null
begin
	select @comSQL=@comSQL+'
		select row_number() over (order by sum(a.pcuTVA) '+(case when @top<0 then 'asc' else 'desc' end)+') as cate, a.nivel1 as nivelTop into #top from #avize a group by a.nivel1
		delete #top where cate>'+convert(varchar(20),abs(@top))
	select @joinTop=' inner join #top t on a.nivel1=t.nivelTop'
end

--> in mod normal, adaugarea de coloane suplimentare se executa doar in @comandaGrupare, formarea @comSQL ulterioara ar trebui sa ramana nealterata
--> nu trebuie modificate liniile care contin "[" sau "]" !!!
declare @comandaGrupare varchar(max), @deInlocuitLaTotal varchar(max)
select @deInlocuitLaTotal='[n1] nivel, max(numeNivel[n1]) numeNivel, "[n1]|"+max(ordNivel[n1]) as ordine,
		(case when max(tipNivel[n1]) not in ("DE","LU","DA","DO") then nivel[n1] else "" end) as codAfisat,'
select @comandaGrupare='
		select --@Nivel1 as tip_nivel, 
		nivel[n1] cod, [parinte] as parinte,
		sum(cantitate) as cantitate, sum(pfTVA) as pfTVA, 
		sum(pcuTVA) as pcuTVA, SUM(valCost) as valCost, SUM(adaos) as adaos, sum(greutate) greutate,
		'+@deInlocuitLaTotal+'
		"" nivel1, "" numeNivel1, 0 pcuTVAgr, 0 topgr from #avize a'+@joinTop

select @comSQL=@comSQL
				+	replace(		--> total
						replace(
							@comandaGrupare,'nivel[n1] cod, [parinte]','"Total" cod, ""'
						),
						@deInlocuitLaTotal,
						'0 nivel, "Total" numeNivel, space(100) as ordine,"" codAfisat,')
				+(case when @s_nivel1<>'null' then		--> mai dificila formarea select-ului pentru nivelul 1 pt ca se selecteaza si coloanele pentru grafic:
						' union '+replace(
						replace(replace(@comandaGrupare,'[parinte]','"Total|"'),'[n1]','1'),
						'"" nivel1, "" numeNivel1, 0 pcuTVAgr, 0 topgr',
						'nivel1 nivel1, max(numeNivel1) numeNivel1, sum(pcuTVA) pcuTVAgr, row_number() over (order by sum(pcuTVA) desc) topgr'
						)
					+' group by nivel1' else '' end)
				+(case when @s_nivel2<>'null' then ' union '+replace(replace(@comandaGrupare,'[n1]','2'),'[parinte]','nivel1+"|Total|"')+' group by nivel2,nivel1' else '' end)
				+(case when @s_nivel3<>'null' then ' union '+replace(replace(@comandaGrupare,'[n1]','3'),'[parinte]','nivel2+"|"+nivel1+"|Total|"')+' group by nivel3,nivel2,nivel1' else '' end)
				+(case when @s_nivel4<>'null' then ' union '+replace(replace(@comandaGrupare,'[n1]','4'),'[parinte]','nivel3+"|"+nivel2+"|"+nivel1+"|Total|"')+' group by nivel4,nivel3,nivel2,nivel1' else '' end)
				+(case when @s_nivel5<>'null' then ' union '+replace(replace(@comandaGrupare,'[n1]','5'),'[parinte]','nivel4+"|"+nivel3+"|"+nivel2+"|"+nivel1+"|Total|"')+' group by nivel5,nivel4,nivel3,nivel2,nivel1' else '' end)+
				+(case when @detalii<>1 then ' union '+replace(replace(@comandaGrupare,'[n1]','6'),'[parinte]','isnull(nivel5+"|","")+isnull(nivel4+"|","")+isnull(nivel3+"|","")+isnull(nivel2+"|","")+isnull(nivel1,"")+"|Total|"')+' group by nivel6,nivel5,nivel4,nivel3,nivel2,nivel1' else '' end)+
				'
				order by ordine'

select @comsql=@comsql+'
--select * from #avize a order by ordnivel1, ordnivel2, ordnivel3, ordnivel4, ordnivel5, ordnivel6
if object_id("tempdb..#avize") is not null drop table #avize
if object_id("tempdb..#top") is not null drop table #top'

--test	select @comSQL comanda for xml path('')
--insert into tRapAvize	--*/
exec (@comSQL)
end try
begin catch
	select 'Eroare:'+error_message() as numeNivel, 'Eroare' as cod
	select @setare_reguli_nivel, @comsql for xml path('')
end catch
