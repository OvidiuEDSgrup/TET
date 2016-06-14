--***
if exists (select * from sysobjects where name ='wDescarcBonSP')
drop procedure wDescarcBonSP
go
--***
create procedure wDescarcBonSP @sesiune varchar(50), @parXML xml
as
/*sp
if exists (select 1 from sysobjects where type='P' and name='wDescarcBonSP')
begin
		-- Atentie! Va recomandam sa evitati scrierea unei proceduri specifice pentru descarcare. 
		-- Daca totusi alegeti sa folositi, marcati folosind tag-uri de tip /*specific*/ si /*end specific*/ 
		-- partea modificata, pentru a putea integra usor codul specific si in 
		-- versiunile mai noi ale procedurii
		exec wDescarcBonSP @sesiune, @parXML
		return
end--sp*/
set transaction isolation level read committed

set nocount on
declare @UID varchar(50), @GestBon varchar(13),@factura varchar(20), @idAntetBon int,
	@Casa int,@Data datetime,@NrBon int,@Vanz varchar(10), @tert varchar(13), @dataScad datetime, @CategP varchar(5), @PctLiv varchar(20),
	@dataStart datetime, @msgEroare varchar(max), @eroareTimeout bit


begin try

/* citesc variabile din parXML */
select	@UID = @parXML.value('(/row/@UID)[1]', 'varchar(50)'),
		@idAntetBon = isnull(@parXML.value('(/row/@idAntetBon)[1]', 'int'),0),
		@dataStart=GETDATE(),
		@eroareTimeout=0

-- in caz exceptional se poate ca idAntetbon sa nu fie salvat in XML. il identific dupa UID.
if @idAntetBon=0
	select @idAntetBon=IdAntetBon from antetBonuri where UID=@UID

if @idAntetBon=0 and @UID is not null
begin
	set @msgEroare='Documentul cautat nu poate fi gasit! '+char(13)+
		'ID bon='+ISNULL(convert(varchar(30),@idAntetBon),'(null)')+char(13)+
		'UID bon='+isnull(@UID,'(null)')
	raiserror(@msgeroare,11,1)
end

declare @nFetchStatus int,@subunitate varchar(9),@Serii int, 
	@listaGestiuni varchar(202),@NuTEAC int,@NuStocTE int,@CodITE int,
	@OrdGest int,@TipG varchar(1), @Incas int, @NrLin int, @valoareDesc float, @valoareLinie float,
	@TipDoc char(2),@Cod varchar(20),@AreSerii int,@serieSauNrDocIncasare varchar(20),@Coef float,@Cant float,
	@CotaTVA float,@SumaTVA float,@pretFaraDiscount float,@Disc float,@Barcod varchar(20),@TipNom char(1),
	@LM varchar(20),@comanda_asis varchar(20),
	@contract varchar(20),@Jurn varchar(3),@AP418 int,@CtFact varchar(13),
	@ExcGest varchar(30),@ExcCont varchar(13), 
	@GestSt varchar(9),@CodISt varchar(20),@Stoc float, @ContOrd varchar(13),@SerieSt varchar(20),
	@CantRam float,@cantDeScris float,@NrDoc varchar(8),@NrTE varchar(8),@NrRM varchar(8),@CodIPrim varchar(13),
	@PValuta float,@PVanz float,@PretAm float,@TvaDeScris float, @pretVanzareDeScris float,
	@TVADesc float,@CantExc8 float,@CtStoc varchar(13),@PStoc float,@TertRM varchar(13),
	@codIntrareInDenumire int, @bTip int, @facturiDefinitive bit, @tipTVA int, @xml xml, @xmlDoc xml, 
	@gestPozitie varchar(30), @listaGestiuniPozitie varchar(300), @tertNeplatitorTva bit, @idPozdoc int,
	@rezervareStocComenzi bit, @gestRezervariComenzi varchar(/*sp 13 sp*/200), @DetaliereBonuri bit, @tmpbon cursor, @CuTranzactii int, @total float
declare @devize table (cod_deviz varchar(20), pozitie int primary key(cod_deviz,pozitie))

/* citesc date de antet document.
IMPORTANT: citirea sa ramana inainte de citirea din par pt ca sa fie citit @gestpv */
select	@TipDoc=isnull(a.bon.value('(/date/document/@tipdoc)[1]','varchar(2)'), (CASE WHEN a.chitanta=1 THEN 'AC' ELSE 'AP' END)),
		@NrDoc=a.bon.value('(/date/document/@numar_in_pozdoc)[1]','varchar(20)'), -- campul este in XML doar daca descarcarea se apeleaza din refaceri
		@GestBon=rtrim(gestiune), @vanz=Vinzator, @Casa=a.Casa_de_marcat, @Data=a.Data_bon, @NrBon=a.Numar_bon,
		@factura=isnull(rtrim(a.factura), convert(VARCHAR(30), a.numar_bon)/*a.numar_bon doar la facturi vechi din PVria v1*/),
		@vanz=a.Vinzator, @tert=a.Tert, @dataScad=a.Data_scadentei, @CategP=isnull(rtrim(a.categorie_de_pret), 0),
		@PctLiv=isnull(rtrim(a.punct_de_livrare), ''),
		/*aceste 2 campuri nu sunt tratate momentan*/@Jurn='', @AP418=0,
		@xmlDoc=a.Bon
	from antetBonuri a where idAntetBon=@idAntetBon

-- citire din par; lasati dupa citirea antetului.
select	@subunitate=(case when Parametru='SUBPRO' then rtrim(Val_alfanumerica) else isnull(@subunitate,'') end),
		@Serii=(case when Parametru='SERII' then Val_logica else isnull(@Serii,0) end),
		@CuTranzactii=(case when Parametru='TRANZACT' then Val_logica else isnull(@CuTranzactii,0) end),
		@facturiDefinitive=(case when Parametru='FACTDEF' then Val_logica else isnull(@facturiDefinitive,0) end),
		@rezervareStocComenzi=(case when Parametru='REZSTOCBK' then Val_logica else isnull(@rezervareStocComenzi,0) end),
		@gestRezervariComenzi=(case when Parametru='REZSTOCBK' then rtrim(Val_alfanumerica) else isnull(@gestRezervariComenzi,'') end),
		@listaGestiuni=(case when Parametru=@GestBon then rtrim(Val_alfanumerica) else isnull(@listaGestiuni,'') end),
		@DetaliereBonuri=(case when Parametru='DETBON' then Val_logica else isnull(@DetaliereBonuri, 0) end),
		@NuTEAC=(case when Parametru='NUTEAC' then Val_logica else isnull(@NuTEAC, 0) end),
		@NuStocTE=(case when Parametru='NUSTOCTE' then Val_logica else isnull(@NuStocTE, 0) end),
		@CodITE=(case when Parametru='CODINOUTE' then Val_logica else isnull(@CodITE, 0) end),
		@OrdGest=(case when Parametru='ORDGEST' then Val_logica else isnull(@OrdGest, 0) end),
		@codIntrareInDenumire=(case when Parametru='CODIINDEN' then Val_logica else isnull(@codIntrareInDenumire, 0) end)		
from par
where Tip_parametru='GE' and Parametru in ('SUBPRO', 'SERII', 'FACTDEF', 'REZSTOCBK', 'TRANZACT')
	or Tip_parametru='PG' and Parametru = @GestBon 
	or Tip_parametru='PO' and Parametru in ('DETBON', 'NUTEAC', 'NUSTOCTE', 'CODINOUTE', 'ORDGEST') 
	or Tip_parametru='PV' and Parametru = 'CODIINDEN'

if charindex(';'+RTrim(@GestBon)+';',';'+RTrim(@listaGestiuni)+';')=0 and (@TipDoc<>'AC' or @NuStocTE=0)
	-- am tinut cont de setarea de ignorare stoc de la magazin pentru AC - sa nu mai puna si gestiunea A in lista:
	set @listaGestiuni=RTrim(@GestBon)+';'+RTrim(@listaGestiuni)

if @dataScad is null 
	set @dataScad=isnull(dateadd(d, (select min(it.discount) from infotert it where it.subunitate=@subunitate and it.tert=@tert and it.identificator=''), 0), @Data)
set @tertNeplatitorTva = case when (select isnull(it.grupa13, 'null') from infotert it where it.subunitate=@subunitate and it.tert=@tert and it.identificator='') NOT IN ('1','null') then 1 else 0 end

if @CuTranzactii=1
	begin transaction descarcaBon

IF ISNULL(@NrDoc,'')='' -- @NrDoc este completat daca descarcarea se face din refaceri, si este deja @numar_in_pozdoc in XML
begin	
	set @NrDoc=left((case when @TipDoc in ('AP','TE') then LTrim(@factura) 
					when @TipDoc='AC' and @DetaliereBonuri=1 then RTrim(CONVERT(varchar(4),@casa))+right(replace(str(@NrBon),' ','0'),4) 
					else 'B'+LTrim(str(day(@Data)))+'G'+rtrim(@GestBon) end),8)
		
	-- salvez numarul de document din pozdoc - se va folosi daca trebuie anulat documentul.
	if (@xmlDoc.value('(/date/document/@numar_in_pozdoc)[1]','varchar(50)')) is null
		update antetBonuri set Bon.modify ('insert attribute numar_in_pozdoc {sql:variable("@NrDoc")} into (/date/document)[1]')
			where idAntetBon=@idAntetBon
	else
		update antetBonuri set Bon.modify('replace value of (/date/document/@numar_in_pozdoc)[1] with sql:variable("@NrDoc")')
			where idAntetBon=@idAntetBon
end

/* 
din PVria v2.3.005 descarc doar cate un bon - uneori se dublau cantitatile descarcate 
din cauza apelarii in paralel a wDescarcBon;
PV da timeout in 30secunde si reincearca, dar procedura nu se opreste la timeout, ci ruleaza in continuare... 
Filtrez doar dupa idAntetBon
*/
set @tmpbon = cursor local fast_forward for
select 
	(case when b.tip in ('11','21') and b.cod_produs<>'' then 0 else 1 end) as incasare ,
	b.numar_linie,
	rtrim(b.cod_produs),
	(CASE WHEN @Serii = 1 AND left(isnull(n.UM_2, ''), 1) = 'Y' THEN 1 ELSE 0 END) AS areSerii,
	rtrim(b.numar_document_incasare) AS serie,
	(CASE b.um WHEN 2 THEN isnull(n.coeficient_conversie_1, 0) WHEN 3 THEN isnull(n.coeficient_conversie_2, 0) ELSE 1 END) AS coef_conv,
	b.total,
	b.cantitate,
	b.cota_tva,
	b.tva,
	b.pret,
	b.discount,
	b.codplu,
	isnull(n.tip, '') tipnomencl,
	rtrim(isnull(b.lm_real, isnull(a.Loc_de_munca, isnull(gestcor.loc_de_munca, '')))) lm,
	rtrim(isnull(b.Comanda_asis, isnull(a.comanda, ''))) comanda_asis,
	rtrim(isnull(b.[contract], isnull(a.contract, ''))) [contract],
	b.tip,
	-- tipul de TVA conteaza doar la tertii platitori de TVA, si depinde de marcajul din Nomenclator
/*sp */(CASE WHEN @tertNeplatitorTva=0 or isnumeric(left(n.tip_echipament, 1))<>1 THEN 0 else convert(int, left(n.tip_echipament, 1)) END) AS tipTVA,/* sp*/
	rtrim(b.Gestiune) as gestiune_pozitie
from bt b
inner join antetBonuri a on a.idAntetBon=b.idAntetBon
left outer join gestcor on gestcor.gestiune=b.Gestiune
left outer join nomencl n on n.cod=b.cod_produs
where a.idAntetBon=@idAntetBon

--/*sp
declare @procid int=@@procid, @objname sysname
set @objname=object_name(@procid)
EXEC wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql=@objname
--sp*/

open @tmpbon
fetch next from @tmpbon into @Incas, @NrLin, @Cod, @AreSerii, @serieSauNrDocIncasare, @Coef, @total, @Cant, @CotaTVA, @SumaTVA, @pretFaraDiscount, @Disc, @Barcod, @TipNom, @LM, @comanda_asis, @contract, @bTip, @tipTVA, @gestPozitie
set @nFetchStatus=@@fetch_status

while @nFetchStatus=0
begin
	if DATEDIFF(second, @dataStart, getdate()) >= 30 and APP_NAME() not like '%Microsoft SQL Server%' 
	begin -- la peste 25 de secunde dau raiserror(pt ca sa nu ramana 'jumatati' de pozitii in pozdoc)
		set @eroareTimeout=1 
		-- textul acesta este hard-codat in PVria. Nu-l modificati.
		raiserror('Timpul alocat pentru descarcarea stocului din gestiune a fost depasit!',11,1)
	end
	
	set @Cant=round(convert(decimal(15,5),@Cant*@Coef),3)
	set @pretFaraDiscount=(case when @Coef=0 then 0 else round(convert(decimal(15,5),@pretFaraDiscount/@Coef),5) end)
	set @CantExc8=0
	if @Incas=0
	begin
		set @CantRam=@Cant
		set @CtFact=(case when @TipDoc='AP' and @AP418=1 then '418' else '' end)
		
		set @PValuta=round(convert(decimal(15,5),@pretFaraDiscount/(1+@CotaTVA/100)),5)
		set @PVanz=round((@total-@SumaTVA)/@Cant,5)
		set @PretAm=round(@total/@Cant,5)
		set @valoareLinie=round(@total-@SumaTVA,5)
		set @TVADesc=0 
		set @valoareDesc=0
		
		-- citesc tipul gestiunii pentru fiecare pozitie.
		select @TipG=tip_gestiune from gestiuni where subunitate=@subunitate and cod_gestiune=@gestPozitie
		
		/* 
			Lista gestiuni pozitie se formeaza din lista generala de gestiuni, luand in considerare gestiunea 
			de pe pozitia curenta.
			Gestiunea din pozitii poate fi diferita fata de cea din antet, si se intampla in general cand se vand
			produse de pe comenzi de livrare sau devize auto.
			Se descarca prioritar din gestiunea din pozitii. Daca nu este stoc in acea gestiune,
			se cauta si in gestiunile atasate utilizatorului. (de modificat daca se vrea fortarea gestiunii...).
		*/
		set @listaGestiuniPozitie = (case	when @gestPozitie=@GestBon and @listaGestiuni<>'' then @listaGestiuni 
											when @gestPozitie=@GestBon and @listaGestiuni='' then @gestPozitie 
											else @gestPozitie+';'+@listaGestiuni end);
		
		/* daca se vinde de pe o comanda de livrare si se lucreaza cu rezervari de stoc, adaug si gestiunea de rezervari la lista de gestiuni. */
		if @rezervareStocComenzi=1 and isnull(@contract,'')<>''
		begin
			set @listaGestiuniPozitie = @gestRezervariComenzi+';'+@listaGestiuniPozitie
		end
		
		/* 
			verific daca s-a finalizat un deviz.
			in cazul devizelor, se factureaza obligatoriu din gestiunea devizului.
			Anulat in rev 11394.
		*/
		if 1=0 and isnull((select pozitie.bon.query('data(@coddeviz)').value('.', 'varchar(80)')
				from @xmlDoc.nodes('/date/document/pozitii/row[@nrlinie=sql:variable("@NrLin")]') pozitie(bon) ),'')<>''
		begin
			set @listaGestiuniPozitie=@gestPozitie+';'
		end
						
		--select @listaGestiuniPozitie '@listaGestiuniPozitie', @gestPozitie '@gestPozitie', @GestBon '@GestBon'
		
		while abs(@CantRam)>=0.001
		begin
			set @GestSt=null
			set @CodISt=null
			set @Stoc=null
			
			if (@CantRam<=-0.001) and @TipNom<>'S'
			begin
				----------------------------------------- pozitie storno -----------------------------------------
				/*
					pentru pozitii storno la AC se scrie un TE si un AC cu minus;
					pentru pozitii storno la AP se scrie un AP cu minus;
					
					pentru AC-uri caut cod intrare din gestiunea de vanzare;
					pentru AP-uri caut in gestiunile asociate gestiunii de vanzare, si doar dupa aceea in GestBon;
					luarea pozitiei e tratata si in wValidareDocumentPV.
				*/
				declare @listaGestiuniStorno varchar(300), @generareCodIntrare bit
				set @listaGestiuniStorno = (case when @TipDoc='AC' then ';'+rtrim(@GestBon)+';'
													else /*@TipDoc='AP'*/
										';'+replace(@listaGestiuniPozitie, @GestBon+';', '')+';'+rtrim(@GestBon)+';' end)
				
				
				-- citesc fara sa tin cont de lock-uri - oricum citesc date vechi
				set transaction isolation level read uncommitted
				
				/*
					* caut un cod intrare in lista de gestiuni storno stabilita mai sus.
					* daca se gaseste un cod intrare valid(cu acelasi pret cu amanuntul), se storneaza pe 
						acelasi cod de intrare; altfel, se genereaza un cod intrare nou.
				*/
				select top 1 @GestSt=s.Cod_gestiune, 
					@CodISt=s.cod_intrare, 
					@generareCodIntrare=(case when s.Tip_gestiune<>'A' or abs(s.Pret_cu_amanuntul-@PretAm)<0.0009 then 0 else 1 end), 
					@PStoc = s.Pret, @Stoc=@CantRam, @CtStoc= rtrim(cont), @SerieSt=''
				from stocuri s
				where subunitate=@subunitate and cod=@Cod --and tip_gestiune=@TipG /* anulat pt. ca in lista gestiuni pot fi mai multe tipuri */
				and charindex(';'+RTrim(s.cod_gestiune)+';',@listaGestiuniStorno)>0 
				/* nu fac filtru pe comenzi/contract, ci order by, pt. ca sa gasesc ceva cod de intrare */
				order by 
				/* filtrare prioritara dupa stoc pe comanda sau contractul vandut - chiar daca e rar cazul */
				(case when @comanda_asis='' then '0' else s.Comanda end) desc, 
				(case when @contract='' then '0' else s.Contract end) desc, 
				/* la bonuri, aleg prioritar codul de intrare cu acelasi pret cu amanuntul; la AP se ignora; */
				(case when s.Tip_gestiune<>'A' or abs(s.Pret_cu_amanuntul-@PretAm)<0.0009 then 1 else 2 end), 
				/* gestiunea se alege in ordinea stabilita in @listaGestiuniStorno */
				charindex(';'+RTrim(s.cod_gestiune)+';',@listaGestiuniStorno), 
				s.Data desc
				
				select 'stocuri pe cod si gest '+@listaGestiuniStorno, *
				from stocuri s
				where subunitate=@subunitate and cod=@Cod --and tip_gestiune=@TipG /* anulat pt. ca in lista gestiuni pot fi mai multe tipuri */
				and charindex(';'+RTrim(s.cod_gestiune)+';',@listaGestiuniStorno)>0 
				/* nu fac filtru pe comenzi/contract, ci order by, pt. ca sa gasesc ceva cod de intrare */
				order by 
				/* filtrare prioritara dupa stoc pe comanda sau contractul vandut - chiar daca e rar cazul */
				(case when @comanda_asis='' then '0' else s.Comanda end) desc, 
				(case when @contract='' then '0' else s.Contract end) desc, 
				/* la bonuri, aleg prioritar codul de intrare cu acelasi pret cu amanuntul; la AP se ignora; */
				(case when s.Tip_gestiune<>'A' or abs(s.Pret_cu_amanuntul-@PretAm)<0.0009 then 1 else 2 end), 
				/* gestiunea se alege in ordinea stabilita in @listaGestiuniStorno */
				charindex(';'+RTrim(s.cod_gestiune)+';',@listaGestiuniStorno), 
				s.Data desc 
				
				--/*sp
				if isnull(@GestSt,'')=''
				BEGIN
					SELECT TOP 1
						@generareCodIntrare=(case when s.Tip_gestiune<>'A' or abs(s.Pret_cu_amanuntul-@PretAm)<0.0009 then 0 else 1 end),
						@GestSt=p.gestiune,
						@PStoc=p.Pret_de_stoc,
						@Stoc=@CantRam
					FROM dbo.pozdoc p 
					WHERE 
						Subunitate=@subunitate 
						AND cod=@cod 
						AND Tip_miscare='E' AND p.Cantitate>0 AND p.Tip IN ('AP','AC') AND p.Data<=@data
						AND charindex(';'+RTrim(p.Gestiune)+';',@listaGestiuniStorno)>0
						AND p.Tert=@tert
					AND Tip_miscare='I'
					ORDER BY Data desc
				END--sp*/
				
				--/*sp
				if isnull(@GestSt,'')=''
				BEGIN
					SELECT TOP 1 'iesiri pe tert pe cod pana la data bon din gest '+@listaGestiuniStorno,
						*
					FROM dbo.pozdoc p 
					WHERE 
						Subunitate=@subunitate 
						AND cod=@cod 
						AND Tip_miscare='E' AND p.Cantitate>0 AND p.Tip IN ('AP','AC') AND p.Data<=@data
						AND charindex(';'+RTrim(p.Gestiune)+';',@listaGestiuniStorno)>0
						AND p.Tert=@tert
					ORDER BY Data desc
				END--sp*/
				
				-- daca nu am gasit in stocuri, caut orice intrare de pe baza de date
				-- nu caut direct in pozdoc, pt. ca nu avem un index pe care sa-l folosim; oricum e caz exceptional.
				if isnull(@GestSt,'')=''
				BEGIN
					SELECT TOP 1
						@generareCodIntrare=1,
						@GestSt=(case when @TipDoc='AC' then rtrim(@GestBon)
									else (select top 1 item from dbo.split(@listaGestiuniStorno,';') where item<>'') end),
						@PStoc=p.Pret_de_stoc,
						@Stoc=@CantRam
					FROM dbo.pozdoc p 
					WHERE 
						Subunitate=@subunitate 
						AND cod=@cod
						AND Tip_miscare='I'
					ORDER BY Data desc
					
					select 'intrari pe cod ',*
					FROM dbo.pozdoc p 
					WHERE 
						Subunitate=@subunitate 
						AND cod=@cod
						AND Tip_miscare='I'
					ORDER BY Data desc
				END
				
				if @generareCodIntrare=1
				begin
					/* 
						aceasta metoda de generare cod intrare nou poate genera erori, dar probabilitatea e mica;
						s-ar putea inlocui cu o functie care sa genereze un cod intrare unic. 
					*/
					set @CodISt	= 'S'+left(NEWID(),12) 
				end
				
				if isnull(@GestSt,'')=''
				begin
					set @msgEroare='Acest produs('+rtrim(@Cod)+') nu a fost vandut'
						+' din gestiunile ('+@listaGestiuniStorno 
						+')! Nu se poate identifica pozitia pentru incarcarea stocului.'
					raiserror(@msgEroare,11,1)
				end
				
				-- scriu AP/AC in pozdoc 
				set @xml=(select @tipDoc as tip, '' as subtip, @NrDoc as numar, convert(char(10), @data,101) as data,
								@tert as tert, @PctLiv as punct_livrare,
								@NrDoc factura, convert(char(10), @data,101) as data_facturii,
								convert(char(10), @dataScad,101) as data_scadentei, @CtFact as cont_factura,
								@GestSt as gestiune, @Cod as cod, @CodISt as cod_intrare, @Stoc as cantitate,
								@PValuta as pret_valuta, @Disc as discount, @PVanz as pret_vanzare,
								@PretAm as pret_amanunt, @LM as lm, @CotaTVA as cota_TVA,
								@SumaTVA as suma_tva, @tipTVA as tipTVA,
								@CategP as categ_pret,
								@contract as contract, @comanda_asis as comanda_bugetari, 
								@Jurn as jurnal, 5 as stare, @barcod as barcod,
								@SerieSt as serie, @Vanz utilizator,
									(select 'PV' as sursa for xml raw,type) detalii
								for xml raw)

				/* apelez wScriuAviz pt. ca sa pot trimite @pret_vanzare; wScriuPozdoc nu citeste atributul */
				exec wScriuAviz @parXmlScriereIesiri=@xml output
				
				if @TipDoc='AC' and @NuTEAC=0 -- pentru bonuri, scriu TE spre alta gestiune
				begin
					declare @GestStPrim varchar(9)
					-- daca este alta gestiune in pozitii, pun acolo marfa.
					if @gestPozitie<>@GestBon
						set @GestStPrim = @gestPozitie
					
					-- daca nu am gasit, iau prima gestiune din lista de gestiuni(in afara de gestiunea curenta)
					if isnull(len(@GestStPrim),0)=0
						set @GestStPrim = (select top 1 item from dbo.split(@listaGestiuniPozitie,';') where Item <> @GestBon)
					
					if len(@GestStPrim)>0 -- apelez scrierea doar daca am gasit o gestiune valida
					begin
						set @xml=
							(select top 1 1 as '@fara_luare_date', rtrim(@subunitate) as '@subunitate', 'TE' as '@tip', 
								@NrDoc as '@numar', convert(varchar(20),@Data,101) as '@data', @CategP as '@categpret',
								@LM as '@lm',@GestSt as '@gestiune',  @contract as '@factura',
								@GestStPrim as '@gestprim', 5 as '@stare',
									(select rtrim(@Cod) as '@cod', convert(decimal(14,5),-1*@Stoc) as '@cantitate', 
										@CodISt as '@codintrare', convert(decimal(14,5),@PStoc) as '@pstoc', 
										convert(decimal(14,5),@Disc) as '@discount' ,
										@CtStoc as '@contstoc', @LM as '@lm', 
										@contract as '@factura'/*comanda livrare*/, @comanda_asis as '@comanda',
										(select 'PV' as sursa for xml raw,type) detalii
										for xml PATH, TYPE)
								for XML PATH, type)

						exec wScriuPozdoc @sesiune=@sesiune, @parXml=@xml
						update pozdoc -- inversez "semnul" pentru a avea transfer in acelasi sens 
							set Gestiune_primitoare=@GestSt, Gestiune=@GestStPrim, Cod_intrare=Grupa, Grupa=@CodISt, 
								Cont_de_stoc=Cont_corespondent, Cont_corespondent=Cont_de_stoc, Cantitate=-Cantitate, 
								Pret_cu_amanuntul=Pret_amanunt_predator, 
								TVA_neexigibil=(select top 1 Cota_TVA from nomencl where nomencl.Cod=pozdoc.Cod)
							where Subunitate=@subunitate and Tip='TE' and Numar=@NrDoc and Data=@Data 
								and Gestiune_primitoare<>@GestSt
					end
				end
				
				set transaction isolation level read committed
				
				set @CantRam=0
				set @TVADesc=@SumaTVA
				set @valoareDesc=@valoareLinie
				----------------------------------------- end pozitie storno -----------------------------------------
			end
			else -- @CantRam > 0 
			begin
				----------------------------------------- pozitie normala -----------------------------------------
				if @TipNom<>'S' 
				begin
					-- caut stoc rezervat pe contract / comanda (filtru pe contract/comanda)
					if isnull(@contract,'')<>'' or ISNULL(@comanda_asis,'')<>'' 
					begin 
						exec iauPozitieStoc @Cod=@Cod, @TipGestiune='', @Gestiune=@GestSt output, @Data=null, @CodIntrare=@CodISt output, 
							@PretStoc=@PStoc output, @Stoc=@Stoc output, @ContStoc=@CtStoc output, @DataExpirarii=null, 
							@TVAneex=null, @PretAm=null, @Locatie=null, @Serie=@SerieSt output, 
							@FltTipGest=null, @FltGestiuni=@listaGestiuniPozitie, @FltExcepGestiuni=@ExcGest, @FltData=@Data, 
							@FltCont=null, @FltExcepCont=@ExcCont, @FltDataExpirarii=null, @FltLocatie=null, 
							@FltLM=null, @FltComanda=@comanda_asis, @FltCntr=@contract , @FltFurn=null, @FltLot=null, 
							@FltSerie=@serieSauNrDocIncasare, @OrdCont=@ContOrd, @OrdGestLista=@OrdGest
					
						-- elimin gestiunea de rezervari, cand caut alt stoc (sa nu iau din ce e rezervat pe alt contract) 
						if @rezervareStocComenzi=1 and isnull(@CodISt,'')='' and isnull(@contract,'')<>''
							set @listaGestiuniPozitie = replace(@listaGestiuniPozitie, @gestRezervariComenzi+';','')
					end
					
					-- caut stoc in lista de gestiuni din care se face TE automat
					if isnull(@CodISt,'')=''
						exec iauPozitieStoc @Cod=@Cod, @TipGestiune='', @Gestiune=@GestSt output, @Data=null, @CodIntrare=@CodISt output, 
							@PretStoc=@PStoc output, @Stoc=@Stoc output, @ContStoc=@CtStoc output, @DataExpirarii=null, 
							@TVAneex=null, @PretAm=null, @Locatie=null, @Serie=@SerieSt output, 
							@FltTipGest=null, @FltGestiuni=@listaGestiuniPozitie, @FltExcepGestiuni=@ExcGest, @FltData=@Data, 
							@FltCont=null, @FltExcepCont=@ExcCont, @FltDataExpirarii=null, @FltLocatie=null, 
							@FltLM=null, @FltComanda='', @FltCntr='' , @FltFurn=null, @FltLot=null, 
							@FltSerie=@serieSauNrDocIncasare, @OrdCont=@ContOrd, @OrdGestLista=@OrdGest
				end
				
				--select isnull( convert(varchar(300),@GestSt), '@gestst is null')
				if @codIntrareInDenumire=1 or @GestSt is null
				begin
					-- daca nu am gasit stoc, stabilesc gestiunea de vanzare.
					set @GestSt = 
							(case	when @gestPozitie<>@GestBon then @gestPozitie  -- daca in pozitii e alta gestiune decat in antet, ramane ea.
									else -- vand din prima gestiune disponibila.
										-- la vanzare servicii din alte gestiuni, nu se va gasi in par, si las @gestpozitie.
										isnull((select top 1 [dbo].[fStrToken](val_alfanumerica, 1, ';') 
											from par where Tip_parametru='PG' and Parametru=@GestBon), @gestpozitie) end )
					--select @GestSt '@GestSt after attrib'
					if @codIntrareInDenumire=1
						set @CodISt=@serieSauNrDocIncasare
					else
						set @CodISt=(case when @TipNom<>'S' and @AreSerii=1 then '' else @serieSauNrDocIncasare end)				
					set @PStoc=@ExcCont
					set @Stoc=@CantRam
					set @CtStoc=''
					set @SerieSt=(case when @TipNom<>'S' then @serieSauNrDocIncasare else '' end)
				end
				
				/* actualizam cantitatea care va trebui scrisa de pe alte pozitii de stoc */
				if @CantRam>=0.001 and @CantRam>@Stoc 
					set @cantDeScris=@Stoc
				else 
					set @cantDeScris=@CantRam
				
				set @CantRam=@CantRam-@cantDeScris
				
				/* 
					Calcule pentru spargerea pe mai multe coduri de intrare. 
					* Cand o pozitie din bt se sparge pe mai multe coduri de intrare, pretul de vanzare unitar si 
						TVA-ul se estimeaza pe primele pozitii scrise in pozdoc estimand un pret si un tva unitar 'mediu'.
						La ultima pozitie (@CantRam=0), pretul unitar si suma TVA se recalculeaza asa incat sumele pozitiilor din pozdoc 
						sa 'bata' pana la ultima zecimala cu bp.
					* Daca nu se sparge pe mai multe coduri de intrare, @CantRam e direct 0 si se scriu direct valorile din bt.
				*/
				set @TvaDeScris= round((case when abs(@CantRam)<0.001 then (@SumaTVA-@TVADesc) else @SumaTVA*@cantDeScris/@Cant end),2)
				set @pretVanzareDeScris=round((case when abs(@CantRam)<0.001 and @cantDeScris>0 then (@valoareLinie-@valoareDesc)/@cantDeScris else @PVanz end),5)
				

				-- transfer automat in GESTPV daca nu e pe stoc.
				-- doar pentru AC-uri
				if @TipDoc='AC' and @TipNom<>'S' and @NuTEAC=0
				begin
					--select 'te',  @GestSt '@GestSt', @GestBon '@GestBon', @gestPozitie '@gestPozitie'
					if @DetaliereBonuri=0
						set @NrTE=left('TE'+left(replace(convert(char(10),@Data,103),'/',''),4)+rtrim(@GestSt),8)
					else
						set @NrTE=@NrDoc
					set @CodIPrim=''
					
					--select 'te2',  @GestSt '@GestSt', @GestBon '@GestBon'
					-- scriu TE doar daca am gasit stoc(@gestst <>'') si daca stocul gasit e in alta gestiune decat cea de vanzare
					if isnull(@GestSt,'')<>'' and isnull(@GestSt,'')<>@GestBon
					begin
						set @xml = (select '' as subtip, @NrTE as numar, @Data as data, @GestSt as gestiune, 
							@GestBon as gestiune_primitoare, @Cod as cod, @CodISt as cod_intrare,
							@cantDeScris as cantitate, @pretFaraDiscount/*sa trimit @PretAm?*/ as pret_amanunt, @CategP as categ_pret,
							@LM as lm, 5 as stare, @comanda_asis as comanda_bugetari, @Jurn as jurnal, 
							@Barcod as barcod, @SerieSt as serie, @Vanz as utilizator,
								(select 'PV' as sursa for xml raw,type) detalii
							for xml raw)
						exec wScriuTE @parXmlScriereIesiri = @xml output
						
						set @CodIPrim=isnull(@xml.value('(/row/@cod_intrare_primitor)[1]','varchar(50)'),isnull(@CodIPrim,''))
						set @CodISt=@CodIPrim
					end
					set @GestSt=@GestBon
				end
				
				if @TipDoc='AC' set @tipTVA=0 -- bonurile de casa nu pot lucra cu TVA neinregistrat 
				if @tipTVA=1 
				begin -- in pozdoc se pune =2 pentru "TVA neinregistrat"
					set @tipTVA=2 
					set @CotaTVA=0
					set @TvaDeScris=0
				end
				
				if @TipDoc='TE'
				begin
					declare @gestprim varchar(20)
					set @gestprim = (select bon.value('(/date/document/@gestprim)[1]','varchar(50)') 
										from antetBonuri where idAntetBon=@idAntetBon)
					
					set @xml = (select '' as subtip, @NrDoc as numar, @Data as data, @tert as tert, 
						@GestSt as gestiune, @gestprim as gestiune_primitoare,
						@Cod as cod, @CodISt as cod_intrare, @cantDeScris as cantitate, @LM as lm, @contract as contract,
						0 as discount, @Jurn as jurnal, 5 as stare, @vanz as utilizator, @SerieSt as serie, @Barcod barcod,
						@CategP as categ_pret, @PretAm as pret_amanunt, @PValuta as pret_valuta,
							(select 'PV' as sursa for xml raw,type) detalii
						for xml raw)
					exec wScriuTE @xml
				end
				else
				begin
					if @TipDoc='AC' and @TipNom='S'
						set @GestSt=@GestBon
					
					-- caut sa vad daca as putea cumula pozitiile
					set @idPozdoc = 0
					if @TipDoc='AC' and @comanda_asis='' and @contract='' -- cumulare pozitii doar la AC-uri la care nu se vinde din deviz sau comanda de livrare.
						select @idPozdoc = idPozdoc
						from pozdoc 
						where subunitate=@subunitate and tip=@tipDoc and numar=@NrDoc and data=@data and cod=@cod and 
							cod_intrare=@codISt and pret_vanzare=@pretVanzareDeScris
							and Discount=@Disc and Loc_de_munca=@LM and Utilizator=@Vanz
					
					if @idPozdoc > 0
						update pozdoc set cantitate=cantitate+@cantDeScris,tva_deductibil=tva_deductibil+@TvaDeScris
							where idPozDoc = @idPozdoc
					else --Pozitie noua
					begin
						set @xml=(select @tipDoc as tip, '' as subtip, @NrDoc as numar, convert(char(10), @data,101) as data,
									@tert as tert, @PctLiv as punct_livrare,
									@NrDoc factura, convert(char(10), @data,101) as data_facturii,
									convert(char(10), @dataScad,101) as data_scadentei, @CtFact as cont_factura,
									@GestSt as gestiune, @Cod as cod, @CodISt as cod_intrare, @cantDeScris as cantitate,
									@PValuta as pret_valuta, @Disc as discount, @pretVanzareDeScris as pret_vanzare,
									@PretAm as pret_amanunt, @LM as lm, @CotaTVA as cota_TVA,
									@TvaDeScris as suma_tva, @tipTVA as tipTVA,
									@CategP as categ_pret,
									@contract as contract, @comanda_asis as comanda_bugetari, 
									@Jurn as jurnal, 5 as stare, @barcod as barcod,
									@SerieSt as serie, @Vanz utilizator,
										(select 'PV' as sursa for xml raw,type) detalii
									for xml raw)
						exec wScriuAviz @parXmlScriereIesiri=@xml output
					end
				end
				set @TVADesc=@TVADesc+@TvaDeScris
				/* in pozdoc, fiecare pozitie se rotunjeste la 2 zecimale */
				set @valoareDesc=@valoareDesc+round(@pretVanzareDeScris*@cantDeScris,2)
				
			end ----------------------------------------- end pozitie normala -----------------------------------------
		end -- end bucla while pentru spargere pe cod intrare
		
		-- update pentru devize auto
		-- daca e completat ceva in campul comanda_asis, verific in XML daca e deviz si actualizez pe deviz.
		if isnull(@comanda_asis,'')<>'' and exists (select 1 from sysobjects where name='pozdevauto') 
		begin
			declare @codDeviz varchar(20), @pozDeviz int
			
			-- verific daca s-a finalizat un deviz
			select	@codDeviz = isnull(pozitie.bon.query('data(@coddeviz)').value('.', 'varchar(80)'),''),
					@pozDeviz = isnull(pozitie.bon.query('data(@pozdeviz)').value('.', 'varchar(80)'),0)--pozdeviz e null pentru linia de manopera(care se cumuleaza)
				from @xmlDoc.nodes('/date/document/pozitii/row[@nrlinie=sql:variable("@NrLin")]') pozitie(bon)
			
			if @codDeviz<>''  
			begin
				-- scriu numarul facturii in deviz si schimb starea.
				update pozdevauto
						set Numar_aviz=@NrDoc, Data_facturarii=@Data, Stare_pozitie=3
					where Cod_deviz = @codDeviz 
					and (@pozDeviz=0 or Pozitie_articol = @pozDeviz) 
					and (@pozDeviz>0 or Tip_resursa='M')
				
				-- salvez faptul ca am modificat pozitia aceasta de deviz. 
				-- daca sunt erori, anulez aceste modificari.
				if not exists (select * from @devize where cod_deviz=@codDeviz and pozitie=@pozDeviz)
					insert into @devize(cod_deviz, pozitie)
						values (@codDeviz, @pozDeviz)
			end
			-- schimb stare deviz
			if not exists (select * from pozdevauto where cod_deviz = @coddeviz and stare_pozitie < 3)
				update devauto set Stare=3 where cod_deviz = @coddeviz
		end -- end update pentru devize auto
	end -- end @Incas=0 (linia = vanzare produs)
	
	if @TipDoc='AP' and @Incas=1
	begin
		declare @contCasa varchar(20)
		
		-- caut existenta contului in XML (de regula la refaceri)
		select	@contCasa = isnull(pozitie.bon.query('data(@cont)').value('.', 'varchar(20)'),'')
			from @xmlDoc.nodes('/date/document/pozitii/row[@nrlinie=sql:variable("@NrLin")]') pozitie(bon)
		
		if @contCasa='' -- daca nu este in xml, citesc din proprietati, si il salvez in xml.
		begin
			if @bTip='36'
				set @contCasa=rtrim(ISNULL((select valoare from proprietati where tip='UTILIZATOR' and Cod_proprietate='CONTCARD' and cod=@Vanz),'5114'))
			else
				set @contCasa=rtrim(ISNULL((select valoare from proprietati where tip='UTILIZATOR' and Cod_proprietate='CONTCASA' and cod=@Vanz),'5311'))
			
			--update antetBonuri set Bon.modify('replace value of (/date/document/pozitii/row[@nrlinie=sql:variable("@NrLin")]/@cont)[1] with sql:variable("@contCasa")')
			update antetBonuri set Bon.modify('insert attribute cont {sql:variable("@contCasa")} as last into (/date/document/pozitii/row[sql:variable("@NrLin")])[1]')
				where idAntetBon=@idAntetBon
		end
		
		declare @denTert varchar(80),@nr_poz_out int, @numarDocIncasare varchar(20), @tipIncasariPeFacturi int
		set @denTert=ISNULL(rtrim((select top 1 denumire from terti where tert=@tert)),'')
		exec luare_date_par 'PV', 'INCPEFACT', 0, @tipIncasariPeFacturi output, ''
		
		-- verific valoarea din numar_doc_incasare din bt
		-- salvez acolo numarul de chitanta, pentru cand se reapeleaza din refaceri sau altceva.
		set @numarDocIncasare=@serieSauNrDocIncasare
		
		if @numarDocIncasare = ''
		begin
			if @tipIncasariPeFacturi=2 -- daca se tipareste la casa de marcat, nr. chitanta=nr. bon
				set @numarDocIncasare=CONVERT(varchar(30), @NrBon)
			else
			begin -- iau numar din plaja
				set @xml = (select 'IB' as tip, @vanz as utilizator, @LM as lm for xml raw)
				exec wIauNrDocFiscale @parXML=@xml, @NrDoc=@numarDocIncasare output
					
				if isnull(@numarDocIncasare,0)=0
					raiserror('Eroare la determinare numar chitanta. Plaja de numere folosita pentru acest tip de document s-a epuizat, sau nu este configurata!',16,1)
			end
		end
		
		-- daca s-a schimbat, il scriu si in bt, pentru refaceri & stuff
		if @numarDocIncasare <> @serieSauNrDocIncasare 
			update bt set Numar_document_incasare = @numarDocIncasare
				where Casa_de_marcat=@Casa and data=@Data and Numar_bon=@NrBon 
				and Vinzator=@vanz and Numar_linie=@NrLin
		
		-- citesc cont factura (e returnat de scriuAviz, dar cand vom folosi wScriuPozdoc nu il vom mai avea).
		select @CtFact=rtrim(Cont_factura)
			from pozdoc p 
			where p.Subunitate=@subunitate and p.Tip=@TipDoc and p.Numar=@NrDoc 
				and p.Data=@Data and p.Cod=@Cod
		
		/*Stergem liniile generate eventual anterior*/
		delete from pozplin where Subunitate=@subunitate and Plata_incasare='IB' and data=@data and tert=@tert and factura=@factura and Explicatii=@denTert

		set @xml=
			(select 'RE' as tip, @contCasa as cont, convert(char(10),@data,101) as data,
				(select 'IB' as subtip, @tert as tert, @numarDocIncasare as numar, @CtFact as contcorespondent,
					@pretFaraDiscount as suma, @denTert as explicatii, @LM as lm, @vanz as utilizator, @factura as factura  
					for xml raw, type) 
			for xml raw)
		
		exec wScriuPozplin @sesiune=@sesiune, @parXML=@xml
	end
	--Aici se vor trata incasarile 
	exec wMutBTBP @Casa,@Vanz,@Data,@NrBon,@NrLin,@TipDoc,@Incas,@Cant,@CantExc8,0
	fetch next from @tmpbon into @Incas, @NrLin, @Cod, @AreSerii, @serieSauNrDocIncasare, @Coef, @total, @Cant, @CotaTVA, @SumaTVA, @pretFaraDiscount, @Disc, @Barcod, @TipNom, @LM, @comanda_asis, @contract, @bTip, @tipTVA, @gestPozitie
	set @nFetchStatus=@@fetch_status
end

-- apelare procedura specifica care sa faca alte operatii.
if exists (select 1 from sysobjects where type='P' and name='wDescarcBonSP2')
begin
	set @xml=(select @idAntetBon idAntetBon for xml raw)
	exec wDescarcBonSP2 @sesiune=@sesiune, @parXML=@xml
end

-- LEGACY: apelare procedura specifica care sa faca alte operatii.
if exists (select 1 from sysobjects where type='P' and name='DescarcBonSP')
begin
	--exec DescarcBonSP @CasaAnt,@DataAnt,@NrBonAnt,@VanzAnt,@TipDoc,@NrDoc
	select 'Procedura DescarcBonSP nu mai este suportata in PVria. Inlocuiti procedura mentionata cu wDescarcBonSP2.' as textMesaj for xml raw,root('Mesaje')
end

-- apelare procedura care sa trateze puncte de fidelizare.
if exists (select 1 from sysobjects where type='P' and name='CalculPuncteBon')
begin
	set @xml=(select @idAntetBon idAntetBon for xml raw)
	exec CalculPuncteBon @sesiune=@sesiune, @parXML=@xml
end

if @facturiDefinitive=1 and @TipDoc='AP'
begin
	if exists (select 1 from incfact where subunitate=@subunitate and Numar_factura=@NrDoc and Numar_pozitie=1)
		update incfact set mod_tp='D' where subunitate=@subunitate and Numar_factura=@NrDoc and Numar_pozitie=1
	else 
		INSERT INTO incfact(Subunitate,Numar_factura,Numar_pozitie,Mod_plata,Serie_doc,Nr_doc,data_doc,suma_doc,datasc_doc,mod_tp,info_tp,Tert,Cont,Loc_de_munca,Utilizator,Data_operarii,Ora_operarii,Jurnal)
		select @subunitate, @NrDoc, 1, '', '', @NrDoc, @Data, 0, @dataScad, 'D', '', @tert,'','',@Vanz, @Data, '',''
end

if @CuTranzactii=1
	commit transaction descarcaBon

/* 
-- linii pentru debug

select * from pozdoc 
where Subunitate='1' and data=@DataAnt
and Numar=@NrDoc
order by data desc, tip

raiserror('in lucru...',11,1)
*/
end try
begin catch
	set @msgEroare = ERROR_MESSAGE()+'. (idAntetBon='+convert(varchar,isnull(@idantetbon,0))+') (wDescarcBonSP)'
	
	if @CuTranzactii=1 and EXISTS (SELECT 1 FROM sys.dm_tran_active_transactions WHERE name = 'descarcaBon')            
		ROLLBACK TRAN descarcaBon
	else
	-- daca sunt erori, mut inapoi in bt tot bonul si sterg din pozdoc documentul
	-- NEFUNCTIONAL pentru cumulare bonuri pe un AC.
	if @idAntetBon>0 and isnull(@eroareTimeout,0)=0
	begin
		if @TipDoc in ('AP', 'TE') -- la facturi si transferuri, sterg tot timpul din pozdoc
			delete from pozdoc where Subunitate=@subunitate and tip=@tipDoc and data=@Data and Numar=@NrDoc and stare=5
		
		-- daca nu se cumuleaza toate bonurile pe un AC, sterg AC-ul partial
		-- daca e setarea cu detaliere, il las in pace - vor fi erori.
		if @tipDoc='AC' and @DetaliereBonuri=1 
			delete from pozdoc where Subunitate=@subunitate and tip in ('TE', 'AC') and data=@Data and Numar=@NrDoc and stare=5
		
		-- anulare modificari in devize
		if exists (select * from @devize) and exists (select 1 from sysobjects where name='pozdevauto')
		begin
			update p
					set stare_pozitie=2, numar_aviz='', Data_facturarii='1901-01-01'
				from pozdevauto p
				inner join @devize d on p.cod_deviz=d.cod_deviz and p.Pozitie_articol=d.pozitie
		
			update da
					set da.stare=2
				from devauto da
				inner join (select distinct cod_deviz from @devize) d on da.cod_deviz=d.cod_deviz
				where da.Stare=3
				
			if not exists (select * from pozdevauto where cod_deviz = @coddeviz and stare_pozitie < 3)
				update devauto set Stare=3 where cod_deviz = @coddeviz
		end
		
		-- pentru descarcare bonuri cu cumulare bonuri in un AC, nu mai fac nimic. 
		-- la TE si AP si bonuri detaliate, mut toate pozitiile in bt, pt. ca le-am sters din pozdoc mai sus
		if @tipDoc<>'AC' or @DetaliereBonuri=0
		begin
			insert bt
			(Casa_de_marcat, Factura_chitanta, Numar_bon, Numar_linie, Data, Ora, Tip, Vinzator, Client, Cod_citit_de_la_tastatura, CodPLU, Cod_produs, Categorie, UM, 
				Cantitate, Cota_TVA, Tva, Pret, Total, Retur, 
				Inregistrare_valida, Operat, Numar_document_incasare, Data_documentului, Loc_de_munca, Discount, 
				lm_real, Comanda_asis,[Contract], idAntetBon)
			select Casa_de_marcat, Factura_chitanta, Numar_bon, Numar_linie, Data, Ora, Tip, Vinzator, Client, Cod_citit_de_la_tastatura, CodPLU, Cod_produs, Categorie, UM, 
				Cantitate, Cota_TVA, TVA, Pret, Total, Retur, 
				Inregistrare_valida, Operat, Numar_document_incasare, Data_documentului, Loc_de_munca, Discount, 
				lm_real, Comanda_asis,[Contract], idAntetBon
			from bp where idAntetBon=@idAntetBon
		
			delete from bp where idAntetBon=@idAntetBon
		end
	end
end catch

begin try
	-- incerc sa inchid cursoarele doar daca sunt deschise
	if CURSOR_STATUS('variable','@tmpbon') >= 0
		close @tmpbon
	if CURSOR_STATUS('variable','@tmpbon') >= -1
		deallocate @tmpbon
end try
begin catch end catch

if len(@msgEroare)>0
	raiserror(@msgeroare,11,1)