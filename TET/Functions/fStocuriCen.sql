--***
create function  fStocuriCen(@dDataSus datetime, @cCod char(20), @cGestiune char(20), @cCodi char(20), @GrCod int, @GrGest int, @GrCodi int, @TipStoc char(1), @cCont char(13), @cGrupa char(13), 
	@Locatie char(30), @LM char(9), @Comanda char(40), @Contract char(20), @Furnizor char(13), @Lot char(20), @parXML xml)
returns @stoc table
(
subunitate char(9),
gestiune char(20),
tip_gestiune char(1),
cod char(20),
data datetime,
data_stoc datetime,
cod_intrare char(20),
pret float,
stoc_initial float,
intrari float,
iesiri float,
data_ultimei_iesiri datetime,
stoc float,
cont varchar(40),
data_expirarii datetime,
tva_neexigibil float,
pret_cu_amanuntul float,
locatie char(30),
loc_de_munca char(9), 
comanda char(40), 
[contract] char(20), 
furnizor char(13), 
lot char(20), 
valoare_stoc float, 
stoc_initial_UM2 float,
intrari_UM2 float,
iesiri_UM2 float,
stoc_UM2 float,
idIntrareFirma int,
idIntrare int
)
as
begin

declare @AccDVI int, @TimbruLit int
set @AccDVI = (select isnull(max(convert(int, val_logica)),0) from par where tip_parametru='GE' and parametru='ACCIMP')
set @TimbruLit = 0--(select isnull(max(convert(int, val_logica)),0) from par where tip_parametru='GE' and parametru='TIMBRULIT')

declare @docstoc table (subunitate char(9),gestiune char(20),cont varchar(40),cod char(20),data datetime,data_stoc datetime,cod_intrare char(20),pret float,tip_document char(2),
	numar_document char(20),cantitate float,cantitate_UM2 float,tip_miscare char(1),in_out char(1),predator char(20),jurnal char(3),tert char(13),serie char(20),pret_cu_amanuntul float,
	tip_gestiune char(1),locatie char(30),data_expirarii datetime,TVA_neexigibil int, pret_vanzare float,accize_cump float,loc_de_munca char(9),comanda char(40),[contract] char(20),
	furnizor char(13),lot char(20),numar_pozitie int, grp varchar(100), ordine varchar(30), ordineIntrariCustodie varchar(30),
	dataG datetime, dataStocG datetime, pretG float, contG varchar(40), dataExpG datetime, pretAmG float, 
	locatieG char(30), lmG char(9), comandaG char(40), contractG char(20), furnizorG char(13), lotG char(20), locatieCustodie char(30),idIntrareFirma int,idIntrare int)

if @GrCod  is null set @GrCod  = 1
if @GrGest is null set @GrGest = 1
if @GrCodi is null set @GrCodi = 1
if @TipStoc is null set @TipStoc = ''

insert @docstoc
select subunitate,gestiune,cont,cod,data,data_stoc,cod_intrare,pret,tip_document,numar_document,cantitate,cantitate_UM2,tip_miscare,in_out,predator,jurnal,tert,serie,
	pret_cu_amanuntul,tip_gestiune,(case when tip_miscare='E' then '' else locatie end),data_expirarii,TVA_neexigibil,pret_vanzare,accize_cump,loc_de_munca,comanda,[contract],furnizor,lot,numar_pozitie,
	subunitate+tip_gestiune+gestiune+cod+cod_intrare grp,
	(case when tip_document = 'SI' then '0' else '1' end)+(case when tip_miscare='I' and tip_document<>'AI' or tip_miscare='E' and cantitate<0 then '0' when tip_document='AI' then '1' else '2' end)
		+convert(char(8),data,112)+str(numar_pozitie) ordine, 	-- SI, apoi intrari, apoi iesiri
	(case when tip_miscare='I' and tip_document<>'AI' or tip_miscare='E' and cantitate<0 then '2' when tip_document = 'SI' then '1' else '0' end)
		+convert(char(8),data,112)+str(numar_pozitie) ordineIntrariCustodie, -- iesiri, apoi SI, apoi intrari = ordinea pt. "ultima intrare"
	'01/01/2999', '01/01/2999', 0, '', '01/01/2999', 0, '', '', '', '', '', '', '',idIntrareFirma,idIntrare
from dbo.fStocuri(@dDataSus, @dDataSus, @cCod, @cGestiune, @cCodi, @cGrupa, @TipStoc, @cCont, 0, @Locatie, @LM, @Comanda, @Contract, @Furnizor, @Lot, @parXML)
	--> pret vanzare este pretul de pe documentul primar; nu e pret vanzare de afisat.
	
	--> se actualizeaza datele pe grupari in functie de regulile specificate pentru campul "ordine":
update @docstoc
set 
	dataG=data, dataStocG=data_stoc, pretG=pret, contG=cont, dataExpG=data_expirarii, pretAmG=pret_cu_amanuntul, 
	locatieG=locatie, lmG=loc_de_munca, comandaG=comanda, contractG=[contract], furnizorG=furnizor, lotG=lot
from @docstoc d, (select d2.grp, min(d2.ordine) as ordine from @docstoc d2 group by d2.grp) d1
where d.grp=d1.grp and d.ordine=d1.ordine

-- locatia pt. custodie e luata de pe ULTIMUL document de intrare, altfel ramane null 
update @docstoc
set 
	locatieCustodie=locatie
from @docstoc d 
inner join (select d2.grp, max(d2.ordineIntrariCustodie) as ordineIntrariCustodie from @docstoc d2 group by d2.grp) d1 on d.grp=d1.grp and d.ordineIntrariCustodie=d1.ordineIntrariCustodie
inner join gestiuni g on g.subunitate=d.subunitate and g.cod_gestiune=d.gestiune and isnull(g.detalii.value('(/row/@custodie)[1]', 'int'),0)=1

insert @stoc
(subunitate, gestiune, tip_gestiune, cod, data, data_stoc, cod_intrare, pret, stoc_initial, intrari, iesiri,
	data_ultimei_iesiri, stoc, cont, data_expirarii, tva_neexigibil, pret_cu_amanuntul, locatie, loc_de_munca,
	comanda, [contract], furnizor, lot, valoare_stoc, stoc_initial_UM2, intrari_UM2, iesiri_UM2, stoc_UM2,idIntrareFirma,idIntrare)
select
	subunitate,
	max(case when @GrGest=1 then gestiune else '' end) gestiune,
	max(case when @GrGest=1 then tip_gestiune when tip_gestiune in ('F', 'T') then tip_gestiune else '' end) tip_gestiune,
	max(case when @GrCod=1 then cod else '' end) cod,
	min(dataG) data, min(case when tip_miscare='I' then data_stoc else '2999-12-31' end) data_stoc, max(case when @GrCodi=1 then cod_intrare else '' end) cod_intrare,
	max(pretG) pret,
	sum(round(convert(decimal(15,5), case when tip_document='SI' then cantitate else 0 end), 3)) stoc_initial,
	sum(round(convert(decimal(15,5), case when tip_document<>'SI' and tip_miscare='I' then cantitate else 0 end), 3)) intrari,
	sum(round(convert(decimal(15,5), case when tip_document<>'SI' and tip_miscare='E' then cantitate else 0 end), 3)) iesiri,
	max(case when tip_miscare='E' then data else '01/01/1901' end) data_ultimei_iesiri,
	sum(round(convert(decimal(15,5), (case when tip_miscare='E' then -1 else 1 end)*cantitate), 3)) stoc,
	max(contG) cont, min(dataExpG) data_expirarii, max(TVA_neexigibil) tva_neexigibil,
	max(case when (@AccDVI=1 or @TimbruLit=1) and tip_miscare='I' and accize_cump<>0 and tip_document<>'AI' 
		and tip_gestiune<>'A' then accize_cump else pretAmG end) pret_cu_amanuntul,
	(case when max(locatieCustodie)='' then max(locatieG) else max(locatieCustodie) end) locatie, max(lmG) loc_de_munca, max(comandaG) comanda, max(contractG) contract, max(furnizorG) furnizor, max(lotG) lot,
	sum(round(convert(decimal(17, 5), (case when tip_miscare='E' then -1 else 1 end)*cantitate*pret), 2)) valoare_stoc,
	sum(round(convert(decimal(15,5), case when tip_document='SI' then cantitate_UM2 else 0 end), 3)) stoc_initial_UM2,
	sum(round(convert(decimal(15,5), case when tip_document<>'SI' and tip_miscare='I' then cantitate_UM2 else 0 end), 3)) intrari_UM2,
	sum(round(convert(decimal(15,5), case when tip_document<>'SI' and tip_miscare='E' then cantitate_UM2 else 0 end), 3)) iesiri_UM2,
	sum(round(convert(decimal(15,5), (case when tip_miscare='E' then -1 else 1 end)*cantitate_UM2), 3)) stoc_UM2,min(idIntrareFirma),min(idIntrare)
from @docstoc
group by subunitate,
(case when @GrGest=1 then gestiune else '' end),
(case when @GrCod=1 then cod else '' end),
(case when @GrCodi=1 then cod_intrare else '' end),
(case when @GrGest=1 then tip_gestiune when tip_gestiune in ('F', 'T') then tip_gestiune else '' end)

return
end
