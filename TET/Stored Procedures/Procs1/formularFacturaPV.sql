-- procedura pentru generarea facturilor din bon pentru PVria.
create procedure formularFacturaPV @sesiune varchar(50), @parXML xml, @numeTabelTemp varchar(100) output
as
set transaction isolation level read uncommitted 

declare @casam int, @eBon bit, @numarBon int, @factura varchar(50), @dataFacturii datetime, @tert varchar(50),
	@DISCOUNT decimal(12,2),@total decimal(12,2),@tvatotal decimal(12,2),@totaltva decimal(12,2), @unitate varchar(200),
	@CUI varchar(200),@ORDREG varchar(200),@JUD varchar(200),@ADR varchar(200),@CT varchar(200),@BC varchar(200), @cTextSelect nvarchar(max), 
	@codfiscal varchar(50), @orcc varchar(50), @judet varchar(50), @adresaTert varchar(500), @contTert varchar(50),
	@bancaTert varchar(50), @delegat varchar(100), @serieCI varchar(50), @numarCI varchar(50), @elieratCI varchar(50),
	@denTert varchar(200), @idPunctLivrare varchar(100), @denPunctLivrare varchar(100), @facturaDinBon bit, @debug bit,
	@totalFaraDiscount decimal(12,2), @vanzator varchar(20), @CNP varchar(20), @numeVanzator varchar(200), @auto varchar(50),
	@cDataExp char(10), @oraExp varchar(10), @dataScadentei datetime, @observatii varchar(8000), @tva_discountat decimal(12,2), @doc xml,
	@eFactura bit, @eTransfer bit, @tipDoc char(2), @adresaGestiunePrimitoare varchar(1000), @adresaGestiunePredatoare varchar(1000), @subunitate varchar(20),
	@gestiune varchar(50), @gestiunePrimitoare varchar(50), @dengestiune varchar(100), @denGestiunePrimitoare varchar(100), @idAntetBon int

begin try

select	@tert = isnull(@parXML.value('(/row/@tert)[1]','varchar(20)'),''), 
		@dataFacturii= convert(datetime,
							isnull(@parXML.value('(/row/@data_facturii)[1]','varchar(20)'), -- cand proc. e apelata din macheta de bonuri
										@parXML.value('(/row/@data)[1]','varchar(20)')) ,101), -- cand proc. e apelata din PVria
		@factura=isnull(@parXML.value('(/row/@factura)[1]','varchar(50)'),''),
		@debug = isnull(@parXML.value('(/row/@debug)[1]','bit'),0)

if isnull(@factura,'')=''
begin 
	raiserror('Bonul nu are atasat factura!',16,1) 
	return -1
end

IF OBJECT_ID('tempdb..#pozitii') IS NOT NULL
	drop table #pozitii
IF OBJECT_ID('tempdb..#selectFinal') IS NOT NULL
	drop table #selectFinal

select	@subunitate=(case when parametru='SUBPRO' then rtrim(val_alfanumerica) else isnull(@subunitate,'') end),
		@unitate=(case when parametru='NUME' then rtrim(val_alfanumerica) else isnull(@unitate,'') end),
		@cui=(case when parametru='CODFISC' then rtrim(val_alfanumerica) else isnull(@cui,'') end),
		@ORDREG=(case when parametru='ORDREG' then rtrim(val_alfanumerica) else isnull(@ORDREG,'') end),
		@JUD=(case when parametru='JUDET' then rtrim(val_alfanumerica) else isnull(@JUD,'') end),
		@ADR=(case when parametru='ADRESA' then rtrim(val_alfanumerica) else isnull(@ADR,'') end),
		@CT=(case when parametru='CONTBC' then rtrim(val_alfanumerica) else isnull(@CT,'') end),
		@BC=(case when parametru='BANCA' then rtrim(val_alfanumerica) else isnull(@BC,'') end)
from par 
where Tip_parametru='GE' and Parametru in ('SUBPRO', 'NUME', 'CODFISC', 'ORDREG', 'JUDET', 'ADRESA', 'CONTBC', 'BANCA')

-- iau date de antet
select @casam=a.Casa_de_marcat, @numarBon=a.Numar_bon, @vanzator=rtrim(a.Vinzator),
	@tert=a.tert, @idPunctLivrare=a.Punct_de_livrare, @dataScadentei=a.Data_scadentei,
	@gestiune=a.Gestiune, @doc=a.Bon, @idAntetBon=a.IdAntetBon
from antetbonuri a
where a.Factura=@factura and a.Data_facturii=@dataFacturii and a.Chitanta=0

set @tipDoc=@doc.value('(/date/document/@tipdoc)[1]','char(2)')
if @tipDoc='TE'
	set @eTransfer=1
else if @tipDoc='AP'
	set @eFactura=1
else if @tipDoc='AC'
	set @eBon=1

-- iau pozitiile de pe pozitiile aferente facturii
select
	CONVERT(varchar(30), MAX(b.Cota_TVA))+'%' as TVA, -- cota tva afisata
	row_number() over (order by b.cod_produs) as NRCRT,
	rtrim(b.cod_produs) as COD,
	left(convert(char(16),convert(money,round(sum(b.cantitate),3)),2),15) as CANT,
	convert(decimal(7,2), MAX(b.Discount)) as procentDiscount,
	convert(decimal(19,5), round(avg(round((b.Total - b.Tva)/b.Cantitate,5)),5)) as PRET_TMP,
	convert(decimal(15,2), round(sum(round(b.Total-b.Tva,2)),2)) as VALOARE_TMP,
	convert(decimal(15,2), round(sum(round((b.total-b.tva)*Discount/(100-Discount),2)),2)) as DISCOUNTPOZ,
	convert(decimal(15,2), round(sum(round(b.tva*Discount/(100-Discount),2)),2)) as tva_discountat_poz,
	convert(decimal(15,2), round(sum(round(b.Tva,2)),2)) as TVAPOZ_TMP,
	b.um
into #pozitii
FROM bonuri b,antetBonuri a
WHERE 
	a.idAntetBon=b.idAntetBon
	and b.Tip = (case when @eTransfer=1 then '11' else '21' end) 
and a.Factura=@factura and a.Data_facturii=@dataFacturii 
	/*se face filtru pe factura(nu pe idAntetBon) pt. ca sa functioneze si la facturi fiscale, dar si la facturi din bonuri
	la facturi din bon, este un idAntetBon pt. factura si cate unul pt. fiecare bon. */
GROUP BY a.Data_facturii, a.Factura, a.tert, b.Cod_produs, b.pret,b.um
having sum(b.cantitate)<>0

-- calculez totaluri
select 
	@total=sum(VALOARE_TMP),
	@tvatotal=sum(TVAPOZ_TMP),
	@totaltva=sum(VALOARE_TMP+TVAPOZ_TMP),
	@DISCOUNT=sum(DISCOUNTPOZ),
	@totalFaraDiscount=@total+@DISCOUNT,
	@tva_discountat=SUM(tva_discountat_poz)
from #pozitii

select @denTert=RTRIM(t.Denumire), @codfiscal=RTRIM(t.Cod_fiscal), @judet=RTRIM(t.Judet), 
	@adresaTert=RTRIM(t.Adresa), @contTert=RTRIM(t.Cont_in_banca), @bancaTert=rtrim(t.Banca)
from terti t where t.Subunitate=@subunitate and t.Tert=@tert 

-- iau date din infotert
set @orcc=ISNULL((select rtrim(max(banca3)) from infotert it 
	where it.Subunitate=@subunitate and it.Tert=@tert and it.Identificator=''),'')

-- iau punct livrare
set @denPunctLivrare=ISNULL((select rtrim(max(it.Descriere)) from infotert it 
	where it.Subunitate=@subunitate and it.Tert=@tert and it.Identificator=@idPunctLivrare),'')

set @numeVanzator=isnull((select rtrim(nume) from utilizatori u where u.id=@vanzator),'')
set @CNP=isnull(dbo.wfProprietateUtilizator('CNP', @vanzator),'')
set @observatii=dbo.wFaObservatiiBonuri(@factura,@dataFacturii)

-- date delegat
select @delegat='', @serieCI='', @numarCI='', @elieratCI=''
if @eTransfer=1
begin
	select @delegat=RTRIM(ad.Numele_delegatului) , @serieCI=RTRIM(ad.Seria_buletin), @numarCI=RTRIM(ad.Numar_buletin), 
			@elieratCI=RTRIM(ad.Eliberat), @auto=RTRIM(ad.Numarul_mijlocului), @cDataExp=CONVERT(char(10), ad.Data_expedierii, 103),
			@oraExp=replace(SUBSTRING(ad.Ora_expedierii,1,2)+':'+SUBSTRING(ad.Ora_expedierii,3,2)+':'+SUBSTRING(ad.Ora_expedierii,5,2),' ','0')
	from anexadoc ad where ad.Numar=@factura and ad.Subunitate=@subunitate
end
else
begin
	select @delegat=RTRIM(af.Numele_delegatului) , @serieCI=RTRIM(af.Seria_buletin), @numarCI=RTRIM(af.Numar_buletin), 
			@elieratCI=RTRIM(af.Eliberat), @auto=RTRIM(af.Numarul_mijlocului), @cDataExp=CONVERT(char(10), af.Data_expedierii, 103),
			@oraExp=replace(SUBSTRING(af.Ora_expedierii,1,2)+':'+SUBSTRING(af.Ora_expedierii,3,2)+':'+SUBSTRING(af.Ora_expedierii,5,2),' ','0')
	from anexafac af where af.Numar_factura=@factura and af.Subunitate=@subunitate
end

if @eTransfer=1 -- citesc date despre gestiune predatoare si primitoare
begin -- se presupune ca gestiunile au un tert atasat, pentru citire adresa
	-- se citeste adresa tertului respectiv.
	declare @tertPredator varchar(13)
	-- predator
	select	@tertPredator = rtrim(SUBSTRING(gestiuni.Denumire_gestiune,31,13)),
			@dengestiune = RTRIM(Denumire_gestiune)
	from gestiuni 
	where Cod_gestiune=@gestiune
	
	-- poate ar trebui adresa punctului de livrare dar nu se poate salva in ASiSplus
	set @adresaGestiunePredatoare = isnull((
			select rtrim(adresa)+', '+ RTRIM(isnull(l.oras, t.Localitate))+', '+ RTRIM(isnull(j.denumire, t.Judet))
				from terti t 
				left join Judete j on t.Judet=j.cod_judet
				left join Localitati l on l.cod_judet=t.Judet and l.cod_oras=t.Localitate
				where t.Tert=@tertPredator and t.Subunitate=@subunitate
		),'')
	
	-- primitor
	set @gestiunePrimitoare = @doc.value('(/date/document/@gestprim)[1]','char(50)')
	select @denGestiunePrimitoare=RTRIM(denumire_gestiune)
		from gestiuni g 
		where Cod_gestiune=@gestiunePrimitoare
	
	set @adresaGestiunePrimitoare = isnull((
		select rtrim(adresa)+', '+ RTRIM(isnull(l.oras, t.Localitate))+', '+ RTRIM(isnull(j.denumire, t.Judet))
			from terti t 
			left join Judete j on t.Judet=j.cod_judet
			left join Localitati l on l.cod_judet=t.Judet and l.cod_oras=t.Localitate
			where t.Tert=@tert and t.Subunitate=@subunitate
		),'')
end

SELECT p.*, n.denumire DEN,
	convert(char(15),convert(money,p.PRET_TMP),2) as PRET,
	convert(char(15),convert(money,p.VALOARE_TMP),1) as VALOARE,
	convert(char(15),convert(money,p.TVAPOZ_TMP),1) as TVAPOZ,
	convert(char(15),convert(money,@DISCOUNT),1) as discount, 
	convert(char(15),convert(money,@total),1) as total, 
	convert(char(15),convert(money,@tvatotal),1) as tvatotal, 
	convert(char(15),convert(money,@totaltva),1) as totaltva, 
	convert(char(15),convert(money,@totalFaraDiscount),1) as TFDISC, 
	convert(char(15),convert(money,@tva_discountat),1) as tvadiscountat, 
	convert(char(15),convert(money,@tvatotal+@tva_discountat),1) as tvafaradiscount, 
	
	RTRIM(@factura) as FACTURA, @factura as aviz, 
	CONVERT(CHAR(10),@dataFacturii,103) as DATA,
	@observatii as OBS, @idAntetBon idAntetBon,
	@codfiscal as CODFISC, @orcc  as ORCC, @judet as JUDET, 
	@adresaTert as ADRESA, @contTert as CONT, @bancaTert as BANCA,
	@unitate as UNITATE, @CUI as CUI, @ORDREG as ORDREG, @JUD as JUD, @ADR as ADR, @CT as CT, @BC as BC,
	@delegat as DELEG, @serieCI as CI, @numarCI as CIS, @elieratCI as POLITIA,
	@denTert as TERT, @denPunctLivrare as PCTL, @numeVanzator as ION, @auto as AUTO,
	@CNP as CNP, @cDataExp as DAT, @oraExp as ORA, isnull(convert(char(10),@dataScadentei,103),'') DS,
	left((case when p.um=1 then n.UM when p.um=2 then n.UM_1 else n.UM_2 end), 3) as UMASURA,
	-- pentru TE
	@dengestiune as PREDATOR, @adresaGestiunePredatoare as ADRESAPRD,
	@denGestiunePrimitoare as PRIMITOR, @adresaGestiunePrimitoare ADRESAPRM
INTO #selectfinal
from 
#pozitii p
inner join nomencl n on n.cod=p.cod

set @cTextSelect='
SELECT *
into '+@numeTabelTemp+'
from #selectfinal
order by NRCRT
'

exec sp_executesql @statement=@cTextSelect

if exists (select 1 from sysobjects where type='P' and name='formularFacturaPVSP1')
begin
	exec formularFacturaPVSP1 @sesiune=@sesiune, @parXML=@parXML, @numeTabelTemp=@numeTabelTemp output
end

if @debug=1 
begin
	set @cTextSelect='select * from '+@numeTabelTemp
	exec sp_executesql @statement=@cTextSelect
end

end try
begin catch 
	declare @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT
	SELECT @ErrorMessage = ERROR_MESSAGE()+' (formularFacturaPV)', @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
end catch

if LEN(@ErrorMessage)>0
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState )
