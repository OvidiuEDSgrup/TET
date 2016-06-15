
/** Procedura luare date firma din tabela terti sau din tabela par pentru toate formularele standard care necesita date despre firma in functie de un set de locuri de munca
	Din terti daca:
		- codul fiscal primit in @parXML exista in tabela terti
	Din par daca:
		- codul fiscal e null
		- codul fiscal nu se gaseste in tabela terti

	Procedura se bazeaza pe existenta tabelei temporare #dateFirma --> se va apela doar in acest caz
 */
CREATE PROCEDURE wDateFirma @locm varchar(50) =null
AS
declare @eroare varchar(max)
select @eroare=''
BEGIN try
	if object_id('tempdb..#datefirma') is null 
	begin
		create table #datefirma(locm varchar(50))
		exec wDateFirma_tabela
	end
/*
	if not exists (select 1 from tempdb.sys.columns c where c.object_id=object_id('tempdb..#datefirma') and name='locm')
		alter table #datefirma add locm varchar(50) default null, locm*/

	--> sa mearga si ca si pana acum:
	if (select count(1) from #datefirma)=0
		insert into #datefirma(locm) select @locm
	
	update #datefirma set locm_proprietate=locm
		
	DECLARE @codFiscalFirma varchar(50), @inTerti bit, @capitalSocial varchar(50)

	/** Daca se vrea prelucrarea locului de munca ..ex: LEFT(@locm, 1) */
	IF EXISTS (SELECT 1 FROM sys.sysobjects WHERE name = 'wDateFirmaSP')
		EXEC wDateFirmaSP @locm = @locm OUTPUT

	--> luare coduri fiscale pe locuri de munca:
	update d set codfiscal=rtrim(p.valoare)
	from #datefirma d inner join proprietati p on p.tip='LM' and d.locm_proprietate=p.cod and p.cod_proprietate='CODFISCAL'
	
	--> luare cod fiscal pentru locuri de munca fara proprietate - cel din par; se ia separat deoarece s-ar putea sa se regaseasca datele firmei in terti:
	update d set codfiscal=rtrim(p.Val_alfanumerica)
	from #datefirma d --inner join proprietati p on p.tip='LM' and d.locm=p.cod and p.cod_proprietate='CODFISCAL'
		, par p
	where p.tip_parametru = 'GE'
		AND p.parametru='CODFISC'
		and isnull(d.codfiscal,'')=''
/*	
	SELECT TOP 1 @codFiscalFirma = RTRIM(Valoare) FROM proprietati WHERE Tip = 'LM' AND Cod = @locm AND Cod_proprietate = 'CODFISCAL'
	SET @inTerti = 0
*/	SELECT @capitalSocial = RTRIM(Val_alfanumerica) FROM par WHERE Tip_parametru = 'GE' AND Parametru = 'CAPITALS'
/*
	IF EXISTS (SELECT 1 FROM terti WHERE (tert = @codFiscalFirma OR Cod_fiscal = @codFiscalFirma))
		SET @inTerti = 1
	
	/** Daca exista terti cu cod fiscal = '' sau tert = '' */
	IF ISNULL(@codFiscalFirma, '') = ''
		SET @inTerti = 0

	/** Luam datele din par */
	IF ISNULL(@codFiscalFirma, '') = '' OR @inTerti = 0
	BEGIN
		DECLARE @firma varchar(200), @cui varchar(50), @ordreg varchar(50), @judet varchar(100), @sediu varchar(150),
			@adresa varchar(300), @cont varchar(50), @banca varchar(100), @telfax varchar(100)

		SELECT @firma = RTRIM(Val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'NUME'
		SELECT @cui = RTRIM(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'CODFISC'
		SELECT @ordreg = RTRIM(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'ORDREG'
		SELECT @judet = RTRIM(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'JUDET'
		SELECT @sediu = RTRIM(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'SEDIU'
		SELECT @adresa = RTRIM( val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'ADRESA'
		SELECT @cont = RTRIM(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'CONTBC'
		SELECT @banca = RTRIM(val_alfanumerica) FROM par WHERE Tip_parametru = 'GE' AND Parametru = 'BANCA'
		SELECT @telfax = RTRIM(Val_alfanumerica) FROM par WHERE Tip_parametru = 'GE' AND Parametru = 'TELFAX'

		INSERT INTO #dateFirma (codFiscal, firma, ordreg, judet, sediu, adresa, cont, banca, capitalSocial, telfax)
		SELECT @cui, @firma, @ordreg, @judet, @sediu, @adresa, @cont, @banca, @capitalSocial, @telfax
	END
	*/
	--> completare informatii pentru coduri fiscale care nu se regasesc in terti:
	update d 
	set firma = par.firma
		,codfiscal = par.codfiscal	--> daca nu e definit vreun cod fiscal din proprietati se va trece inapoi pe cel default - al firmei
		,ordreg = par.ordreg
		,judet = par.judet
		,sediu = par.sediu
		,adresa = par.adresa
		,cont = par.cont
		,banca = par.banca
		,telfax = par.telfax
		,capitalSocial=@capitalSocial
	from #dateFirma d,
		(select max(RTRIM(case when parametru='NUME' then Val_alfanumerica else '' end)) firma
				,max(RTRIM(case when parametru='CODFISC' then Val_alfanumerica else '' end)) codfiscal
				,max(RTRIM(case when parametru='ORDREG' then Val_alfanumerica else '' end)) ordreg
				,max(RTRIM(case when parametru='JUDET' then Val_alfanumerica else '' end)) judet
				,max(RTRIM(case when parametru='SEDIU' then Val_alfanumerica else '' end)) sediu
				,max(RTRIM(case when parametru='ADRESA' then Val_alfanumerica else '' end)) adresa
				,max(RTRIM(case when parametru='CONTBC' then Val_alfanumerica else '' end)) cont
				,max(RTRIM(case when parametru='BANCA' then Val_alfanumerica else '' end)) banca
				,max(RTRIM(case when parametru='TELFAX' then Val_alfanumerica else '' end)) telfax
			from par WHERE par.tip_parametru = 'GE'
				AND par.parametru in ('NUME', 'CODFISC', 'ORDREG', 'JUDET', 'SEDIU', 'ADRESA', 'CONTBC', 'BANCA', 'TELFAX')) par
		where not exists (select 1 from terti t where isnull(d.codfiscal,'')<>'' and (t.tert = d.codfiscal OR t.Cod_fiscal = d.codfiscal))
	
	/** Luam datele din terti */
	update d set codFiscal=RTRIM(ISNULL(t.tert, t.Cod_fiscal)), firma=RTRIM(t.Denumire), ordreg=RTRIM(it.Banca3),
		judet=RTRIM(ISNULL(j.denumire, t.Judet)), sediu=RTRIM(ISNULL(l.oras, t.Localitate)),
		adresa=RTRIM(t.Adresa), cont=RTRIM(t.Cont_in_banca), banca=RTRIM(ISNULL(b.Denumire, t.Banca)),
		capitalSocial=isnull(t.detalii.value('(/row/@capital)[1]', 'varchar(20)'), @capitalSocial), telfax=RTRIM(t.Telefon_fax)
	from #dateFirma d
		inner join terti t on t.Tert=d.codfiscal or d.codfiscal=t.cod_fiscal
		LEFT JOIN infotert it ON it.Subunitate = t.Subunitate AND it.Tert = t.Tert AND it.Identificator = ''
		LEFT JOIN Judete j ON j.cod_judet = t.Judet
		LEFT JOIN Localitati l ON l.cod_oras = t.Localitate
		LEFT JOIN bancibnr b ON b.Cod = t.Banca
/*
	IF @inTerti = 1
	BEGIN
		INSERT INTO #dateFirma (codFiscal, firma, ordreg, judet, sediu, adresa, cont, banca, capitalSocial, telfax)
		SELECT RTRIM(ISNULL(t.tert, t.Cod_fiscal)), RTRIM(t.Denumire), RTRIM(it.Banca3),
			RTRIM(ISNULL(j.denumire, t.Judet)), RTRIM(ISNULL(l.oras, t.Localitate)),
			RTRIM(t.Adresa), RTRIM(t.Cont_in_banca), RTRIM(ISNULL(b.Denumire, t.Banca)),
			@capitalSocial, RTRIM(t.Telefon_fax)
		FROM terti t
		LEFT JOIN infotert it ON it.Subunitate = t.Subunitate AND it.Tert = t.Tert AND it.Identificator = ''
		LEFT JOIN Judete j ON j.cod_judet = t.Judet
		LEFT JOIN Localitati l ON l.cod_oras = t.Localitate
		LEFT JOIN bancibnr b ON b.Cod = t.Banca
		WHERE (t.Tert = @codFiscalFirma OR t.Cod_fiscal = @codFiscalFirma)
	END
*/
	--select * from #dateFirma
END try
begin catch
	select @eroare=ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
end catch

if len(@eroare)>0 raiserror(@eroare,16,1)
