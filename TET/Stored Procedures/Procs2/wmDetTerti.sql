
CREATE procedure wmDetTerti @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmDetTertiSP' and type='P')
begin
	exec wmDetTertiSP @sesiune, @parXML 
	return 0
end

set transaction isolation level READ UNCOMMITTED
declare @cod varchar(100), @utilizator varchar(30), @wIaComenziCod varchar(30), @punctlivrare varchar(30),
		@idpunctlivrare varchar(30),@AdrComp int, @subunitate varchar(9), @raspuns varchar(max),
		@comandaDeschisa varchar(20), @stareBkFacturabil varchar(20), @gestiuneDepozitBK varchar(20)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
if @utilizator is null
	return -1

	SELECT @gestiuneDepozitBK= dbo.wfProprietateUtilizator('GESTDEPBK',@utilizator)

select	@subunitate=(case when Parametru='SUBPRO' then rtrim(Val_alfanumerica) else @subunitate end),
		@AdrComp=(case when Parametru='ADRCOMP' then Val_logica else @AdrComp end),
		@stareBkFacturabil=(case when Parametru='STBKFACT' then rtrim(Val_alfanumerica) else @stareBkFacturabil end)
from par where (Tip_parametru='GE' and Parametru in ('SUBPRO', 'ADRCOMP')) or (Tip_parametru='UC' and Parametru = 'STBKFACT')

select	@cod=@parXML.value('(/row/@tert)[1]','varchar(20)'),
		@idPunctLivrare=@parXML.value('(/row/@pctliv)[1]','varchar(100)')

-- iau denumire punct livrare...
select	@punctlivrare=(select descriere from infotert where Subunitate=@subunitate and tert=@cod and identificator=@idpunctlivrare)	

-- reinitializare incasare suma
delete from proprietati where Tip='U' and Cod=@utilizator and Cod_proprietate='IncasareSuma'

-- identific daca are comanda deschisa => presupun ca are doar una in stare 0 -> poate se va schimba...
select top 1 @comandaDeschisa=idContract
	from (
			select
				c.idContract,jc.stare, jc.utilizator, RANK() over (order by jc.data desc, jc.idJurnal desc) rn
			from Contracte c
			JOIN JurnalContracte jc on jc.idContract=c.idContract 
			where tip='CL' and tert = @cod and (@idPunctLivrare is null or @idPunctLivrare=c.punct_livrare)
		) cst where	cst.stare='0' and cst.utilizator=@utilizator and cst.rn=1

set @raspuns='<Date>'+CHAR(13)

declare @areMeniu int -- Variabila folosita pentru a vedea daca are un meniu sau nu
/*Sold beneficiar*/
exec wAreMeniuMobile 'SB',@utilizator,@areMeniu output
	if @areMeniu=1	-- linie cu soldul beneficiarului
		set @raspuns=@raspuns+
		isnull((select 'SB' as cod,'0xffffff' as culoare,'assets/Imagini/Meniu/sold.png' as poza,
			'Sold b: '/*beneficiar*/+isnull(convert(varchar(20),convert(money,SUM(ff.sold),2),1),'0')+' RON' as denumire,null as procdetalii,
			'C' as tipdetalii
			from facturi ff
				left join doc d on d.subunitate=ff.subunitate and d.cod_tert=ff.tert and d.factura=ff.factura and d.data_facturii=ff.data and d.tip ='AP'
			where ff.tip=0x46 and ff.tert=@cod 
				and (d.gestiune_primitoare=@idPunctLivrare or isnull(@idPunctLivrare,'')='' or isnull(d.gestiune_primitoare,'')='')
			
		for xml raw ),'')+char(13)
	
/*Sold furnizor*/
exec wAreMeniuMobile 'SF',@utilizator,@areMeniu output
	if @areMeniu=1
		set @raspuns=@raspuns+isnull((select 'SF' as cod,'0xffffff' as culoare,'assets/Imagini/Meniu/sold.png' as poza,
			'Sold f: '/*furnizor*/+isnull(convert(varchar(20),convert(money,SUM(ff.sold),2),1),'0')+' RON' as denumire,null as procdetalii,
			'C' as tipdetalii
			from facturi ff
			where ff.tip=0x54 and ff.tert=@cod and 
					(@idpunctlivrare='' or exists (select 1 from incfact i where i.Serie_doc=@idpunctlivrare and
													i.tert=ff.tert and i.Numar_factura=ff.factura))
			--having sum(ff.sold) is not null
		for xml raw ),'')+char(13)

/*comanda deschisa*/
exec wAreMeniuMobile 'CD',@utilizator,@areMeniu output
	if @areMeniu=1
	set @raspuns=@raspuns+
	isnull((select @comandaDeschisa cod, '0xffffff' culoare, 'assets/Imagini/Meniu/comanda.png' as poza,
		'Comanda deschisa' denumire,
		'wmComandaLivrare' as procdetalii, 'C' as tipdetalii, '@comanda' as numeatr
	for xml raw ),'')+char(13)
	
/*Comenzi in depozit*/
declare @nr_comenzi_depozit int

select @nr_comenzi_depozit=count(1)
from 
	(
		select c.idContract
		from Contracte c
		JOIN
			(select
				jc.idContract, RANK() OVER (PARTITION by jc.idContract order by jc.data DESC, jc.idJurnal desc) rn, jc.stare, jc.utilizator
			from JurnalContracte jc 
			) st
		ON c.idContract=st.idContract and st.rn=1 and st.stare=@stareBkFacturabil and c.tert=@cod and st.utilizator=@utilizator and c.gestiune=@gestiuneDepozitBK
	) a
exec wAreMeniuMobile 'CF',@utilizator,@areMeniu output
	if @areMeniu=1
	set @raspuns=@raspuns+isnull((select @stareBkFacturabil cod, '@stare' numeatr,
		'Comenzi in depozit:'+convert(varchar,isnull((@nr_comenzi_depozit),0))  denumire,
		'wmIaComenzi' as procdetalii, 'C' as tipdetalii, 
		'0xffffff' culoare, 'assets/Imagini/Meniu/facturi.png' as poza,
		@gestiuneDepozitBK gestiuneDepozitBK, '1' _toateAtr
	for xml raw ),'')+char(13)
	
/*Incasare (facturi si/sau suma)*/
exec wAreMeniuMobile 'IF',@utilizator,@areMeniu output
	if @areMeniu=1
	set @raspuns=@raspuns+isnull((select 'IF' as cod,'0xffffff' as culoare,'assets/Imagini/Meniu/incasari.png' as poza,
		'Incasare' as denumire,(select convert(varchar(5),count(1)) from facturi ff 
		left join doc d on d.subunitate=ff.subunitate and d.cod_tert=ff.tert and d.factura=ff.factura and d.data_facturii=ff.data and d.tip ='AP'
			where ff.tip=0x46 and ff.tert=@cod 
				and (d.gestiune_primitoare=@idPunctLivrare or isnull(@idPunctLivrare,'')='' or isnull(d.gestiune_primitoare,'')='')
		and ff.tip=0x46 and ff.sold>0.05)+' facturi in sold' as info,
		'wmDetaliiIncasare' as procdetalii,'C' as tipdetalii
	for xml raw ),'')+char(13)

	
-- linie persoane de contact
exec wAreMeniuMobile 'PC',@utilizator,@areMeniu output
	if @areMeniu=1
	set @raspuns=@raspuns+isnull((select 'PC' as cod,'0xffffff' as culoare,'assets/Imagini/Meniu/Raportare.png' as poza,
			'Persoane de contact:'+ltrim(str(isnull((select count(*) from infotert it where it.subunitate='C1' and it.tert=@cod),0))) as denumire,
		'wmIaPersoaneContact' as procdetalii,'C' as tipdetalii, 1 as toateAtr
	for xml raw ),'')+char(13)
	

-- linie detalii firma
exec wAreMeniuMobile 'DF', @utilizator, @areMeniu output
if @areMeniu=1
set @raspuns=@raspuns+isnull(
	(select 
			'DF' as cod, 'Detalii firma' denumire,
			'assets/Imagini/Meniu/salarii3.png' as poza,
			rtrim(t.Tert) as cod_tert, rtrim(t.Denumire) as denumire_tert,rtrim(t.Cod_fiscal) as cod_fiscal,
			rtrim(it.Banca3) as nr_reg_com,
			rtrim(t.Localitate) as localitate,rtrim(t.Judet) as judet,rtrim(t.Adresa) as adresa,
			rtrim(t.Telefon_fax) as telefon_fax,
			rtrim(t.Banca) as banca,rtrim(t.Cont_in_banca) as cont_in_banca, RTRIM(CONVERT(varchar,it.discount)) as zilescad,
			convert(int,Sold_ca_beneficiar) as categorie_pret,
			'D' as tipdetalii, 'wmScriuDetaliiFirma' as procdetalii
		from terti t
		left join infotert it on  it.Subunitate=@subunitate and it.Tert=t.Tert and it.Identificator=''
		where t.subunitate=@subunitate and t.Tert = @cod
		for xml raw
	),'')+char(13)
	
--linie harta tert
exec wAreMeniuMobile 'HA',@utilizator,@areMeniu output
	if @areMeniu=1
	set @raspuns=@raspuns+isnull((select 'HA' as cod,'0xffffff' as culoare,'assets/Imagini/Meniu/harta.png' as poza,'Harta zona' as denumire,
		(case when @AdrComp=0 then ltrim(rtrim(t.adresa))+','+LTRIM(RTRIM(t.localitate))+',Romania' 
			when @AdrComp=1 then 
				rtrim(substring(t.adresa, 31, 8))+','+rtrim(left(t.adresa, 30))+','+
					isnull(l.oras, t.localitate)+',Romania'
			end) as procdetalii,
			'M' as tipdetalii
	from terti t
	left join localitati l on l.cod_judet=t.judet and l.cod_oras=t.localitate
	where t.tert=@cod
	for xml raw ),'')+char(13)
	
-- linie situatii
exec wAreMeniuMobile 'ST',@utilizator,@areMeniu output
	if @areMeniu=1
	set @raspuns=@raspuns+isnull((select 'ST' as cod,'0xffffff' as culoare,'assets/Imagini/Meniu/situatii.png' as poza,'Situatii ultima luna' as denumire,
		'wmSituatiiTerti' as procdetalii,'C' as tipdetalii
		for xml raw ),'')+char(13)

-- linie activitati CRM
exec wAreMeniuMobile 'AT', @utilizator, @areMeniu output
	if @areMeniu=1
	set @raspuns = @raspuns + isnull((select 'AT' as cod, '0xffffff' as culoare,'assets/Imagini/Meniu/harta.png' as poza,
		'Sarcini/Activitati' as denumire, 'wmIaSarciniCRM' as procdetalii,
		'C' as tipdetalii, 1 as toateAtr for xml raw), '') + char(13) 

set @raspuns=@raspuns+'</Date>'
	
select convert(xml,@raspuns)

set @punctlivrare=(case when rtrim(isnull(@punctlivrare,''))='' then '' else ' - '+@punctlivrare end)

select	rtrim(denumire)+isnull(@punctlivrare,'') as titlu,
		0 as areSearch, 
		'wmDateTerti' as detalii, 'D' as tipdetalii,
		dbo.f_wmIaForm('AC') as form -- pentru detalii firma - cand se va putea trimite form pe fiecare linie, se poate muta acolo.
from terti where tert=@cod and subunitate=@subunitate
for xml raw,Root('Mesaje')
