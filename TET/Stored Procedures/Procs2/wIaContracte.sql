
CREATE PROCEDURE wIaContracte @sesiune VARCHAR(50), @parXML XML
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

if object_id('tempdb..#diezcontracte') is not null drop table #diezcontracte
if object_id('tempdb..#diezpozcontracte') is not null drop table #diezpozcontracte
if exists (select 1 from sysobjects where [type]='P' and [name]='wIaContracteSP')
begin
	-- SP complementar. Daca se vrea inlocuitor, se va seta @parXML = null
	exec wIaContracteSP @sesiune=@sesiune, @parXML=@parXML
		return 0
end

DECLARE 
	@f_numar VARCHAR(20), @f_gestiune VARCHAR(20), @f_dengestiune VARCHAR(50), @f_gestiune_primitoare VARCHAR(20), 
	@f_dengestiune_primitoare VARCHAR(50), @f_tert VARCHAR(20), @f_dentert VARCHAR(50), @f_lm VARCHAR(20), @f_denlm VARCHAR(50), @idContractCorespondent int,
	@f_stare VARCHAR(20), @f_datajos DATETIME, @f_datasus DATETIME, @idContract INT, @tip VARCHAR(2), @utilizator VARCHAR(100), @sub varchar(100),
	@lista_lm bit, @lista_gestiuni int, @areFiltruClient bit,@f_explicatii VARCHAR(20)


EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @sub OUTPUT

/** Filtru Tip Contract **/
SET @tip = @parXML.value('(/*/@tip)[1]', 'varchar(2)')
SET @f_numar = '%' + @parXML.value('(/*/@f_numar)[1]', 'varchar(20)') + '%'
SET @f_gestiune = '%' + @parXML.value('(/*/@f_gestiune)[1]', 'varchar(20)') + '%'
SET @f_dengestiune = '%' + @parXML.value('(/*/@f_dengestiune)[1]', 'varchar(50)') + '%'
SET @f_gestiune_primitoare = '%' + @parXML.value('(/*/@f_gestiune_primitoare)[1]', 'varchar(20)') + '%'
SET @f_dengestiune_primitoare = '%' + @parXML.value('(/*/@f_dengestiune_primitoare)[1]', 'varchar(50)') + '%'
SET @f_tert = '%' + @parXML.value('(/*/@f_tert)[1]', 'varchar(20)') + '%'
SET @f_dentert = '%' + @parXML.value('(/*/@f_dentert)[1]', 'varchar(50)') + '%'
SET @f_lm = '%' + @parXML.value('(/*/@f_lm)[1]', 'varchar(20)') + '%'
SET @f_denlm = '%' + @parXML.value('(/*/@f_denlm)[1]', 'varchar(50)') + '%'
SET @f_stare = '%' + @parXML.value('(/*/@f_stare)[1]', 'varchar(20)') + '%'
SET @f_datajos = isnull(@parXML.value('(/*/@datajos)[1]', 'datetime'), '01/01/1901')
SET @f_datasus = isnull(@parXML.value('(/*/@datasus)[1]', 'datetime'), '01/01/2901')
SET @idContract = @parXML.value('(/*/@idContract)[1]', 'int')
SET @idContractCorespondent = isnull(@parXML.value('(/*/@idContractCorespondent)[1]', 'int'), 0)
SET @f_explicatii = '%' + @parXML.value('(/*/@f_explicatii)[1]', 'varchar(50)') + '%'

EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

-- daca nu contin valori relevante nu filtrez dupa filtre
if replace(@f_numar, '%', '')=''
	set @f_numar=null
if replace(@f_gestiune, '%', '')=''
	set @f_gestiune=null
if replace(@f_dengestiune, '%', '')=''
	set @f_dengestiune=null
if replace(@f_gestiune_primitoare, '%', '')=''
	set @f_gestiune_primitoare=null
if replace(@f_dengestiune_primitoare, '%', '')=''
	set @f_dengestiune_primitoare=null
if replace(@f_tert, '%', '')=''
	set @f_tert=null
if replace(@f_dentert, '%', '')=''
	set @f_dentert=null
if replace(@f_lm, '%', '')=''
	set @f_lm=null
if replace(@f_denlm, '%', '')=''
	set @f_denlm=null
if replace(@f_stare, '%', '')=''
	set @f_stare=null

select @lista_lm=dbo.f_arelmfiltru(@utilizator)

declare @GestiuniUser table(valoare varchar(9))

insert @GestiuniUser(valoare)
select RTRIM(valoare) from proprietati where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='GESTIUNE' and Valoare<>''

set @lista_gestiuni=0
if exists (select * from @GestiuniUser)
	set @lista_gestiuni=1

declare @clienti table(tert varchar(13) primary key)
insert into @clienti
select RTRIM(valoare)
from proprietati p
where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='CLIENT' and valoare<>''

set @areFiltruClient=isnull((select max(1) from @clienti),0)

SELECT TOP 100 
	ct.idContract idContract, 
	rtrim(ct.tip) AS tip, 
	rtrim(ct.numar) AS numar, 
	convert(VARCHAR(10), ct.data, 101) data, 
	rtrim(ct.tert) AS tert, 
	rtrim(t.denumire) AS dentert, 
	rtrim(ct.punct_livrare) AS punct_livrare, 
	rtrim(it.Descriere) AS denpunct_livrare, 
	rtrim(gestiune) AS gestiune, 
	rtrim(gest.denumire_gestiune) AS dengestiune, 
	rtrim(ct.gestiune_primitoare) AS gestiune_primitoare, 
	rtrim(gestPrim.denumire_gestiune) AS dengestiune_primitoare, 
	rtrim(ct.loc_de_munca) AS lm, 
	rtrim(lm.denumire) AS denlm, 
	rtrim(ct.valuta) AS valuta, 
	rtrim(isnull(isnull(v.Denumire_valuta,ct.valuta),'RON')) AS denvaluta, 
	convert(DECIMAL(15, 4), ct.curs) AS curs, 
	convert(VARCHAR(10), ct.valabilitate, 101) valabilitate, 
	rtrim(ct.explicatii) AS explicatii, 
/*	------> cod vechi anterior procedurii wTvaContracte; daca totul e bine se poate sterge:
	pozitii.nr,
	*/
	convert(int,0) nr,
	convert(int,0) AS pozitii, 
	rtrim(st.stare) AS stare, 
	ct.detalii AS detalii, 
	st.culoare AS culoare, 
	rtrim(st.denstare) AS denstare, 
/*	------> cod vechi anterior procedurii wTvaContracte; daca totul e bine se poate sterge:
	convert(DECIMAL(15, 2), pozitii.valoare) AS valoare,
	convert(DECIMAL(15, 2), pozitii.valoarePV) AS valoarePV,
	convert(DECIMAL(15, 2), pozitii.totalcutva)	AS totalcutva,
	convert(DECIMAL(15, 2), pozitii.valoare*(case when isnull(ct.valuta,'')<>'' then ct.curs else 1 end)) AS valoareRON,
	convert(DECIMAL(15, 2), pozitii.cantitate) AS cantitate,
*/	
	convert(decimal(15,2),0) valoare, convert(decimal(15,2),0) valoarePV, convert(decimal(15,2),0) totalcutva, convert(decimal(15,2),0) valoareRON, convert(decimal(15,2),0) cantitate,
	cc.idContract as idContractCorespondent,
	cc.dencontract as denidContractCorespondent
into #diezcontracte
FROM Contracte ct
left outer join @GestiuniUser gu on (gu.valoare=ct.gestiune or gu.valoare=ct.gestiune_primitoare)
LEFT JOIN terti t ON t.tert = ct.tert AND t.subunitate=@sub
LEFT JOIN infotert it ON it.subunitate = t.subunitate AND it.tert = t.tert AND ct.punct_livrare = it.Identificator
LEFT JOIN gestiuni gest ON gest.cod_gestiune = ct.gestiune and gest.subunitate = @sub
LEFT JOIN gestiuni gestPrim ON gestPrim.cod_gestiune = ct.gestiune_primitoare and gestPrim.Subunitate = @sub
LEFT JOIN lm ON lm.cod = ct.loc_de_munca
LEFT JOIN valuta v ON v.Valuta = ct.valuta
OUTER APPLY (select idContract, cc.numar+'-'+convert(char(10),cc.data,103) dencontract from contracte cc where ct.idContractCorespondent = cc.idContract) cc
/*	------> cod vechi anterior procedurii wTvaContracte; daca totul e bine se poate sterge:
OUTER APPLY		
(
	SELECT 
		isnull(count(1), 0) nr, sum(cantitate) cantitate, 
		sum(cantitate * (pret*(1.00-ISNULL(p.discount,0)/100.00))) AS valoare, 
		sum(round(cantitate*round(pret*(1.00-ISNULL(p.discount,0)/100.00)*(1+convert(float,n.cota_tva)/100),2)/(1+convert(float,n.cota_tva)/100),2)) AS valoarePV,
		sum(cantitate * (pret*(1.00-ISNULL(p.discount,0)/100.00))*(1+convert(float,n.cota_tva)/100)) as totalcutva,
	FROM PozContracte p
		left join nomencl n on p.cod=n.cod
	where p.idContract=ct.idContract
) pozitii	--*/
OUTER APPLY 
(
	select top 1 j.stare stare, s.denumire denstare, s.culoare culoare from JurnalContracte j JOIN StariContracte s on j.stare=s.stare and s.tipContract=ct.tip and j.idContract=ct.idContract order by j.data desc
) st
WHERE (@idContract IS NULL OR ct.idContract = @idContract)
	AND ct.data BETWEEN @f_datajos AND @f_datasus
	AND (@f_numar IS NULL OR ct.numar LIKE @f_numar)
	AND (@f_gestiune IS NULL OR ct.gestiune LIKE @f_gestiune)
	AND (@f_dengestiune IS NULL OR gest.denumire_gestiune LIKE @f_dengestiune)
	AND (@f_gestiune_primitoare IS NULL OR ct.gestiune_primitoare LIKE @f_gestiune_primitoare)
	AND (@f_dengestiune_primitoare IS NULL OR gestPrim.denumire_gestiune LIKE @f_dengestiune_primitoare)
	AND (@f_tert IS NULL OR ct.tert LIKE @f_tert)
	AND (@f_dentert IS NULL OR t.tert+t.denumire LIKE @f_dentert)
	AND (@f_lm IS NULL OR ct.loc_de_munca LIKE @f_lm)
	AND (@f_denlm IS NULL OR lm.denumire LIKE @f_denlm)
	AND (@tip IS NULL OR ct.tip = @tip)
	AND (@f_stare IS NULL OR st.denstare LIKE @f_stare)
	AND (@idContractCorespondent=0 or ct.idContractCorespondent=@idContractCorespondent)
	and (@lista_lm=0 or isnull(ct.Loc_de_munca,'')='' or ct.Loc_de_munca is not null and exists (select 1 from lmfiltrare lu where lu.utilizator=@utilizator and lu.cod=ct.Loc_de_munca))
	and (@lista_gestiuni=0 or gu.valoare is not null)
	and (@areFiltruClient=0 or exists (select * from @clienti c where c.tert=ct.tert))
	AND (@f_explicatii IS NULL OR ct.explicatii LIKE @f_explicatii)
order by ct.data desc,idContract desc

--> luarea cotei de tva pentru contracte se face in acelasi fel de peste tot - cu wTVAContracte:
if object_id('tempdb..#diezpozcontracte') is null
begin
	create table #diezpozcontracte (idpozcontract int)
end
exec wTvaContracte_tabela

insert into #diezpozcontracte(idpozcontract)
select idpozcontract
from pozcontracte pc inner join #diezcontracte d on pc.idcontract=d.idcontract

exec wTvaContracte @sesiune=@sesiune, @parxml=@parxml

update ct set nr=p.nr, pozitii=p.nr, cantitate=p.cantitate, valoare=p.valoare, valoarePV=p.valoarePV, totalcutva=p.totalcutva,
		valoareRON=convert(DECIMAL(15, 2), p.valoare*(case when isnull(ct.valuta,'')<>'' then ct.curs else 1 end))
	from #diezcontracte ct outer apply 
		(select isnull(count(1), 0) nr, 
			sum(p.cantitate) cantitate, 
			sum(p.valoare) AS valoare, 
			sum(p.valoarePV) AS valoarePV,
			sum(p.totalcutva) as totalcutva
		from #diezpozcontracte p where ct.idcontract=p.idcontract) p
	
select *, totalcutva valoarecutva from #diezcontracte	--> valoarecutva e setat in configurari pentru comenzi
FOR XML raw, root('Date')
if object_id('tempdb..#diezcontracte') is not null drop table #diezcontracte
if object_id('tempdb..#diezpozcontracte') is not null drop table #diezpozcontracte
SELECT '1' AS areDetaliiXml
FOR XML raw, root('Mesaje')
