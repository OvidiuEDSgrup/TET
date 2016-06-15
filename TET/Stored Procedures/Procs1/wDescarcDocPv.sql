--***
create procedure wDescarcDocPv @sesiune varchar(50), @parXML xml, @idrulare int=0
as
if exists (select 1 from sysobjects where type='P' and name='wDescarcDocPvSP')
begin
		-- Atentie! Va recomandam sa evitati scrierea unei proceduri specifice pentru descarcare. 
		-- Daca totusi alegeti sa folositi, marcati folosind tag-uri de tip /*specific*/ si /*end specific*/ 
		-- partea modificata, pentru a putea integra usor codul specific si in 
		-- versiunile mai noi ale procedurii
		exec wDescarcDocPvSP @sesiune, @parXML
		return
end
set transaction isolation level read uncommitted

set nocount on
declare @UID varchar(50), @GestBon varchar(13),@factura varchar(20), @idAntetBon int,
	@Casa int,@Data datetime,@NrBon int,@Vanz varchar(10), @tert varchar(13), @dataScad datetime, @CategP varchar(5), @PctLiv varchar(20),
	@dataStart datetime, @msgEroare varchar(max), @eroareTimeout bit, @xml xml


begin try

/* citesc variabile din parXML */
select	@UID = @parXML.value('(/row/@UID)[1]', 'varchar(50)'),
		@idAntetBon = isnull(@parXML.value('(/row/@idAntetBon)[1]', 'int'),0),
		@dataStart=GETDATE(),
		@eroareTimeout=0

-- in caz exceptional se poate ca idAntetbon sa nu fie salvat in XML. il identific dupa UID.
if @idAntetBon=0
	select @idAntetBon=IdAntetBon from antetBonuri where UID=@UID

if @idAntetBon=0 and @UID is not null or not exists (select * from antetBonuri where idAntetBon=@idAntetBon)
begin
	set @msgEroare='Documentul cautat nu poate fi gasit! '+char(13)+
		'ID bon='+ISNULL(convert(varchar(30),@idAntetBon),'(null)')+char(13)+
		'UID bon='+isnull(@UID,'(null)')
	raiserror(@msgeroare,11,1)
end

-- daca se apeleaza descarcarea pt. linii din antetBonuri care contin facturi simplificate sau bonuri cu rol de incasare sau facturi din bon, nu mai facem nimic
if exists (select * from antetbonuri where idantetbon=@idantetbon and bon is null and not exists (select * from bt where idAntetBon=@idAntetBon))
	return 0

declare @NrLin int, @TipDoc char(2), @AP418 int,@CtFact varchar(13),
	@NrDoc varchar(8), @codIntrareInDenumire int, @idPozContract int, @idJurnalContract int, @xmlTrimis xml,
	@sub varchar(50), @LM varchar(50), @data_facturii datetime, @categpret int
	
declare @devize table (cod_deviz varchar(20), pozitie int primary key(cod_deviz,pozitie))
declare @contracte table (idContract int)

select	@sub=(case when Parametru='SUBPRO' then rtrim(Val_alfanumerica) else isnull(@sub,'') end),
		@codIntrareInDenumire=(case when Parametru='CODIINDEN' then Val_logica else isnull(@codIntrareInDenumire, 0) end)
from par
where Tip_parametru='GE' and Parametru in ('SUBPRO')
	or Tip_parametru='PV' and Parametru = 'CODIINDEN'

/* citesc date de antet document.
IMPORTANT: citirea sa ramana inainte de citirea din par pt ca sa fie citit @gestpv */
select	@TipDoc=a.bon.value('(/date/document/@tipdoc)[1]','varchar(2)'),
		@NrDoc=a.bon.value('(/date/document/@numar_in_pozdoc)[1]','varchar(20)'), -- campul este in XML doar daca descarcarea se apeleaza din refaceri		
		@GestBon=rtrim(gestiune), 
		@vanz=Vinzator, 
		@Casa=a.Casa_de_marcat, 
		@Data=a.Data_bon, 
		@NrBon=a.Numar_bon,
		@factura=case when @TipDoc<>'AP' then null else rtrim(a.factura) end,
		@data_facturii=case when @TipDoc<>'AP' then null else rtrim(a.data_facturii) end,
		@vanz=a.Vinzator, 
		@tert=a.Tert, 
		@dataScad=a.Data_scadentei, 
		@PctLiv=isnull(rtrim(a.punct_de_livrare), ''),
		@LM = rtrim(a.loc_de_munca),
		@categpret = a.Categorie_de_pret,
		@AP418=isnull(a.bon.value('(/date/document/@aviz_nefacturat)[1]','varchar(20)'),0), 
		@CtFact=isnull(a.bon.value('(/date/document/@cont_factura)[1]','varchar(20)'),
					(case when @TipDoc='AP' and @AP418=1 then '418' else null end))
	from antetBonuri a where idAntetBon=@idAntetBon

if @TipDoc is null
	raiserror('Tipul documentului nu poate fi identificat', 16, 1)

begin tran 

set @xmlTrimis=
(select @tipDoc tip, @NrDoc numar, convert(char(10), @Data, 101) data, @Tert tert, @PctLiv punctlivrare, @categpret categpret, 
	@factura factura, @CtFact contfactura, @dataScad datascadentei, @data_facturii datafacturii,'1' fara_mesaje, '1' returneaza_inserate,
	(
	select 
		rtrim(b.cod_produs) cod, 
		case	when @codIntrareInDenumire=1 then nullif(numar_document_incasare,'')
				when detalii is not null then detalii.value('/row[1]/@codintrare','varchar(20)') else null 
			end codintrare,
		convert(decimal(17, 5), b.cantitate) cantitate, 
		convert(decimal(17, 5), b.discount) discount, 
		round(convert(decimal(17, 5), b.pret/(1+b.cota_tva/100.00)),5) pvaluta,
		round(convert(decimal(17, 5), (b.total-b.tva)/b.cantitate),5) pret_vanzare,
		convert(decimal(17, 2), round(b.total/b.cantitate,2)) pamanunt,
		b.gestiune as gestiune,
		convert(decimal(17, 5), b.tva) as sumatva, 
		convert(decimal(12,2),b.cota_tva) as cotatva, 
		isnull(b.lm_real, nullif(rtrim(a.loc_de_munca),'')) as lm, 
		rtrim(b.vinzator) as utilizator,
		isnull(rtrim(b.contract), a.contract) as contract,
		isnull(rtrim(b.comanda_asis), a.comanda) as comanda,
		b.idPozContract idPozContract,
		b.idPozContract idlinie	
	from bt b, antetBonuri a 
	where a.idAntetBon=@idAntetBon and a.IdAntetBon=b.idAntetBon
	and b.tip in ('11','21') and b.cod_produs<>'' -- doar produse
	for xml raw, type)

for xml raw)
--select @xmlTrimis
if exists (select * from sysobjects where name ='wScriuDoc')
	exec wScriuDoc @sesiune=@sesiune, @parXML=@xmlTrimis OUTPUT
else 
if exists (select * from sysobjects where name ='wScriuDocBeta')
	exec wScriuDocBeta @sesiune=@sesiune, @parXML=@xmlTrimis OUTPUT
else 
	raiserror('Eroare configurare PVria: procedura wDescarcDocPv necesita folosirea procedurii wScriuDoc(beta). Stergeti aceasta procedura sau folositi wScriuDoc', 16, 1)
	
if @TipDoc='AP' and exists(select * from bt where idAntetBon=@idAntetBon and left(tip,1)='3') -- facturi cu incasari
begin
	update bt  -- la facturi cu incasari, salvam date in detalii
		set detalii='<row />'
	where idAntetBon=@idAntetBon and left(tip,1)='3' and (detalii is null or convert(varchar(max),detalii)='')

	declare @prop table(cod varchar(50), val varchar(50))
	
	insert into @prop(cod, val)
	select Cod_proprietate, rtrim(valoare) cont
	from proprietati p
	where p.tip='UTILIZATOR' 
	and cod=@Vanz 
	and Cod_proprietate in ('CONTCARD', 'CONTPUNCTE', 'CONTCASA')
	and valoare<>''
		
	declare @conturi table(tip varchar(50), cont varchar(50))
	insert into @conturi(tip)
	select distinct tip 
	from bt
	where idAntetBon=@idAntetBon and left(tip,1)='3'
		
	update c
		set cont = case when c.tip='36' then isnull((select val from @prop where cod='CONTCARD'),'5114') 
						when c.tip='37' then isnull((select val from @prop where cod='CONTPUNCTE'),'609')
						else isnull((select val from @prop where cod='CONTCASA'),'5311') end
	from @conturi c
		
	update t
		set detalii.modify('insert attribute cont {sql:column("cont")} into /row[1]')
	from bt t, @conturi c
	where idAntetBon=@idAntetBon 
	and t.Tip=c.tip -- in @conturi e filtrat tipul deja
	and detalii.value('/row[1]/@cont','varchar(50)') is null

	declare @denTert varchar(80),@nr_poz_out int, @numarDocIncasare varchar(20), @tipIncasariPeFacturi int
	set @denTert=ISNULL(rtrim((select top 1 denumire from terti where tert=@tert)),'')
	exec luare_date_par 'PV', 'INCPEFACT', 0, @tipIncasariPeFacturi output, ''
		
	select @CtFact=rtrim(Cont_factura)
	from pozdoc p 
	where p.Subunitate=@sub and p.Tip=@TipDoc and p.Numar=@NrDoc and p.Data=@Data
		
	/*Stergem liniile generate eventual anterior*/
	delete from pozplin where Subunitate=@sub and Plata_incasare='IB' and data=@data and tert=@tert and factura=@factura and Explicatii=@denTert
		
	declare @contCasa varchar(50), @tip varchar(50)

	while exists (select * from @conturi)
	begin
		-- folosim bucla while pt. ca nu stiu sigur daca wScriuPozplin permite mai multe conturi in antet 
		-- -> de corectat
		select top 1	@contCasa=cont,
						@tip = tip
		from @conturi

		-- verific valoarea din bt.numar_doc_incasare
		-- salvez acolo numarul de chitanta, pentru cand se reapeleaza din refaceri.
		select @numarDocIncasare=Numar_document_incasare
		from bt
		where idAntetBon=@idAntetBon and tip=@tip
		
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
				
			update bt 
				set Numar_document_incasare = @numarDocIncasare
			where idAntetBon=@idAntetBon and tip=@tip
		end
			
		set @xml=
			(select 'RE' as tip, @contCasa as cont, convert(char(10),@data,101) as data,
				(select 'IB' as subtip, @tert as tert, @numarDocIncasare as numar, @CtFact as contcorespondent,
					@denTert as explicatii, @LM as lm, @vanz as utilizator, @factura as factura,
					pret as suma
				from bt
				where idAntetBon=@idAntetBon and tip=@tip
				for xml raw, type) 
			for xml raw)
		exec wScriuPozplin @sesiune=@sesiune, @parXML=@xml

		delete from @conturi where cont=@contCasa
	end
end

insert bp(Casa_de_marcat, Factura_chitanta, Numar_bon, Numar_linie, Data, Ora, Tip, Vinzator, Client, 
	Cod_citit_de_la_tastatura, CodPLU, Cod_produs, Categorie, UM, Cantitate, Cota_TVA, Tva, Pret, Total, Retur, 
	Inregistrare_valida, Operat, Numar_document_incasare, Data_documentului, Loc_de_munca, Discount, 
	lm_real, Comanda_asis,[Contract], idAntetBon, idPozContract, detalii)
select Casa_de_marcat, Factura_chitanta, Numar_bon, Numar_linie, Data, Ora, Tip, Vinzator, Client, 
	Cod_citit_de_la_tastatura, CodPLU, Cod_produs, Categorie, UM, Cantitate, Cota_TVA, Tva, Pret, Total, Retur, 
	Inregistrare_valida, Operat, Numar_document_incasare, Data_documentului, Loc_de_munca, Discount, 
	lm_real, Comanda_asis,[Contract], idAntetBon, idPozContract, detalii
from bt where idantetbon=@idantetbon

delete from bt where idantetbon=@idantetbon

commit tran	

/* Aceasta procedura realizeaza scrierea legaturilor */
if exists (select 1 from sysobjects where type='P' and name='wOPTrateazaLegaturiSiStariContracte')
BEGIN
	declare 
		@ddoc int, @xml_proc xml

	EXEC sp_xml_preparedocument @ddoc OUTPUT, @xmlTrimis

	create table #Legaturi (a bit)
	exec CreazaDiezLegaturi

	insert into #Legaturi (idPozContract, idPozDoc)
	-- In acest caz idlinie catre wScriuDoc a fost trimis IdPozContract
	SELECT idlinie, idPozDoc
	FROM OPENXML(@ddoc, '/row/docInserate/row')
	WITH
	(	idLinie int '@idlinie',
		idPozDoc	int '@idPozDoc'
	)
	EXEC sp_xml_removedocument @ddoc 

	/*Procedura care trateaza jurnalizarea si scrierea legaturilor*/
	set @xml_proc= (select 'Vanzare PVria ('+(case @TipDoc when 'AP' then 'Factura' when 'AC' then 'Bon' when 'TE' then 'Transfer' else @TipDoc end)+')' explicatii for xml raw)
	exec wOPTrateazaLegaturiSiStariContracte @sesiune=@sesiune, @parXML=@xml_proc
END

/* Aceasta procedura trateaza comenzile HORECA  */
if exists (select 1 from sysobjects where type='P' and name='wDefinitivareComandaRestaurant')
begin
	set @xml=(select @idAntetBon idAntetBon for xml raw)
	exec wDefinitivareComandaRestaurant @sesiune=@sesiune, @parXML=@xml
end

 /* Apelare procedura specifica care sa faca alte operatii */
if exists (select 1 from sysobjects where type='P' and name='wDescarcDocPvSP2')
begin
	set @xml=(select @idAntetBon idAntetBon for xml raw)
	exec wDescarcDocPvSP2 @sesiune=@sesiune, @parXML=@xml
end

/* Apelare procedura care sa trateze puncte de fidelizare */
if exists (select 1 from sysobjects where type='P' and name='CalculPuncteBon')
begin
	set @xml=(select @idAntetBon idAntetBon for xml raw)
	exec CalculPuncteBon @sesiune=@sesiune, @parXML=@xml
end

end try
begin catch
	set @msgEroare = ERROR_MESSAGE()+'. (idAntetBon='+convert(varchar,isnull(@idantetbon,0))+') (wDescarcDocPv)'
	if @@trancount>0
		rollback tran
end catch

if len(@msgEroare)>0
	raiserror(@msgeroare,11,1)
