--***
create procedure wUnCodNomenclator @sesiune varchar(50), @parXML XML, @xmlFinal xml=null output /* pt teste */
as
set transaction isolation level read uncommitted

declare @returnValue int
if exists(select * from sysobjects where name='wUnCodNomenclatorSP' and type='P')      
begin
	exec @returnValue = wUnCodNomenclatorSP @sesiune,@parXML
	return @returnValue 
end

if exists(select * from sysobjects where name='wUnCodNomenclatorSP1' and type='P')      
begin
	exec @returnValue = wUnCodNomenclatorSP1 @sesiune=@sesiune, @parXML=@parXML output
	
	if @parXML is null
		return @returnValue 
end

declare @cod varchar(100), @categoriePret int, @cantitate decimal(12,3), @vanzareFaraStoc_OLD bit, @vanzareFaraStoc bit, @ruleazaSelect bit, @barcode varchar(50), @UM varchar(3),
		@utilizator varchar(10),@gestiuneBon varchar(13), @esteStoc bit, @mesaj varchar(max), @tipNomencl varchar(10), @stocTotal float, @codUM varchar(3),
		@pret float, @discount float, @tert varchar(50), @comanda varchar(20), @xmlPret xml, @listaGestiuni varchar(max), @GESTPVbon varchar(100),
		@coefConversie float, @codInitial varchar(50), @cantitateStr varchar(50), @denumire varchar(50), @cotaTvaStr varchar(50),
		@trebuieCantarit bit, @durataInput int, @clipboardIsSimilar bit , @sub varchar(20), 
		@faraMesaje bit 

select	@cod=ISNULL(@parXML.value('(/row/@cod)[1]', 'varchar(100)'), ''), 
		@codInitial=ISNULL(@parXML.value('(/row/@codInitial)[1]', 'varchar(20)'),''), 
		@categoriePret=ISNULL(@parXML.value('(/row/@categoriePret)[1]', 'int'), '1'), 
		@tert=ISNULL(@parXML.value('(/row/tert/@cod)[1]', 'varchar(50)'), ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(50)'),'')), 
		@comanda=ISNULL(@parXML.value('(/row/@comanda)[1]', 'varchar(20)'), ''), 
		@cantitate=isnull(@parXML.value('(/row/@cantitate)[1]', 'decimal(12,3)'),1),
		@GESTPVbon=ISNULL(@parXML.value('(/row/@GESTPV)[1]', 'varchar(100)'),''), -- gestiunea bonului - poate fi setata si din detalii...
		@durataInput=ISNULL(@parXML.value('(/row/@durataInput)[1]', 'int'), 0) , /* timpul(in ms) de la tastarea primei litere pana la apasare <enter>. Poate fi 0 daca e din interfata touch.  */
		@clipboardIsSimilar=ISNULL(@parXML.value('(/row/@clipboardIsSimilar)[1]', 'bit'), 0), /* flag trimis 'true' daca textul din clipboard e similar cu textul cautat */
		@faraMesaje = case when @xmlFinal is not null then 1 else 0 end /* daca @xmlFinal nu e null, inseamna ca procedura aceasta e apelata din alta procedura si nu mai returnam xml prin select. */

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
if @utilizator is null
	return -1

/* determinare gestiune: daca nu e trimisa in parXML, se ia din proprietatea GESTPV de pe user. 
Se atasaza si gestiunile din care se face transfer automat, pentru calcularea stocului */
set @gestiuneBon= (case when @GESTPVbon<>'' then @GESTPVbon else dbo.wfProprietateUtilizator('GESTPV', @utilizator) end)
set @listaGestiuni= dbo.wfListaGestiuniAtasatePV(@gestiuneBon)

/* categorie pret in ordine 
	1. Categoria Documentului/Tertului, (din PVria vine categoria documentului daca este configurabila in detalii, sau a tertului, daca se alege un tert cu alta categorie.)
	2. Categoria gestiunii  */
if isnull(@categoriePret,0)=0
	set @categoriePret=1
if @categoriePret=1 /* din PVria vine implicit 1 sau categoria tertului */
	set @categoriePret=(select rtrim(min(valoare)) from proprietati where tip='GESTIUNE' and cod_proprietate='CATEGPRET' and cod=@gestiuneBon)

/* 
	identificare cod produs. Daca @codInitial e completat, exista x sau * in denumire si trebuie cautat codul initial.
	@codInitial contine textul nemodificat din casuta de input din PVria.
*/
if @codInitial<>'' and @cod<>@codInitial
begin
	-- verific daca este codul in nomencl.
	if exists ( select 1 from nomencl where cod = @codInitial )
	begin
		set @cod=@codInitial
		set @cantitate=1 -- resetam cantitate pt. ca s-a identificat eronat din @codInitial
	end
	else -- caut in tabela cu coduri de bara.
	if exists (select * from codbare where Cod_de_bare=@codInitial)
	begin
		select @barcode=rtrim(cod_de_bare) , @cod=rtrim(Cod_produs), @codUM=rtrim(um)
			from codbare 
			where Cod_de_bare=@codInitial 
		set @cantitate=1
	end
end -- pana aici ne-am asigurat ca @codInitial nu contine un cod valid de produs sau barcode.
if not exists (select 1 from nomencl where cod=@cod)
begin
	/* verific daca am scanat un cod de bare si identific codul de produs */
	select @barcode=rtrim(cod_de_bare) , @cod=rtrim(Cod_produs), @codUM=rtrim(um)
	from codbare 
	where Cod_de_bare=@cod 
end

if not exists ( select 1 from nomencl where cod = @cod )
begin 
	IF @codInitial='' -- cand nu se trimite cod initial - se va corecta.
		SET @codInitial=@cod
	/* 
		Verific daca s-a scanat un card de fidelizare. 
		Implicit dimensiunea unui cod de card > 20; daca este SP1 se valideaza acolo dimensiune sau altele.
	 */
	if (LEN(@codInitial)>20 or exists (select 1 from sysobjects where type='P' and name='wIaPuncteCardFidelizareSP1') )
		and exists (select * from CarduriFidelizare c where c.UID=@codInitial)
			
	begin
		set @xmlFinal=@parXML
		if (@xmlFinal.value('(/row/@uidCardFidelizare)[1]','varchar(50)')) is null
			set @xmlFinal.modify ('insert attribute uidCardFidelizare {sql:variable("@codInitial")} into (/row)[1]')
		else
			set @xmlFinal.modify('replace value of (/row/@uidCardFidelizare)[1] with sql:variable("@codInitial")')

		exec wIaPuncteCardFidelizare @sesiune=@sesiune, @parXML=@xmlFinal
		
		return
	end
	else
	begin
		set @mesaj='Codul introdus ('+ @cod + case when @codInitial<>@cod then ' sau ' + @codInitial  else '' end + ') nu poate fi gasit.'
		raiserror(@mesaj,11,1)
		return -1
	end
end

/* setarea 'GE','FARASTOC' = pot face vanzare 'in rosu'(fara sa existe pe stoc respectivele produse) */
select	@vanzareFaraStoc_OLD=(case when parametru='FARASTOC' then Val_logica else isnull(@vanzareFaraStoc_OLD,0) end),
		@vanzareFaraStoc=(case when parametru='FARAVSTN' then Val_logica else isnull(@vanzareFaraStoc,0) end),
		@sub=(case when parametru='SUBPRO' then rtrim(val_alfanumerica) else @sub end)
from par 
where Tip_parametru='GE' and Parametru in ('FARASTOC', 'FARAVSTN', 'SUBPRO')

-- verific daca trebuie trimisa cota TVA=0 - a se pastra corelat cu conditia din wDescarcBon
declare @tipTVA int
if @tert='' or exists (select 1 from TvaPeTerti  where tipf='F' and  tert=@tert and factura IS NULL and tip_tva='N')
	set @tipTVA=0
else
	set @tipTVA=isnull((select convert(int, left(n.tip_echipament,1)) from nomencl n where n.Cod=@cod),0)

/* formare pret */
select	@pret=null, @discount=null,
		@xmlPret= (select @cod cod, @tert tert, @comanda  comandalivrare, @categoriePret categoriePret, (case when @tipTVA=1 then 0 else 1 end) iaupretamanunt for xml raw )
--exec dbo.wIaPretDiscount @xmlPret, @pret output, @discount output

create table #preturi(cod varchar(20),nestlevel int)
insert into #preturi
select @cod ,@@NESTLEVEL

exec CreazaDiezPreturi
exec wIaPreturi @sesiune=@sesiune,@parXML=@xmlPret

select @pret=case when @tipTVA=1 then pret_vanzare else pret_amanunt end ,
	@discount=discount
from #preturi 
where cod=@cod

/* validare tip nomencl si calculare pret in alte UM, folosind coef. conversie */
-- Ghita, 27.06.2011: am citit UM de stoc, am modificat cantitatea sa fie in UM de stoc
select @tipNomencl=tip, @UM=UM,--rtrim((case isnull(@codUM,1) when 2 then UM_1 when 3 then UM_2 else UM end)),
	@coefConversie= (case isnull(@codUM,1) when 1 then 1 when 2 then Coeficient_conversie_1 when 3 then Coeficient_conversie_2 else 1 end),
	--@pret=@pret*@coefConversie
	@cantitate=@cantitate*@coefConversie,
	@denumire=rtrim(n.denumire), 
	@cotaTvaStr=convert(varchar(50),convert(decimal(12,2),(case when @tipTVA=1 then 0 else convert(decimal(12,2),cota_tva) end)))
from nomencl n where cod=@cod 

if @tipNomencl not in ('A', 'M', 'P', 'S') 
begin
	set @mesaj='Tipul de nomenclator:'+@tipNomencl+' nu este permis la vanzare.'
	raiserror(@mesaj,11,1)
	return -1
end

set @trebuieCantarit = (case when @UM='kg' then 1 else 0 end)

/* validare cod: verifica daca se poate vinde fara stoc. Daca nu e voie, valideaza stocul pentru
   gestiunile atasate. Pentru cant<=0 nu afisez eroare, dar calculez si trimit stocMaxim. */
if @vanzareFaraStoc_OLD=0 -- validare stoc dupa setarea veche din ASiSplus (=1 inseamna ca nu validez stocul)
	and @vanzareFaraStoc=0 -- validare stoc de ASiSria/PVria (=1 inseamna ca nu validez stocul)
	and @tipNomencl<>'S'
begin 
	/* calculez stoc total pe gestiunile valide */
	set @stocTotal= ISNULL(( select SUM(stoc) from stocuri s inner join dbo.split(@listagestiuni,';') lg on s.Cod_gestiune=lg.Item
		where Subunitate=@sub and cod=@cod ),0)

	if @stocTotal<=0.00999 and @cantitate>0.00
	begin
		set @mesaj='Produsul selectat nu este pe stoc in ' + 
			(case when @gestiuneBon+';'=@listaGestiuni then 'gestiunea '+rtrim(@gestiuneBon) 
				else 'gestiunile '+REPLACE(@listaGestiuni,';',',') end) + '.'
		raiserror(@mesaj,11,1)
		return -1
	end
	
	/* pentru vanzare in alte UM, cantitatea implicita nu e obligatoriu 1 */
	if @UM<>'BUC' and @stocTotal>0.0001 and @stocTotal<1.00 and @cantitate=1.00
		set @cantitate=round(@stoctotal,3)
	
	if @stocTotal-@cantitate<-0.0001 /*isnull(@coefConversie,1)*/ and @cantitate>0.00 /*nu validez cantitate, daca se adauga produs storno.*/
	begin
		set @mesaj='Stocul maxim disponibil este de '+ convert(varchar,CONVERT(decimal(12,2),@stocTotal))+'.'+
			(case when @coefConversie<>1 then '(stocul maxim este afisat in UM principala)' else '' end)
		raiserror(@mesaj,11,1)
		return -1
	end
end
set @cantitateStr=replace(rtrim(replace(replace(rtrim(replace(@cantitate,'0',' ')),' ','0'),'.',' ')),' ','.')

-- atentie la atributele hardcodate care se trimit si pt. offline. (@cod, @denumire, @um, @cotatva, @codbare
set @xmlFinal=
(select @cod as cod, @denumire as denumire, @UM um, @codUM codUM, @cotaTvaStr as cotatva, @barcode as barcode,
	convert(decimal(12,2),@pret) as pretcatalog, convert(decimal(12,2),@discount) as discount, @tipNomencl as tip, 
	@cantitateStr as cantitate,
	@trebuieCantarit as trebuieCantarit,
	convert(decimal(12,2),@stocTotal) as stocMaxim,
	null as cotatvaincasam /* identificator cota TVA se poate trimite din SP. E mai puternic decat setarile de pe statii. 
								(case when cota_tva=24 then 1 when Cota_TVA=9 then 2 else 0 end)*/,
	null as zecimaleCantitate /* pt. a permite alt numar de zecimale la cantitate, 
				din macheta pt. schimbare cantitate - momentan in casuta cu Cod permitem oricate zecimale... */ 
	for xml raw)

/* procedura specifica va insera atribute in xml-ul primit in parametrul 3 */
if exists (select 1 from sysobjects where name ='formeazaPretMinimSP') /* procedura legacy folosita (cred) numai la pragmatic */
	exec formeazaPretMinimSP @sesiune=@sesiune, @parXML=@parXML, @xmlFinal=@xmlFinal output

/* procedura specifica va insera atribute in xml-ul primit in parametrul 3.
	in @parXML se trimite parametrul din PVria, iar @xmlFinal este generat in aceasta procedura 
*/
if exists (select 1 from sysobjects where name ='wUnCodNomenclatorSP2')
	exec wUnCodNomenclatorSP2 @sesiune=@sesiune, @parXML=@parXML, @xmlFinal=@xmlFinal output

if @faraMesaje=0
	select @xmlFinal


return 0 
